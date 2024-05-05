import ./operatorTypes
import std/[importutils, sequtils]

proc takeSubscribe[T](
  parent: Observable[T],
  observable: Observable[T],
  observer: Observer[T],
  count: int
): Subscription =
  privateAccess(Observable)
  privateAccess(Subscription)
  let parentObserver = newForwardingObserver[T, T](observer, nil)
  
  var valueCounter = 0
  proc onParentNext(value: T) =
    let hasEmittedEnough = valueCounter >= count
    if hasEmittedEnough:
      observable.completeProc()
      if observer.hasCompleteCallback():
        observer.complete()
      return
    
    observer.next(value)
    valueCounter.inc
  
  parentObserver.next = proc(value: T) =
    rerouteError(parentObserver):
      onParentNext(value)
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
  
  takeObservable.completeProc = proc() =
    completeOperatorObservable(takeObservable)
      
  takeObservable.subscribeProc = proc(observer: Observer[T]): Subscription =
    takeSubscribe(parent, takeObservable, observer, count)
  
  return takeObservable