import std/[importutils]
import ../core
export core

proc toNewObservable*[SOURCE, RESULT](
  source: Observable[SOURCE],
  initialHandler: proc(observer: Observer[RESULT]) {.closure.}
): Observable[RESULT] =
  privateAccess(Observable[SOURCE])
  return Observable[RESULT](
    completed: source.completed,
    hasInitialValues: source.hasInitialValues,
    initialHandler: initialHandler,
  )

proc newForwardingObserver*[SOURCE, RESULT](
  observer: Observer[RESULT],
  next: NextCallback[SOURCE]
): Observer[SOURCE] =
  ## Creates an observer that forward all events to another observer
  ## This is used particularly for initial data handling when subscribing
  ## to e.g. cold observables.
  proc forwardComplete() = 
    if observer.hasCompleteCallback():
      observer.complete()
  
  proc forwardError(error: ref CatchableError) =
    if observer.hasErrorCallback():
      observer.error(error)
  
  return newObserver[SOURCE](
    next = next, 
    complete = forwardComplete,
    error = forwardError
  ) 

proc newConnectingObserver[SOURCE, RESULT](
  source: Observable[SOURCE], 
  target: Observable[RESULT], 
  next: NextCallback[SOURCE]
): Observer[SOURCE] =
  ## Creates an observer that connects a source observable to the given target observable
  ## All value-, error- and complete-events from source get forwarded to target,
  ## so that it can distribute those events to its own observers.
  proc onSourceCompletion() = complete(target)

  proc onSourceError(error: ReactiveError) =
    privateAccess(Observable)
    for observer in target.observers:
      if observer.hasErrorCallback():
        observer.error(error)
  
  return newObserver[SOURCE](
    next = next, 
    complete = onSourceCompletion,
    error = onSourceError
  ) 

proc connect*[SOURCE, RESULT](
  source: Observable[SOURCE], 
  target: Observable[RESULT], 
  next: NextCallback[SOURCE]
) =
  let connection =newConnectingObserver(source, target, next)
  discard source.subscribe(connection)

proc forward*[T](source: Observable[T], value: T) =
  privateAccess(Observable)
  for observer in source.observers:
    observer.next(value)