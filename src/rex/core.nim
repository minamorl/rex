import std/[sequtils, asyncdispatch]

# TODO:
# - Figure out how to unsubscribe the tap observer when the parent unsubscribes. Might be that tap does need to create a new observable. Then test tap accordingly
# - Implement combineLatest
# - Implement throttle

type ReactiveError* = ref CatchableError
type SubscriptionError* = ReactiveError

### TYPES / BASICS
type 
  NextCallback*[T] = proc(value: T) {.async, closure.}
  SyncNextCallback*[T] = proc(value: T) {.closure.}
  ErrorCallback* = proc(error: ref CatchableError) {.async, closure.}
  SyncErrorCallback* = proc(error: ref CatchableError) {.closure.}
  CompleteCallback* = proc() {.async, closure.}
  SyncCompleteCallback* = proc() {.closure.}

  Observer*[T] = ref object
    nextProc: NextCallback[T]
    errorProc: ErrorCallback
    completeProc: CompleteCallback

  Observable*[T] = ref object of RootObj
    observers: seq[Observer[T]]
    subscribeProc: proc(observer: Observer[T]): Subscription
    completeProc: proc(): Future[void] {.async.}
    completed: bool
  
  Subscription* = ref object
    fut: Future[void]
    unsubscribeProc: proc()
    error: ErrorCallback

proc `next=`*[T](observer: Observer[T], next: NextCallback[T]) =
  observer.nextProc = next
  
proc `error=`*[T](observer: Observer[T], error: ErrorCallback) =
  observer.errorProc = error
  
proc `complete=`*[T](observer: Observer[T], complete: CompleteCallback) =
  observer.completeProc = complete

proc hasNextCallback*[T](observer: Observer[T]): bool =
  return not observer.nextProc.isNil()

proc hasErrorCallback*[T](observer: Observer[T]): bool =
  return not observer.errorProc.isNil()

proc hasCompleteCallback*[T](observer: Observer[T]): bool =
  return not observer.completeProc.isNil()

proc next*[T](observer: Observer[T], value: T) {.async.} =
  if observer.hasNextCallback():
    await observer.nextProc(value)

proc error*(observer: Observer, error: ref CatchableError) {.async.} =
  if observer.hasErrorCallback():
    await observer.errorProc(error)

proc complete*(observer: Observer) {.async.} =
  if observer.hasCompleteCallback():
    await observer.completeProc()

proc removeObserver*[T](reactable: Observable[T], observer: Observer[T]) =
  let filteredObservers = reactable.observers.filterIt(it != observer)
  reactable.observers = filteredObservers

proc newSubscription*[A, B](
  observable: Observable[A], 
  observer: Observer[B]
): Subscription =
  proc unsubscribeProc() =
    observable.removeObserver(observer)

  return Subscription(
    unsubscribeProc: unsubscribeProc,
    error: observer.errorProc
  )

let EMPTY_SUBSCRIPTION* = Subscription(
  unsubscribeProc: proc() = discard, 
)

proc unsubscribe*(subscription: Subscription) =
  subscription.unsubscribeProc()
  
proc doWork*(subscription: Subscription): Subscription {.discardable.} =
  let hasFuture = not subscription.fut.isNil()
  if not hasFuture:
    return subscription
  
  try:
    waitFor subscription.fut
  except CatchableError as e: # TODO: Check if this try-catch is necessary, the new next closure wrapper with await should take care of this
    if not subscription.error.isNil():
      waitFor subscription.error(e)
    
  return subscription

converter toAsync*(errorProc: SyncErrorCallback): ErrorCallback =
  return if errorProc.isNil():
      nil
    else:
      proc(error: ref CatchableError) {.async.} = errorProc(error)
      
converter toAsync*(complete: SyncCompleteCallback): CompleteCallback =
  return if complete.isNil():
    nil
  else:
    proc() {.async.} = complete()

proc newObserver*[T](
  next: NextCallback[T],
  error: ErrorCallback = nil,
  complete: CompleteCallback = nil
): Observer[T] =
  proc nextProc(value: T) {.async.} =
    try:
      await next(value)
    except CatchableError as e:
      if not error.isNil():
        await error(e)

  return Observer[T](
    nextProc: nextProc, 
    errorProc: error, 
    completeProc: complete,
  )

proc newObserver*[T](
  next: SyncNextCallback[T],
  error: ErrorCallback = nil,
  complete: CompleteCallback = nil
): Observer[T] =
  proc asyncNext(value: T) {.async.} = next(value)
  return newObserver[T](asyncNext, error, complete)
  
proc newObservable*[T](valueProc: proc(observer: Observer[T]): Future[void] {.async.}): Observable[T] =
  let newObs = Observable[T](
    observers: @[],
    completed: true,
    completeProc: proc() {.async.} = discard
  )
  
  proc subscribeProc(observer: Observer[T]): Subscription =
    let subscription = newSubscription(newObs, observer)
    try:
      waitFor valueProc(observer)
    except CatchableError as e:
      subscription.fut = observer.error(e)
    
    return subscription
  newObs.subscribeProc = subscribeProc
  
  return newObs

proc newObservable*[T](valueProc: proc()): Observable[T] =
  proc asyncValueProc(observer: Observer[T]): Future[void] {.async.} =
    valueProc()
  
  return newObservable(asyncValueProc)
    
proc newObservable*[T](value: T): Observable[T] =
  proc valueProc(observer: Observer[T]) {.async.} =    
    let nextFuture = observer.next(value)
    let completeFuture = observer.complete()
    
    await all([nextFuture, completeFuture])
    
  return newObservable(valueProc)

proc subscribe*[T](
  reactable: Observable[T]; 
  observer: Observer[T]
): Subscription {.discardable.} =
  return reactable.subscribeProc(observer)

proc subscribe*[T](
  reactable: Observable[T],
  next: NextCallback[T],
  error: ErrorCallback = nil,
  complete: CompleteCallback = nil
): Subscription {.discardable.} =
  let observer = newObserver[T](next, error, complete)
  return reactable.subscribe(observer)

proc subscribe*[T](
  reactable: Observable[T],
  next: SyncNextCallback[T],
  error: ErrorCallback = nil,
  complete: CompleteCallback = nil
): Subscription {.discardable.} =
  proc asyncNext(value: T) {.async.} = 
    next(value)
  return reactable.subscribe(asyncNext, error, complete)