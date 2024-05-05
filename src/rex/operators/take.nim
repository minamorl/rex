import ./operatorTypes
import std/[importutils]

proc takeSubscribe[T](
  source: Observable[T],
  destination: Observable[T],
  observer: Observer[T],
  count: int
): Subscription =
  ## The subscription closure called when an external observer registers itself with
  ## an destination created via take operator.
  privateAccess(Observable)
  privateAccess(Subscription)  
  var valueCounter = 0
  let sourceObserver = newForwardingObserver[T, T](observer, nil)
  var hasCompleted = false
  proc onSourceNext(value: T) {.async.} =
    ## Forwards values from source to whoever subscribes to the take-Observable.
    ## When the count is reached, the take-Observable completes and unsubscribes
    ## itself.
    if hasCompleted:
      return
    
    await observer.next(value)
    valueCounter.inc
  
    let hasEmittedEnough = valueCounter >= count
    if hasEmittedEnough:
      await all [destination.completeProc(), observer.complete()]
      source.removeObserver(sourceObserver)
      hasCompleted = true

  sourceObserver.next = onSourceNext
  let sourceSubscription = source.subscribe(sourceObserver)
  
  return newSubscription(sourceSubscription)

proc take*[T](
  source: Observable[T],
  count: int
): Observable[T] =
  privateAccess(Observable)
  let takeObservable = Observable[T](
    completed: source.completed,
    observers: @[],
  )
  
  takeObservable.completeProc = proc() {.async.} =
    await completeOperatorObservable(takeObservable)
      
  takeObservable.subscribeProc = proc(observer: Observer[T]): Subscription =
    takeSubscribe(source, takeObservable, observer, count)
  
  return takeObservable