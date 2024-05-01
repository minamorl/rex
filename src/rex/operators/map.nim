import ./operatorTypes
import std/[sugar, options, importutils]

proc newMapObservable*[SOURCE, RESULT](
  parent: Observable[SOURCE],
  mapper: proc(value: SOURCE): RESULT
): Observable[RESULT] =
  proc getValueClosure(): Option[RESULT] =
    privateAccess(Observable[SOURCE])
    let parentValue: Option[SOURCE] = parent.getValue()
    return parentValue.map(value => mapper(value))
  
  return parent.toNewObservable(getValueClosure)

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
