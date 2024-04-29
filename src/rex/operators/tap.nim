import ./operatorTypes

proc tap*[T](
  source: Observable[T], 
  observer: Observer[T],
): Observable[T] =
  source.subscribe(observer)
  return source

proc tap*[T](
  source: Observable[T],
  tapProc: SubscriptionCallback[T],
  error: ErrorCallback = nil,
  complete: CompleteCallback = nil
): Observable[T] =
  let observer = newObserver[T](tapProc, error, complete)
  return source.tap(observer)