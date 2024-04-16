# rex.nim

type Observable*[T] = ref object
  observers: seq[proc(value: T)]
  process: proc()

proc subscribe*[T](observable: Observable[T], observer: proc(value: T)) =
  observable.observers.add(observer)

proc next*[T](observable: Observable[T], value: T) =
  for observer in observable.observers:
    observer(value)

proc create*[T](process: proc(observable: Observable[T])): Observable[T] =
  let result = Observable[T]()
  result.process = proc() =
    process(result)
  return result

proc enable*[T](observable: Observable[T]) =
  observable.process()
