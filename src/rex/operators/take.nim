import ./operatorTypes
import std/[importutils, sequtils]

proc takeSubscribe[T](
  parent: Observable[T],
  observable: Observable[T],
  observer: Observer[T],
  count: int
): Subscription =
  ## The subscription closure called when an external observer registers itself with
  ## an observable created via take operator.
  privateAccess(Observable)
  privateAccess(Subscription)  
  privateAccess(Observer)  
  var valueCounter = 0
  let parentObserver = newForwardingObserver[T, T](observer, nil)
  var hasCompleted = false
  proc onParentNext(value: T) {.async.} =
    ## Forwards values from parent to whoever subscribes to the take-Observable.
    ## When the count is reached, the take-Observable completes and unsubscribes
    ## itself.
    if hasCompleted:
      return
    
    await observer.next(value)
    valueCounter.inc
  
    let hasEmittedEnough = valueCounter >= count
    if hasEmittedEnough:
      await observable.completeProc()
      await observer.complete()
      parent.removeObserver(parentObserver)
      hasCompleted = true

  parentObserver.next = onParentNext
  let parentSubscription = parent.subscribe(parentObserver)
  
    
  return Subscription(
    unsubscribeProc: proc() = parentSubscription.unsubscribe()
  )

proc take*[T](
  parent: Observable[T],
  count: int
): Observable[T] =
  privateAccess(Observable)
  let takeObservable = Observable[T](
    completed: parent.completed,
    observers: @[],
  )
  
  takeObservable.completeProc = proc() {.async.} =
    await completeOperatorObservable(takeObservable)
      
  takeObservable.subscribeProc = proc(observer: Observer[T]): Subscription =
    takeSubscribe(parent, takeObservable, observer, count)
  
  return takeObservable