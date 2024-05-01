import ./operatorTypes
import std/[importutils]

proc newMapObservable*[SOURCE, RESULT](
  parent: Observable[SOURCE],
  mapper: proc(value: SOURCE): RESULT
): Observable[RESULT] =
  proc initialHandler(childObserver: Observer[RESULT]) =
    ## Handles forwarding events for when somebody initially subscribes to an observable.
    ## The childObserver is either a temporary observer created for only this purpose or the
    ## observer provided for subscribing.
    proc onNextInitially(value: SOURCE) =
      rerouteError(childObserver):
        let newValue = mapper(value)
        childObserver.next(newValue)
    let tempObserver = newForwardingObserver(childObserver, onNextInitially)
      
    privateAccess(Observable[SOURCE])
    parent.initialHandler(tempObserver)
    parent.removeObserver(tempObserver)

  return toNewObservable(parent, initialHandler)

proc map*[SOURCE, RESULT](
  source: Observable[SOURCE], 
  mapper: proc(value: SOURCE): RESULT
): Observable[RESULT] =
  ## Applies a given `mapper` function to each value emitted by `source`.
  ## Emits the mapped values in a new Observable
  let newObservable = newMapObservable[SOURCE, RESULT](source, mapper)

  proc mapSubscription(value: SOURCE) =
      let newValue = mapper(value)
      newObservable.forward(newValue)

  source.connect(newObservable, mapSubscription)

  return newObservable
