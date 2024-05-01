import ./operatorTypes
import std/[importutils, monotimes, times]

proc newThrottleObservable[T](
  parent: Observable[T],
  throttleProc: proc(value: T): Duration {.closure.}
): Observable[T] =
  proc initialHandler(childObserver: Observer[T]) =
    ## Handles forwarding events for when somebody initially subscribes to an observable.
    ## The childObserver is either a temporary observer created for only this purpose or the
    ## observer provided for subscribing.
    var lastTriggerTime: MonoTime
    proc onNextInitially(value: T) =
      rerouteError(childObserver):
        let delay = throttleProc(value)
        let now = getMonoTime()
        let elapsed = now - lastTriggerTime
        if elapsed >= delay:
          lastTriggerTime = now
          childObserver.next(value)
    let tempObserver = newForwardingObserver(childObserver, onNextInitially)
    
    privateAccess(Observable[T])
    parent.initialHandler(tempObserver)
    parent.removeObserver(tempObserver)
  
  return toNewObservable(parent, initialHandler)

proc throttle*[T](
  source: Observable[T], 
  throttleProc: proc(value: T): Duration {.closure.}
): Observable[T] =
  let newObservable = newThrottleObservable[T](source, throttleProc)
  
  var lastTriggerTime: MonoTime
  proc throttleSubscription(value: T) =
      let delay = throttleProc(value)
      let now = getMonoTime()
      let elapsed = now - lastTriggerTime
      if elapsed >= delay:
        lastTriggerTime = now
        newObservable.forward(value)
  
  source.connect(newObservable, throttleSubscription)
  return newObservable