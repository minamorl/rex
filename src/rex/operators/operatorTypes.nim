import std/[options, importutils]
import ../core
export core

proc toNewObservable*[SOURCE, RESULT](
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