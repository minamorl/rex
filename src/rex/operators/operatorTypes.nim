import std/[sugar, options]
import ../core
export core

proc newFilterObservable*[T](
  parent: Observable[T],
  obsFilter: proc(value: T): bool
): Observable[T] =
  proc getValueClosure(): Option[T] =
    let parentValue: Option[T] = parent.value
    return parentValue.filter(value => obsFilter(value))
  
  result = newObservable[T](default(T))
  result.value = getValueClosure

proc newMapObservable*[SOURCE, RESULT](
  parent: Observable[SOURCE],
  mapper: proc(value: SOURCE): RESULT
): Observable[RESULT] =
  proc getValueClosure(): Option[RESULT] =
    let parentValue: Option[SOURCE] = parent.value
    return parentValue.map(value => mapper(value))
  
  result = newObservable[RESULT](default(RESULT))
  result.value = getValueClosure
