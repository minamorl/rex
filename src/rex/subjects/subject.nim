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
  
  subj.nextProc = proc(values: seq[T]) {.async, closure.} =
    ## Forwards new values to all subscribed observers at once and awaits them in parallel
    privateAccess(Observable)
    if subj.completed:
      return
    
    await all values.mapIt(subj.internalNext(it))
  
  subj.completeProc = proc() {.async.} =
    ## Starts completion of all subscribed observers at once and awaits them in parallel
    if subj.completed:
      return
    
    subj.completed = true
    
    await all subj.observers.mapIt(it.complete())

    subj.observers = @[]
  
  return subj

proc next*[T](subj: Subject[T], values: varargs[T]) {.async.} =
  ## Pushes a variable amount of new values through subject, forwarding it to all
  ## of subjects subscribers. 
  ## This operation is asynchronous, as any of the subject's observers may do 
  ## asynchronous work as part of their callbacks.
  ## 
  ## The returned future must be awaited for any remaining asynchronous work of these
  ## callbacks to be finished.
  await subj.nextProc(values.toSeq())

proc nextBlock*[T](subj: Subject[T], values: varargs[T]) =
  ## Convenience proc for `next`. Calls next and blocks until all asynchronous work is done.
  waitFor subj.nextProc(values.toSeq())

proc complete*[T](subj: Subject[T]) {.async.} =
  ## Completes the subject and informs all observers of that completion.
  ## 
  ## This operation is asynchronous, as any of the subject's observers may do 
  ## asynchronous work as part of their complete callbacks.
  privateAccess(Observable)
  if subj.completed:
    return
  
  await subj.completeProc()

proc completeBlock*[T](subj: Subject[T]) =
  ## Convenience proc for `complete`. Calls complete and blocks until all asynchronous work is done.
  waitFor subj.complete()

proc asObservable*[T](source: Subject[T]): Observable[T] = source