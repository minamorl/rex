import ./operatorTypes
import std/[importutils]

proc newFilterObservable[T](
  parent: Observable[T],
  obsFilter: proc(value: T): bool
): Observable[T] =
  proc initialHandler(childObserver: Observer[T]) =
    ## Handles forwarding events for when somebody initially subscribes to an observable.
    ## The childObserver is either a temporary observer created for only this purpose or the
    ## observer provided for subscribing.
    proc onNextInitially(value: T) =
      rerouteError(childObserver):
        if obsFilter(value):
          childObserver.next(value)
    let tempObserver = newForwardingObserver(childObserver, onNextInitially)
    
    privateAccess(Observable[T])
    parent.initialHandler(tempObserver)
    parent.removeObserver(tempObserver)
  
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