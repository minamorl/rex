type Observable*[T] = ref object
  observers: seq[proc(value: T)]
  lastValue: T
  hasValue: bool

proc subscribe*[T](observable: Observable[T], observer: proc(value: T)) =
  observable.observers.add(observer)
  if observable.hasValue:
    observer(observable.lastValue)

proc next*[T](observable: Observable[T], value: T) =
  observable.lastValue = value
  observable.hasValue = true
  for observer in observable.observers:
    observer(value)

proc create*[T](process: proc(observable: Observable[T])): Observable[T] =
  let result = Observable[T]()
  process(result)
  return result
