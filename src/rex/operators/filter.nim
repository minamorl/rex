import ./operatorTypes

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