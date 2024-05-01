import std/[importutils, options]
import ../core

type Subject*[T] = ref object of Observable[T]

proc newSubject*[T](): Subject[T] =
  privateAccess(Observable[T]) # Enables assigning to Observable fields that Subject inherited
  return Subject[T](
    getValue: proc(): Option[T] = none(T),
  )

proc next*[T](subj: Subject[T], values: varargs[T]) =
  privateAccess(Observable[T]) # Enables accessing observer field
  for value in values:
    for observer in subj.observers:
      observer.next(value)

proc asObservable*[T](source: Subject[T]): Observable[T] = source