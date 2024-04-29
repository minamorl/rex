import std/[times, monotimes, os, options, sugar]

# TODO:
# - Instead of a proc you don't export, try using importutils for really evil private field access
# - Provide `of` and use "newObservable" only internally. Then you can test complete callbacks.

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
  Observer[T](subscription: subscription, error: error, complete: complete)

### OBSERVABLE ###
type Observable*[T] = ref object of RootObj
  observers: seq[Observer[T]]
  getValue: proc(): Option[T] {.closure.}
  completed: bool

proc value*[T](obs: Observable[T]): Option[T] = obs.getValue()
proc `value=`*[T](obs: Observable[T], valueGetter: proc(): Option[T] {.closure.}) =
  obs.getValue = valueGetter
  
proc forward*[T](obs: Observable[T], value: T) =
  # For internal usage only. Forwards a value when e.g. a subject is underneath the type
  for observer in obs.observers:
    observer.subscription(value)

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
    return
  
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
