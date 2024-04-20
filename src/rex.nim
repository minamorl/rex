import std/[times, monotimes]

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

proc map*[T, R](source: Observable[T], mapper: proc(value: T): R ): Observable[R] =
  ## Applies a given `mapper` function to each value emitted by `source`.
  ## Emits the mapped values in a new Observable
  let result = Observable[R]()
  proc observer(value: T) =
    result.next(mapper(value))
  source.subscribe(observer)
  return result

proc filter*[T](source: Observable[T], filter: proc(value: T): bool {.noSideEffect.}): Observable[T] =
  ## Filters items emitted by `source` by only emitting those that satisfy the
  ## specified `filter` function. The filtered values are emitted as a new Observable.
  let result = Observable[T]()
  proc observer(value: T) =
    if filter(value):
      result.next(value)
      
  source.subscribe(observer)
  
  return result

proc tap*[T](source: Observable[T], sideEffect: proc(value: T)): Observable[T] =
  ## Performs side effects in `sideEffect` every time `source` emits a value. 
  ## Returns `source` without changing it.
  proc observer(value: T) =
    sideEffect(value)
  source.subscribe(observer)
  return source


proc throttle*[T](source: Observable[T], throttleProc: proc(value: T): Duration): Observable[T] =
  ## Receives a proc to compute the silencing duration for each value emitted by `source`.
  ## During the silencing duration any value emitted by `source` will be ignored.
  let result = Observable[T]()
  var lastTriggerTime: MonoTime 
  proc observer(value: T) =
    let delay: Duration = throttleProc(value)
    let now = getMonoTime()
    let elapsed = (now - lastTriggerTime)
    if elapsed >= delay:
      lastTriggerTime = now
      result.next(value)
      
  source.subscribe(observer)
  return result

proc combine*[T, R](
  source1: Observable[T], 
  source2: Observable[R]
): Observable[(T, R)] =
  ## Combines the latest values from `source1` and `source2` and emits them as a tuple in a new Observable.
  ## This Observable emits every time either `source1` or `source2` emit.
  let result = Observable[(T, R)]()
  
  var latestsource1Value: T = source1.lastValue
  var latestsource2Value: R = source2.lastValue
  proc source1Observer(value1: T) =
    latestSource1Value = value1
    result.next((value1, latestSource2Value))
  source1.subscribe(source1Observer)
  
  proc source2Observer(value2: R) =
    latestSource2Value = value2
    result.next((latestSource1Value, value2))
  source2.subscribe(source2Observer)
  
  return result
