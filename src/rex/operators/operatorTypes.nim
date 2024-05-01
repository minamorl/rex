import std/[sugar, options, importutils]
import ../core
export core

proc toNewObservable[SOURCE, RESULT](
  source: Observable[SOURCE],
  valueGetter: proc(): Option[RESULT] {.closure.}
): Observable[RESULT] =
  privateAccess(Observable[SOURCE])
  return Observable[RESULT](
    getValue: valueGetter,
    completed: source.completed
  )

proc forward*[T](source: Observable[T], value: T) =
  privateAccess(Observable[T])
  for observer in source.observers:
    observer.next(value)

proc newFilterObservable*[T](
  parent: Observable[T],
  obsFilter: proc(value: T): bool
): Observable[T] =
  proc getValueClosure(): Option[T] =
    privateAccess(Observable[T])
    let parentValue: Option[T] = parent.getValue()
    return parentValue.filter(value => obsFilter(value))
  
  return parent.toNewObservable(getValueClosure)

proc newMapObservable*[SOURCE, RESULT](
  parent: Observable[SOURCE],
  mapper: proc(value: SOURCE): RESULT
): Observable[RESULT] =
  proc getValueClosure(): Option[RESULT] =
    privateAccess(Observable[SOURCE])
    let parentValue: Option[SOURCE] = parent.getValue()
    return parentValue.map(value => mapper(value))
  
  return parent.toNewObservable(getValueClosure)
