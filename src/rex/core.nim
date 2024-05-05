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
    next*: NextCallback[T]
    error*: ErrorCallback
    complete*: CompleteCallback

  Observable*[T] = ref object of RootObj
    observers: seq[Observer[T]]
    subscribeProc: proc(observer: Observer[T]): Subscription
    completeProc: proc(): Future[void] {.async.}
    completed: bool
  
  Subscription* = ref object
    fut: Future[void]
    unsubscribeProc: proc()
    error: ErrorCallback

proc hasErrorCallback*(observer: Observer): bool =
  not observer.error.isNil()

proc hasCompleteCallback*(observer: Observer): bool =
  not observer.complete.isNil()

template rerouteError*(observer: Observer, body: untyped) =
  try:
    body
  except CatchableError as e:
    if observer.hasErrorCallback():
      observer.error(e)

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
    error: observer.error
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
  except CatchableError as e:
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
  obsNext: NextCallback[T],
  obsError: ErrorCallback = nil,
  obsComplete: CompleteCallback = nil
): Observer[T] =
  proc nextProc(value: T) {.async.} =
    try:
      await obsNext(value)
    except CatchableError as e:
      if not obsError.isNil():
        await obsError(e)

  return Observer[T](
    next: nextProc, 
    error: obsError, 
    complete: obsComplete,
  )

proc newObserver*[T](
  next: SyncNextCallback[T],
  error: ErrorCallback = nil,
  complete: CompleteCallback = nil
): Observer[T] =
  proc asyncNext(value: T): Future[void] {.async.} = 
    next(value)
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
      subscription.fut = valueProc(observer)
    except CatchableError as e:
      if observer.hasErrorCallback():
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
    var futures = newSeq[Future[void]]()
    
    let nextFuture = observer.next(value)
    futures.add(nextFuture)
    
    if observer.hasCompleteCallback():
      let completeFuture = observer.complete()
      futures.add(completeFuture)
    
    return all(futures)
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