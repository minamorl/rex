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
    subscribeProc: proc(observer: Observer[T]): Subscription
    completeProc: proc()
    completed: bool
  
  Subscription* = ref object
    unsubscribeProc: proc()

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

proc removeObserver*[T](reactable: Observable[T], observer: Observer[T]) =
  let filteredObservers = reactable.observers.filterIt(it != observer)
  reactable.observers = filteredObservers

proc newSubscription[A, B](observable: Observable[A], observer: Observer[B]): Subscription =
  proc unsubscribeProc() =
    observable.removeObserver(observer)

  return Subscription(unsubscribeProc: unsubscribeProc)

proc unsubscribe*(subscription: Subscription) =
  subscription.unsubscribeProc()
  
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
  let newObs = Observable[T](
    observers: @[],
    completed: true,
    completeProc: proc() = discard
  )
  
  proc subscribeProc(observer: Observer[T]): Subscription =
    rerouteError(observer):
      valueProc(observer)
    
    return newSubscription(newObs, observer)
  newObs.subscribeProc = subscribeProc
  
  return newObs

proc newObservable*[T](value: T): Observable[T] =
  proc valueProc(observer: Observer[T]) =
    observer.next(value)
    
    if observer.hasCompleteCallback():
      observer.complete()
    
  return newObservable(valueProc)

proc subscribe*[T](
  reactable: Observable[T]; 
  observer: Observer[T]
): Subscription {.discardable.} =  
  return reactable.subscribeProc(observer)

proc subscribe*[T](
  reactable: Observable[T],
  next: NextCallback[T],
  error: ErrorCallback = nil,
  complete: CompleteCallback = nil
): Subscription {.discardable.} =
  let observer = newObserver[T](next, error, complete)
  return reactable.subscribe(observer)