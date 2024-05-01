import ./operatorTypes
import std/[importutils]

proc newFilterObservable[T](
  parent: Observable[T],
  obsFilter: proc(value: T): bool
): Observable[T] =
  proc initialHandler(childObserver: Observer[T]) =
    ## Keep in mind, we're going from child to parent here where child calls parent
    proc onNext(value: T) =
      if obsFilter(value):
        childObserver.next(value)
    
    let thisObserver = newForwardingObserver(childObserver, onNext)
    privateAccess(Observable[T])
    parent.initialHandler(thisObserver)
    parent.removeObserver(thisObserver)
  
  return toNewObservable(parent, initialHandler)

proc filter*[T](
  source: Observable[T], 
  filterCond: proc(value: T): bool {.closure.}
): Observable[T] =
  let newObservable = newFilterObservable[T](source, filterCond)
  
  proc filterSubscription(value: T) =
    if filterCond(value):
      newObservable.forward(value)
  
  source.connect(newObservable, filterSubscription)
  return newObservable