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

proc newSubscription*(subscriptions: varargs[Subscription]): Subscription =
  let subscriptionList = subscriptions.toSeq()
  return Subscription(
    unsubscribeProc: proc() = 
      for subscription in subscriptionList:
        subscription.unsubscribeProc()
  )

let EMPTY_SUBSCRIPTION* = Subscription(
  unsubscribeProc: proc() = discard, 
)

proc hasAsyncWork*(subscription: Subscription): bool =
  not subscription.fut.isNil()

proc unsubscribe*(subscription: Subscription) =
  subscription.unsubscribeProc()
  
proc doWork*(subscription: Subscription): Subscription {.discardable.} =
  ## Convenience proc for starting the asynchronous work on cold observables.
  ## 
  ## If the subscription is to a hot observable, this does nothing.
  ## 
  ## If the subscription is to a cold observable, this will blocks until all 
  ## asynchronous work of the observable in the subscription is done.
  if subscription.hasAsyncWork():
    waitFor subscription.fut
  
  return subscription

let EMPTY* = Observable[void](
  observers: @[],
  completed: true,
  completeProc: completeDoNothing,
  subscribeProc: proc(observer: Observer[void]): Subscription = EMPTY_SUBSCRIPTION
)

proc newObservable*[T](valueProc: proc(observer: Observer[T]): Future[void] {.async.}): Observable[T] =
  ## Creates a cold observable that emits values to subscribed observers via `valueProc`.
  ## Upon subscription, `valueProc` will be executed *to completion*.
  ## This means, that if you use async operators inside `valueProc`, then the CPU *will* block.
  let newObs = Observable[T](
    observers: @[],
    completed: true,
    completeProc: completeDoNothing
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
  ## Convenience proc that allows creating a cold observable with a purely synchronous `valueProc`.
  proc asyncValueProc(observer: Observer[T]): Future[void] {.async.} =
    valueProc()
  
  return newObservable(asyncValueProc)
    
proc newObservable*[T](value: T): Observable[T] =
  ## Convenience proc that allows creating a cold observable from a value
  proc valueProc(observer: Observer[T]) {.async.} =    
    let nextFuture = observer.next(value)
    let completeFuture = observer.complete()
    
    await all [nextFuture, completeFuture]
    
  return newObservable(valueProc)

proc subscribe*[T](
  reactable: Observable[T]; 
  observer: Observer[T]
): Subscription {.discardable.} =
  ## Subscribes an observer to an observable.
  ## 
  ## If the observable is hot, then the observer just starts listening to future values.
  ## 
  ## If the observable is cold, it will start executing the cold observables `valueProc`.
  ## This operation is asynchronous for cold observables, as any of the observable's observers
  ## may do asynchronous work as part of their callbacks that get executed upon subscription.
  ## This asynchronous work is not immediately executed and can be manually triggered via the 
  ## returned `Subscription` (See `doWork`) 
  
  return reactable.subscribeProc(observer)

proc subscribe*[T](
  reactable: Observable[T],
  next: NextCallback[T],
  error: ErrorCallback = nil,
  complete: CompleteCallback = nil
): Subscription {.discardable.} =
  ## Convenience proc that allows subscribing by just defining the next/error/complete callbacks.
  ## If called with `SyncErrorCallback` or `CompleteErrorCallback` type those will be immediately
  ## converted via the `functionType.toAsync` converters.
  let observer = newObserver[T](next, error, complete)
  return reactable.subscribe(observer)

proc subscribe*[T](
  reactable: Observable[T],
  next: SyncNextCallback[T],
  error: ErrorCallback = nil,
  complete: CompleteCallback = nil
): Subscription {.discardable.} =
  ## Convenience proc that allows subscribing by just defining the next/error/complete callbacks.
  ## If called with `SyncErrorCallback` or `CompleteErrorCallback` type those will be immediately
  ## converted via the `functionType.toAsync` converters.
  proc asyncNext(value: T) {.async.} = 
    next(value)
  return reactable.subscribe(asyncNext, error, complete)