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

