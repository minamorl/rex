import ./functionTypes

type Observer*[T] = ref object
  nextProc: NextCallback[T]
  errorProc: ErrorCallback
  completeProc: CompleteCallback

proc `next=`*[T](observer: Observer[T], next: NextCallback[T]) =
  observer.nextProc = next
  
proc `error=`*[T](observer: Observer[T], error: ErrorCallback) =
  observer.errorProc = error
  
proc `complete=`*[T](observer: Observer[T], complete: CompleteCallback) =
  observer.completeProc = complete

proc hasNextCallback*[T](observer: Observer[T]): bool =
  return not observer.nextProc.isNil()

proc hasErrorCallback*[T](observer: Observer[T]): bool =
  return not observer.errorProc.isNil()

proc hasCompleteCallback*[T](observer: Observer[T]): bool =
  return not observer.completeProc.isNil()

proc next*[T](observer: Observer[T], value: T) {.async.} =
  if observer.hasNextCallback():
    await observer.nextProc(value)

proc error*(observer: Observer, error: ref CatchableError) {.async.} =
  if observer.hasErrorCallback():
    await observer.errorProc(error)

proc complete*(observer: Observer) {.async.} =
  if observer.hasCompleteCallback():
    await observer.completeProc()

proc newObserver*[T](
  next: NextCallback[T],
  error: ErrorCallback = nil,
  complete: CompleteCallback = nil
): Observer[T] =
  proc nextProc(value: T) {.async.} =
    try:
      await next(value)
    except CatchableError as e:
      if not error.isNil():
        await error(e)

  return Observer[T](
    nextProc: nextProc, 
    errorProc: error, 
    completeProc: complete,
  )
