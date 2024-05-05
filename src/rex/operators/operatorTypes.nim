import std/[asyncdispatch, importutils, sequtils]
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
    await observer.complete()
  
  let forwardError: ErrorCallback = proc(error: ref CatchableError) {.async.} =
    await observer.error(error)
  
  return newObserver[SOURCE](
    next = next, 
    complete = forwardComplete,
    error = forwardError
  ) 

proc completeOperatorObservable*[T](observable: Observable[T]) {.async.} =
  ## Starts completion of all subscribed observers at once and awaits them in parallel
  privateAccess(Observable)
  if observable.completed:
    return
  
  await all observable.observers.mapIt(it.complete())
  
  observable.observers = @[]
  observable.completed = true