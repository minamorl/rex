import ./operatorTypes
import std/[sugar, options, importutils]

proc newFilterObservable[T](
  parent: Observable[T],
  obsFilter: proc(value: T): bool
): Observable[T] =
  proc getValueClosure(): Option[T] =
    privateAccess(Observable[T])
    let parentValue: Option[T] = parent.getValue()
    return parentValue.filter(value => obsFilter(value))
  
  return parent.toNewObservable(getValueClosure)

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