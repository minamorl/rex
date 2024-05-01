import std/[sequtils]

# TODO:
# - Instead of a proc you don't export, try using importutils for really evil private field access
# - Implement error handling to call error callback when an error appears anywhere
# - Provide a second version of newObservable that takes in `proc[T](observer: Observer[T])`.
#     This likely will become a refactor because the assumption of "an observable contains a value" no longer holds up.
#     Instead it becomes "an observable holds a callback on how to execute observers"
# - Unsubscription mechanisms, because observables might outlive observers and thus they should be able to unsubscribe

type SubscriptionError = object of CatchableError

### TYPES / BASICS
type NextCallback*[T] = proc(value: T)
type ErrorCallback* = proc(error: CatchableError)
type CompleteCallback* = proc()
type 
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
  
  let hasCompleteCallback = not observer.complete.isNil()
  if reactable.completed and hasCompleteCallback:
    observer.complete()
  
  if not reactable.completed:  
    reactable.observers.add(observer)
  
  if reactable.hasInitialValues:
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
    let hasCompleteCallback = not observer.complete.isNil()
    if hasCompleteCallback:
      observer.complete()
  reactable.observers = @[]

proc connect*[T, U](source: Observable[T], target: Observable[U], next: proc(value: T)) =    
  proc onSourceCompletion() = complete(target)

  proc onSourceError(error: CatchableError) =
    for observer in target.observers:
      if not observer.error.isNil():
        observer.error(error)
  
  let connection = newObserver[T](
    next = next, 
    complete = onSourceCompletion,
    error = onSourceError
  ) 
  discard source.subscribe(connection)
