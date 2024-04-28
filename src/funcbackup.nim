import std/[times, monotimes, os, options, sugar]

# IDEAS
# - Turn OperatorObservable into an object variant that has different proc fields for different kinds of operators

### TYPES / BASICS
type SubscriptionCallback*[T] = proc(value: T)
type ErrorCallback* = proc(error: CatchableError)
type CompleteCallback* = proc()
type Observer*[T] = ref object
  subscription: SubscriptionCallback[T]
  error: ErrorCallback
  complete: CompleteCallback

proc newObserver*[T](
  subscription: SubscriptionCallback[T], 
  error: ErrorCallback = nil,
  complete: CompleteCallback = nil
): Observer[T] =
  Observer[T](subscription: subscription, error: error, complete: complete)
  
### OBSERVABLE ###
type Observable*[T] = ref object of RootObj
  observers*: seq[Observer[T]]
  getValue*: proc(): Option[T] {.closure.}
  completed*: bool

proc newObservable*[T](value: T): Observable[T] = 
  Observable[T](
    observers: @[],
    getValue: proc(): Option[T] = some(value),
    completed: false
  )

proc subscribe*[T](reactable: Observable[T]; observer: Observer[T]) =
  let hasCompleteCallback = not observer.complete.isNil()
  if reactable.completed and hasCompleteCallback:
    observer.complete()
    return
  
  reactable.observers.add(observer)
  
  let initialValue = reactable.getValue()
  let hasInitialValue = initialValue.isSome()
  if hasInitialValue:
    observer.subscription(initialValue.get())

proc complete*[T](reactable: Observable[T]) =
  reactable.completed = true
  for observer in reactable.observers:
    let hasCompleteCallback = not observer.complete.isNil()
    if hasCompleteCallback:
      observer.complete()
  reactable.observers = @[]

proc connect*[T, U](source: Observable[T], target: Observable[U], subscription: proc(value: T)) =    
  proc onSourceCompletion() = complete(target)

  proc onSourceError(error: CatchableError) =
    for observer in target.observers:
      if not observer.error.isNil():
        observer.error(error)
  
  let connection = newObserver[T](
    subscription = subscription, 
    complete = onSourceCompletion,
    error = onSourceError
  ) 
  source.subscribe(connection)

proc next[T](obs: Observable[T], value: T) =
  # Internal so it can't be used from the outside. 
  # Used internally to receive values from e.g. subjects
  for observer in obs.observers:
    observer.subscription(value)

### SUBJECT ###
type Subject*[T] = ref object of Observable[T]

proc newSubject*[T](): Subject[T] =
  Subject[T](
    observers: @[],
    getValue: proc(): Option[T] = none(T),
    completed: false,
  )

proc next*[T](subj: Subject[T], values: varargs[T]) =
  for observer in subj.observers:
    for value in values:
      observer.subscription(value)

proc asObservable*[T](source: Subject[T]): Observable[T] = source

### OPERATORS ###
type OperatorKind = enum
  mapper
  filter
  tapper

type OperatorObservable[SOURCE, RESULT] = ref object of Observable[RESULT]
  case kind: OperatorKind
  of mapper:
    mapProc: proc(value: SOURCE): RESULT {.closure.}
  of filter:
    filterProc: proc(value: RESULT): bool {.closure.}
  of tapper:
    tapProc: proc(value: RESULT) {.closure.}

# MAP # 
proc newMapObservable[SOURCE, RESULT](
  parent: Observable[SOURCE],
  mapper: proc(value: SOURCE): RESULT
): OperatorObservable[SOURCE, RESULT] =
  proc getValueClosure(): Option[RESULT] =
    let parentValue: Option[SOURCE] = parent.getValue()
    return parentValue.map(value => mapper(value))
  
  return OperatorObservable[SOURCE, RESULT](
    getValue: getValueClosure,
    observers: @[],
    kind: mapper,
    mapProc: mapper,
  )

proc map*[SOURCE, RESULT](
  source: Observable[SOURCE], 
  mapper: proc(value: SOURCE): RESULT
): OperatorObservable[SOURCE, RESULT] =
  ## Applies a given `mapper` function to each value emitted by `source`.
  ## Emits the mapped values in a new Observable
  let newObservable = newMapObservable[SOURCE, RESULT](source, mapper)

  proc mapSubscription(value: SOURCE) =
    let newValue = mapper(value)
    newObservable.next(newValue)

  source.connect(newObservable, mapSubscription)

  return newObservable

# FILTER #
proc newFilterObservable[A](
  parent: Observable[A],
  obsFilter: proc(value: A): bool
): OperatorObservable[A, A] =
  proc getValueClosure(): Option[A] =
    let parentValue: Option[A] = parent.getValue()
    return parentValue.filter(value => obsFilter(value))
  
  return OperatorObservable[A, A](
    getValue: getValueClosure,
    observers: @[],
    kind: filter,
    filterProc: obsFilter
  )

proc filter*[T](
  source: Observable[T], 
  filterCond: proc(value: T): bool {.closure.}
): OperatorObservable[T, T] =
  let newObservable = newFilterObservable[T](source, filterCond)
  
  proc filterSubscription(value: T) =
    if filterCond(value):
      newObservable.next(value)
  
  source.connect(newObservable, filterSubscription)
  return newObservable