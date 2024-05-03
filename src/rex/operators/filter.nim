import ./operatorTypes
import std/[importutils]

proc filterSubscribe[T](
  parent: Observable[T], 
  observer: Observer[T],
  filterCond: proc(value: T): bool {.closure.}
): Subscription =   
  proc onParentNext(value: T) =
    if filterCond(value):
      observer.next(value)
    
  let parentObserver = newForwardingObserver(observer, onParentNext)
  let subscription = parent.subscribe(parentObserver)
  
  privateAccess(Subscription)
  return Subscription(
    unsubscribeProc: proc() = subscription.unsubscribe()
  )

proc filter*[T](
  source: Observable[T], 
  filterCond: proc(value: T): bool {.closure.}
): Observable[T] =
  privateAccess(Observable)
  let filterObservable = Observable[T](
    completed: source.completed,
    observers: @[],
  )
  
  filterObservable.completeProc = proc() =
    completeOperatorObservable(filterObservable)
    
  filterObservable.subscribeProc = proc(observer: Observer[T]): Subscription =
    return filterSubscribe(source, observer, filterCond)
  
  return filterObservable