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

  Observable*[T] = ref object of RootObj
    observers: seq[Observer[T]]
    subscribeProc: proc(observer: Observer[T])
    completeProc: proc()
    completed: bool
  
  Subscription*[T] = ref object
    observable: Observable[T]
    observer: Observer[T]

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

proc newSubscription[T](observable: Observable[T], observer: Observer[T]): Subscription[T] =
  Subscription[T](observable: observable, observer: observer)

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

proc removeObserver*[T](reactable: Observable[T], observer: Observer[T]) =
  let filteredObservers = reactable.observers.filterIt(it != observer)
  reactable.observers = filteredObservers

proc unsubscribe*[T](subscription: Subscription[T]) =
  subscription.observable.removeObserver(subscription.observer)

proc newObservable*[T](valueProc: proc(observer: Observer[T])): Observable[T] =
  result = Observable[T](
    observers: @[],
    completed: true,
    completeProc: proc() = discard
  )
  
  proc subscribeProc(observer: Observer[T]) =
    rerouteError(observer):
      valueProc(observer)
  
  result.subscribeProc = subscribeProc

proc newObservable*[T](value: T): Observable[T] =
  proc valueProc(observer: Observer[T]) =
    observer.next(value)
    
    if observer.hasCompleteCallback():
      observer.complete()
    
  return newObservable(valueProc)


proc subscribe*[T](
  reactable: Observable[T]; 
  observer: Observer[T]
): Subscription[T] {.discardable.} =  
  reactable.subscribeProc(observer)
  return newSubscription(reactable, observer)

proc subscribe*[T](
  reactable: Observable[T],
  next: NextCallback[T],
  error: ErrorCallback = nil,
  complete: CompleteCallback = nil
): Subscription[T] {.discardable.} =
  let observer = newObserver[T](next, error, complete)
  return reactable.subscribe(observer)

proc complete*[T](reactable: Observable[T]) =
  if reactable.completed:
    return
  
  reactable.completeProc()