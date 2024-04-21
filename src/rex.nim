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
  result = Observable[T]()
  process(result)
  return result

proc map*[T, R](source: Observable[T], mapper: proc(value: T): R ): Observable[R] =
  ## Applies a given `mapper` function to each value emitted by `source`.
  ## Emits the mapped values in a new Observable
  let newObservable = Observable[R]()
  proc observer(value: T) =
    newObservable.next(mapper(value))
  source.subscribe(observer)
  return newObservable

proc filter*[T](source: Observable[T], filter: proc(value: T): bool {.noSideEffect.}): Observable[T] =
  ## Filters items emitted by `source` by only emitting those that satisfy the
  ## specified `filter` function. The filtered values are emitted as a new Observable.
  let newObservable = Observable[T]()
  proc observer(value: T) =
    if filter(value):
      newObservable.next(value)
      
  source.subscribe(observer)
  
  return newObservable

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
  let newObservable = Observable[T]()
  var lastTriggerTime: MonoTime 
  proc observer(value: T) =
    let delay: Duration = throttleProc(value)
    let now = getMonoTime()
    let elapsed = (now - lastTriggerTime)
    if elapsed >= delay:
      lastTriggerTime = now
      newObservable.next(value)
      
  source.subscribe(observer)
  return newObservable

proc combine*[T, R](
  source1: Observable[T], 
  source2: Observable[R]
): Observable[(T, R)] =
  ## Combines the latest values from the given observables and emits them as a tuple in a new Observable.
  ## This Observable emits every time any of the sources emit.
  let newObservable = Observable[(T, R)]()
  
  var latestsource1Value: T = source1.lastValue
  var latestsource2Value: R = source2.lastValue
  proc source1Observer(value1: T) =
    latestSource1Value = value1
    newObservable.next((value1, latestSource2Value))
  source1.subscribe(source1Observer)
  
  proc source2Observer(value2: R) =
    latestSource2Value = value2
    newObservable.next((latestSource1Value, value2))
  source2.subscribe(source2Observer)
  
  return newObservable

proc combine*[T, R, S](
  source1: Observable[T], 
  source2: Observable[R],
  source3: Observable[S]
): Observable[(T, R, S)] =
  ## Combines the latest values from the given observables and emits them as a tuple in a new Observable.
  ## This Observable emits every time any of the sources emit.
  let newObservable = Observable[(T, R, S)]()
  
  var latestSource1Value: T = source1.lastValue
  var latestSource2Value: R = source2.lastValue
  var latestSource3Value: S = source3.lastValue
  
  proc source1Observer(value1: T) =
    latestSource1Value = value1
    newObservable.next((value1, latestSource2Value, latestSource3Value))
  source1.subscribe(source1Observer)
  
  proc source2Observer(value2: R) =
    latestSource2Value = value2
    newObservable.next((latestSource1Value, value2, latestSource3Value))
  source2.subscribe(source2Observer)
  
  proc source3Observer(value3: S) =
    latestSource3Value = value3
    newObservable.next((latestSource1Value, latestSource2Value, value3))
  source3.subscribe(source3Observer)
  
  return newObservable

proc combine*[T, R, S, Q](
  source1: Observable[T], 
  source2: Observable[R],
  source3: Observable[S],
  source4: Observable[Q]
): Observable[(T, R, S, Q)] =
  ## Combines the latest values from the given observables and emits them as a tuple in a new Observable.
  ## This Observable emits every time any of the sources emit.
  let newObservable = Observable[(T, R, S, Q)]()
  
  var latestSource1Value: T = source1.lastValue
  var latestSource2Value: R = source2.lastValue
  var latestSource3Value: S = source3.lastValue
  var latestSource4Value: Q = source4.lastValue
  
  proc source1Observer(value1: T) =
    latestSource1Value = value1
    newObservable.next((value1, latestSource2Value, latestSource3Value, latestSource4Value))
  source1.subscribe(source1Observer)
  
  proc source2Observer(value2: R) =
    latestSource2Value = value2
    newObservable.next((latestSource1Value, value2, latestSource3Value, latestSource4Value))
  source2.subscribe(source2Observer)
  
  proc source3Observer(value3: S) =
    latestSource3Value = value3
    newObservable.next((latestSource1Value, latestSource2Value, value3, latestSource4Value))
  source3.subscribe(source3Observer)

  proc source4Observer(value4: Q) =
    latestSource4Value = value4
    newObservable.next((latestSource1Value, latestSource2Value, latestSource3Value, value4))
  source4.subscribe(source4Observer)
  
  return newObservable