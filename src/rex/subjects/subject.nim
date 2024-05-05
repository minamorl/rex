import std/[importutils, asyncdispatch, sequtils]
import ../core

type Subject*[T] = ref object of Observable[T]
  nextProc: proc(values: seq[T]) {.async, closure.}

proc internalNext[T](subj: Subject[T], value: T) {.async.} =
  ## Iterates over the list of observers of the subject and calls
  ## their next callbacks with the new value
  privateAccess(Observable)
  # Observers may remove themselves from that list as they get
  # triggered (e.g. if they stem from (take(1))), therefore we can't
  # iterate over them directly, we iterate over a copy of the initial list
  # and then check each time if the observer is still allowed to be called.
  let initialObserverList = subj.observers
  var futures: seq[Future[void]] = @[]
  
  for obs in initialObserverList:
    let isStillObserver = subj.observers.contains(obs)
    if isStillObserver:
      futures.add obs.next(value)
  
  await all(futures)

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
      await subj.internalNext(value)

  subj.nextProc = subjNext
  
  subj.completeProc = proc() {.async.} =
    subj.completed = true
    
    let futures: seq[Future[void]] = subj.observers
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