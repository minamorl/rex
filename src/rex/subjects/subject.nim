import std/[importutils, asyncdispatch, sequtils]
import ../core

type Subject*[T] = ref object of Observable[T]
  nextProc: proc(values: seq[T]) {.async, closure.}

proc newSubject*[T](): Subject[T] =
  privateAccess(Observable)
  privateAccess(Subscription)
  
  let subj = Subject[T](
    completed: false,
    observers: @[]
  )
  
  subj.subscribeProc = proc(observer: Observer[T]): Subscription =
    if subj.completed:
      return EMPTY_SUBSCRIPTION
    
    subj.observers.add(observer)
    
    return newSubscription(subj, observer)
  
  proc subjNext(values: seq[T]) {.async, closure.} =
    privateAccess(Observable)
    if subj.completed:
      return
    
    for value in values:
      for obs in subj.observers:
        await obs.next(value)
  subj.nextProc = subjNext
  
  subj.completeProc = proc() {.async.} =
    subj.completed = true
    
    let futures: seq[Future[void]] = subj.observers
      .filterIt(it.hasCompleteCallback())
      .mapIt(it.complete())
    await all(futures)

    subj.observers = @[]
  
  return subj

proc next*[T](subj: Subject[T], values: varargs[T]) {.async.} =
  await subj.nextProc(values.toSeq())

proc nextBlock*[T](subj: Subject[T], values: varargs[T]) =
  waitFor subj.nextProc(values.toSeq())

proc complete*[T](subj: Subject[T]) {.async.} =
  privateAccess(Observable)
  if subj.completed:
    return
  
  await subj.completeProc()

proc completeBlock*[T](subj: Subject[T]) =
  waitFor subj.complete()

proc asObservable*[T](source: Subject[T]): Observable[T] = source