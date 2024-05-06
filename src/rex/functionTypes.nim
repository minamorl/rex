import std/asyncdispatch
export asyncdispatch

type ReactiveError* = ref CatchableError
type SubscriptionError* = ReactiveError

type 
  NextCallback*[T] = proc(value: T) {.async, closure.}
  SyncNextCallback*[T] = proc(value: T) {.closure.}
  ErrorCallback* = proc(error: ref CatchableError) {.async, closure.}
  SyncErrorCallback* = proc(error: ref CatchableError) {.closure.}
  CompleteCallback* = proc() {.async, closure.}
  SyncCompleteCallback* = proc() {.closure.}

proc completeDoNothing*() {.async.} = discard

converter toAsync*(errorProc: SyncErrorCallback): ErrorCallback =
  ## Enables implicitly converting synchronous error closures into asynchronous error closures.
  return if errorProc.isNil():
      nil
    else:
      proc(error: ref CatchableError) {.async, closure.} = errorProc(error)

converter toAsync*(errorProc: proc(error: ref CatchableError) {.nimcall.}): ErrorCallback =
  ## Enables implicitly converting synchronous error callbacks that are not closures into asynchronous error closures.
  return if errorProc.isNil():
      nil
    else:
      proc(error: ref CatchableError) {.async, closure.} = errorProc(error)
    
converter toAsync*(complete: SyncCompleteCallback): CompleteCallback =
  ## Enables implicitly converting synchronous complete closures into asynchronous complete closures.
  return if complete.isNil():
    nil
  else:
    proc() {.async, closure.} = complete()

converter toAsync*(complete: proc() {.nimcall.}): CompleteCallback =
  ## Enables implicitly converting synchronous complete callbacks that are not closures into asynchronous complete closures.
  return if complete.isNil():
    nil
  else:
    proc() {.async, closure.} = complete()

converter toAsync*[T](next: SyncNextCallback[T]): NextCallback[T] =
  ## Enables implicitly converting synchronous next closures into asynchronous next closures.
  return if next.isNil():
    nil
  else:
    proc(value: T) {.async, closure.} = next(value)

converter toAsync*[T](next: proc(value: T) {.nimcall.}): NextCallback[T] =
  ## Enables implicitly converting synchronous next callbacks that are not closures into asynchronous next closures.
  return if next.isNil():
    nil
  else:
    proc(value: T) {.async, closure.} = next(value)