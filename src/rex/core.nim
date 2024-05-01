import std/[sequtils]

# TODO:
# - Figure out how to unsubscribe the tap observer when the parent unsubscribes. Might be that tap does need to create a new observable. Then test tap accordingly
# - Implement combineLatest
# - Implement throttle

type ReactiveError* = ref CatchableError
type SubscriptionError* = ReactiveError

### TYPES / BASICS
type 
  NextCallback*[T] = proc(value: T)
  ErrorCallback* = proc(error: ReactiveError)
  CompleteCallback* = proc()
  Observer*[T] = ref object
    next*: NextCallback[T]
    error*: ErrorCallback
    complete*: CompleteCallback
    observed: Observable[T] # Observable this observer is subscribed to

  Observable*[T] = ref object of RootObj
    observers: seq[Observer[T]]
    initialHandler: proc(observer: Observer[T])
    hasInitialValues: bool # Indicates whether the observable has values that must be emitted immediately when somebody subscribes to it. If this is true, initialHandler *must* not be nil. This is true for cold observables, ReplaySubjects, BehaviorSubjects and similar
    completed: bool

proc hasErrorCallback*(observer: Observer): bool =
  not observer.error.isNil()

proc hasCompleteCallback*(observer: Observer): bool =
  not observer.complete.isNil()

template rerouteError*(observer: Observer, body: untyped) =
  try:
    body
  except CatchableError as e:
    if observer.hasErrorCallback():
      observer.error(e)
      
proc newObserver*[T](
  next: NextCallback[T], 
  error: ErrorCallback = nil,
  complete: CompleteCallback = nil,
): Observer[T] =
  Observer[T](
    next: next, 
    error: error, 
    complete: complete,
  )
  
proc newObservable*[T](valueProc: proc(observer: Observer[T])): Observable[T] =
  Observable[T](
    observers: @[],
    initialHandler: valueProc,
    hasInitialValues: true,
    completed: true
  )  

proc newObservable*[T](value: T): Observable[T] =
  proc handleObserver(observer: Observer[T]) =
    rerouteError(observer):
      observer.next(value)
    
  return newObservable(handleObserver)

proc removeObserver*[T](reactable: Observable[T], observer: Observer[T]) =
  let filteredObservers = reactable.observers.filterIt(it != observer)
  reactable.observers = filteredObservers

proc unsubscribe*[T](observer: Observer[T]) =
  removeObserver(observer.observed, observer)

proc subscribe*[T](
  reactable: Observable[T]; 
  observer: Observer[T]
): Observer[T] {.discardable.} =
  observer.observed = reactable
  
  if reactable.completed and observer.hasCompleteCallback():
    observer.complete()
  
  if not reactable.completed:  
    reactable.observers.add(observer)
  
  if reactable.hasInitialValues:
    rerouteError(observer):
      reactable.initialHandler(observer)
  
  return observer

proc subscribe*[T](
  reactable: Observable[T],
  next: NextCallback[T],
  error: ErrorCallback = nil,
  complete: CompleteCallback = nil
): Observer[T] {.discardable.} =
  let observer = newObserver[T](next, error, complete)
  return reactable.subscribe(observer)

proc complete*[T](reactable: Observable[T]) =
  if reactable.completed:
    return
  
  reactable.completed = true
  for observer in reactable.observers:
    if observer.hasCompleteCallback():
      observer.complete()
  reactable.observers = @[]