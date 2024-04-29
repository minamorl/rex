import std/[times, monotimes, os, options, sugar]

# TODO:
# - Instead of a proc you don't export, try using importutils for really evil private field access
# - Implement error handling to call error callback when an error appears anywhere
# - Provide a second version of newObservable that takes in `proc[T](observer: Observer[T])`.
#     This likely will become a refactor because the assumption of "an observable contains a value" no longer holds up.
#     Instead it becomes "an observable holds a callback on how to execute observers"
# - Unsubscription mechanisms, because observables might outlive observers and thus they should be able to unsubscribe

### TYPES / BASICS
type SubscriptionCallback*[T] = proc(value: T)
type ErrorCallback* = proc(error: CatchableError)
type CompleteCallback* = proc()
type Observer*[T] = ref object
  subscription*: SubscriptionCallback[T]
  error*: ErrorCallback
  complete*: CompleteCallback

proc newObserver*[T](
  subscription: SubscriptionCallback[T], 
  error: ErrorCallback = nil,
  complete: CompleteCallback = nil
): Observer[T] =
  Observer[T](
    subscription: subscription, 
    error: error, 
    complete: complete
  )

### OBSERVABLE ###
type Observable*[T] = ref object of RootObj
  observers: seq[Observer[T]]
  getValue: proc(): Option[T] {.closure.}
  completed: bool

proc newObservable*[T](value: T): Observable[T] = 
  Observable[T](
    observers: @[],
    getValue: proc(): Option[T] = some(value),
    completed: true
  )

proc subscribe*[T](reactable: Observable[T]; observer: Observer[T]) =
  let hasCompleteCallback = not observer.complete.isNil()
  if reactable.completed and hasCompleteCallback:
    observer.complete()
  
  if not reactable.completed:  
    reactable.observers.add(observer)
  
  let initialValue = reactable.getValue()
  let hasInitialValue = initialValue.isSome()
  if hasInitialValue:
    observer.subscription(initialValue.get())

proc subscribe*[T](
  reactable: Observable[T],
  subscription: SubscriptionCallback[T],
  error: ErrorCallback = nil,
  complete: CompleteCallback = nil
) =
  let observer = newObserver[T](subscription, error, complete)
  reactable.subscribe(observer)


proc complete*[T](reactable: Observable[T]) =
  if reactable.completed:
    return
  
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
