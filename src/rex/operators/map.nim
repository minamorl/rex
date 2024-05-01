import ./operatorTypes
import std/[importutils]

proc newMapObservable*[SOURCE, RESULT](
  parent: Observable[SOURCE],
  mapper: proc(value: SOURCE): RESULT
): Observable[RESULT] =
  proc initialHandler(childObserver: Observer[RESULT]) =
    proc onNext(value: SOURCE) =
      let newValue = mapper(value)
      childObserver.next(newValue)
      
    let thisObserver = newForwardingObserver(childObserver, onNext)
    privateAccess(Observable[SOURCE])
    parent.initialHandler(thisObserver)
    parent.removeObserver(thisObserver)

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
