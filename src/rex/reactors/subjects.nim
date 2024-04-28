import std/options
import ../core

type Subject*[T] = ref object of Observable[T]

proc newSubject*[T](): Subject[T] =
  result = Subject[T]()
  result.value = proc(): Option[T] = none(T)


proc next*[T](subj: Subject[T], values: varargs[T]) =
  for value in values:
    subj.forward(value)

proc asObservable*[T](source: Subject[T]): Observable[T] = source