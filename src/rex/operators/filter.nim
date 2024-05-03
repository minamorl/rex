import ./operatorTypes
import std/[importutils]

proc filterComplete[T](observable: Observable[T]) =
  privateAccess(Observable)
  if observable.completed:
    return
  
  for observer in observable.observers:
    if observer.hasCompleteCallback():
      observer.complete()
  
  observable.observers = @[]
  observable.completed = true

proc filterSubscribe[T](
  parent: Observable[T], 
  observer: Observer[T],
  filterCond: proc(value: T): bool {.closure.}
) = 
  proc onParentNext(value: T) =
    rerouteError(observer):
      if filterCond(value):
        observer.next(value)
    
  let parentObserver = newForwardingObserver(observer, onParentNext)
  parent.subscribe(parentObserver)

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
    filterComplete(filterObservable)
    
  filterObservable.subscribeProc = proc(observer: Observer[T]) =
    filterSubscribe(source, observer, filterCond)
  
  return filterObservable