import ./operatorTypes
import std/[importutils, monotimes, times]

proc throttleComplete[T](observable: Observable[T]) =
  privateAccess(Observable)
  if observable.completed:
    return
  
  for observer in observable.observers:
    if observer.hasCompleteCallback():
      observer.complete()
  
  observable.observers = @[]
  observable.completed = true

proc throttleSubscribe[T](
  observable: Observable[T], 
  observer: Observer[T],
  throttleProc: proc(value: T): Duration {.closure.}
) =
  var lastTriggerTime: MonoTime
  proc onParentNext(value: T) =
      let delay = throttleProc(value)
      let now = getMonoTime()
      let elapsed = now - lastTriggerTime
      if elapsed >= delay:
        lastTriggerTime = now
        observer.next(value)
  
  let parentObserver = newForwardingObserver(observer, onParentNext)
  observable.subscribe(parentObserver)

proc throttle*[T](
  source: Observable[T], 
  throttleProc: proc(value: T): Duration {.closure.}
): Observable[T] =
  privateAccess(Observable)
  let throttleObservable = Observable[T](
    completed: source.completed,
    observers: @[]
  )
  
  throttleObservable.completeProc = proc() =
    throttleComplete(throttleObservable)
  
  throttleObservable.subscribeProc = proc(observer: Observer[T]) =
    throttleSubscribe(source, observer, throttleProc)
    
  return throttleObservable