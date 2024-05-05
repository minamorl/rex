import ./operatorTypes

proc mapSubscribe[SOURCE, RESULT](
  parent: Observable[SOURCE], 
  observer: Observer[RESULT],
  mapper: proc(value: SOURCE): RESULT {.closure.}
): Subscription = 
  proc onParentNext(value: SOURCE) {.async.} =
    let newValue = mapper(value)
    await observer.next(newValue)
    
  let parentObserver = newForwardingObserver(observer, onParentNext)
  let subscription = parent.subscribe(parentObserver)
  
  privateAccess(Subscription)
  return Subscription(
    unsubscribeProc: proc() = subscription.unsubscribe()
  )

proc map*[SOURCE, RESULT](
  parent: Observable[SOURCE],
  mapper: proc(value: SOURCE): RESULT {.closure.}
): Observable[RESULT] =
  privateAccess(Observable)
  let mapObservable = Observable[RESULT](
    completed: parent.completed,
    observers: @[],
  )
  
  mapObservable.completeProc = proc() {.async.} =
    await completeOperatorObservable(mapObservable)
  
  mapObservable.subscribeProc = proc(observer: Observer[RESULT]): Subscription =
    return mapSubscribe(parent, observer, mapper)
    
  return mapObservable