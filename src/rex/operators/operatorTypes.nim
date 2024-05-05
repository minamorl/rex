import std/[asyncdispatch, importutils]
import ../core
export core, asyncdispatch, importutils

proc newForwardingObserver*[SOURCE, RESULT](
  observer: Observer[RESULT],
  next: NextCallback[SOURCE]
): Observer[SOURCE] =
  ## Creates an observer that forward all events to another observer
  ## This is used particularly for initial data handling when subscribing
  ## to e.g. cold observables.
  let  forwardComplete: CompleteCallback = proc() {.async.} = 
    if observer.hasCompleteCallback():
      await observer.complete()
  
  let forwardError: ErrorCallback = proc(error: ref CatchableError) {.async.} =
    if observer.hasErrorCallback():
      await observer.error(error)
  
  return newObserver[SOURCE](
    next = next, 
    complete = forwardComplete,
    error = forwardError
  ) 

proc completeOperatorObservable*[T](observable: Observable[T]) {.async.} =
  privateAccess(Observable)
  if observable.completed:
    return
  
  for observer in observable.observers:
    if observer.hasCompleteCallback():
      await observer.complete()
  
  observable.observers = @[]
  observable.completed = true