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
    if not observer.complete.isNil():
      observer.complete()
  
  proc forwardError(error: CatchableError) =
    if not observer.error.isNil():
      observer.error(error)
  
  return newObserver[SOURCE](
    next = next, 
    complete = forwardComplete,
    error = forwardError
  ) 

proc forward*[T](source: Observable[T], value: T) =
  privateAccess(Observable[T])
  for observer in source.observers:
    observer.next(value)