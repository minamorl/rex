import std/[importutils]
import ../core

type Subject*[T] = ref object of Observable[T]

proc newSubject*[T](): Subject[T] =
  privateAccess(Observable[T]) # Enables assigning to Observable fields that Subject inherited
  return Subject[T](
    hasInitialValues: false, # Raw subject type does not emit on subscribe
    initialHandler: nil # Raw subject type does not emit on subscribe
  )

proc next*[T](subj: Subject[T], values: varargs[T]) =
  privateAccess(Observable[T])
  for value in values:
    for observer in subj.observers:
      observer.next(value)

proc asObservable*[T](source: Subject[T]): Observable[T] = source