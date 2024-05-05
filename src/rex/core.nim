import std/[sequtils, asyncdispatch, importutils]
import ./observer
import ./functionTypes

export observer
export functionTypes

type 
  Observable*[T] = ref object of RootObj
    observers: seq[Observer[T]]
    subscribeProc: proc(observer: Observer[T]): Subscription
    completeProc: proc(): Future[void] {.async.}
    completed: bool
  
  Subscription* = ref object
    fut: Future[void]
    unsubscribeProc: proc()
    error: ErrorCallback

proc removeObserver*[T](reactable: Observable[T], observer: Observer[T]) =
  let filteredObservers = reactable.observers.filterIt(it != observer)
  reactable.observers = filteredObservers

proc newSubscription*[A, B](
  observable: Observable[A], 
  observer: Observer[B]
): Subscription =
  privateAccess(Observer)

  proc unsubscribeProc() =
    observable.removeObserver(observer)

  return Subscription(
    unsubscribeProc: unsubscribeProc,
    error: observer.errorProc
  )

let EMPTY_SUBSCRIPTION* = Subscription(
  unsubscribeProc: proc() = discard, 
)

proc hasAsyncWork*(subscription: Subscription): bool =
  not subscription.fut.isNil()

proc unsubscribe*(subscription: Subscription) =
  subscription.unsubscribeProc()
  
proc doWork*(subscription: Subscription): Subscription {.discardable.} =
  if subscription.hasAsyncWork():
    waitFor subscription.fut
  
  return subscription

proc newObservable*[T](valueProc: proc(observer: Observer[T]): Future[void] {.async.}): Observable[T] =
  ## Creates a cold observable that emits values to subscribed observers via `valueProc`.
  ## Upon subscription, `valueProc` will be executed *to completion*.
  ## This means, that if you use async operators inside `valueProc`, then the CPU *will* block.
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