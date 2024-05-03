import std/[importutils]
import ../core
export core

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
  
  proc forwardNext(source: SOURCE) = 
    try:
      next(source)
    except CatchableError as e:
      forwardError(e)
  
  return newObserver[SOURCE](
    next = next, 
    complete = forwardComplete,
    error = forwardError
  ) 

proc completeOperatorObservable*[T](observable: Observable[T]) =
  privateAccess(Observable)
  if observable.completed:
    return
  
  for observer in observable.observers:
    if observer.hasCompleteCallback():
      observer.complete()
  
  observable.observers = @[]
  observable.completed = true