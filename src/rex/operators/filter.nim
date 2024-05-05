import ./operatorTypes
import std/[importutils]

proc filterSubscribe[T](
  source: Observable[T], 
  observer: Observer[T],
  filterCond: proc(value: T): bool {.closure.}
): Subscription =   
  proc onSourceNext(value: T) {.async.} =
    if filterCond(value):
      await observer.next(value)
    
  let sourceObserver = newForwardingObserver(observer, onSourceNext)
  let sourceSubscription = source.subscribe(sourceObserver)
  
  privateAccess(Subscription)
  return newSubscription(sourceSubscription)

proc filter*[T](
  source: Observable[T], 
  filterCond: proc(value: T): bool {.closure.}
): Observable[T] =
  privateAccess(Observable)
  let filterObservable = Observable[T](
    completed: source.completed,
    observers: @[],
  )
  
  filterObservable.completeProc = proc() {.async.} =
    completeOperatorObservable(filterObservable)
    
  filterObservable.subscribeProc = proc(observer: Observer[T]): Subscription =
    return filterSubscribe(source, observer, filterCond)
  
  return filterObservable