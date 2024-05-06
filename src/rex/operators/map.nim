import ./operatorTypes

proc mapSubscribe[SOURCE, RESULT](
  source: Observable[SOURCE], 
  observer: Observer[RESULT],
  mapper: proc(value: SOURCE): RESULT {.closure.}
): Subscription = 
  proc onSourceNext(value: SOURCE) {.async.} =
    let newValue = mapper(value)
    await observer.next(newValue)
    
  let sourceObserver = newForwardingObserver(observer, onSourceNext)
  let subscription = source.subscribe(sourceObserver)
  
  return newSubscription(subscription)

proc map*[SOURCE, RESULT](
  source: Observable[SOURCE],
  mapper: proc(value: SOURCE): RESULT {.closure.}
): Observable[RESULT] =
  privateAccess(Observable)
  let mapObservable = Observable[RESULT](
    completed: source.completed,
    observers: @[],
  )
  
  mapObservable.completeProc = proc() {.async.} =
    await completeOperatorObservable(mapObservable)
  
  mapObservable.subscribeProc = proc(observer: Observer[RESULT]): Subscription =
    return mapSubscribe(source, observer, mapper)
    
  return mapObservable