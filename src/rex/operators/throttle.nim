import ./operatorTypes
import std/[importutils, monotimes, times]

proc throttleSubscribe[T](
  observable: Observable[T], 
  destinationObserver: Observer[T],
  throttleProc: proc(value: T): Duration {.closure.}
): Subscription =
  var lastTriggerTime: MonoTime
  proc onSourceNext(value: T) {.async.} =
      let delay = throttleProc(value)
      let now = getMonoTime()
      let elapsed = now - lastTriggerTime
      if elapsed >= delay:
        lastTriggerTime = now
        await destinationObserver.next(value)
  
  let sourceObserver = newForwardingObserver(destinationObserver, onSourceNext)
  let subscription = observable.subscribe(sourceObserver)

  privateAccess(Subscription)
  return Subscription(
    unsubscribeProc: proc() = subscription.unsubscribe()
  )

proc throttle*[T](
  source: Observable[T], 
  throttleProc: proc(value: T): Duration {.closure.}
): Observable[T] =
  privateAccess(Observable)
  let throttleObservable = Observable[T](
    completed: source.completed,
    observers: @[]
  )
  
  throttleObservable.completeProc = proc() {.async.} =
    await completeOperatorObservable(throttleObservable)
  
  throttleObservable.subscribeProc = proc(observer: Observer[T]): Subscription =
    return throttleSubscribe(source, observer, throttleProc)
    
  return throttleObservable