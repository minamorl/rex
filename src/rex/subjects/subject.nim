import std/[importutils]
import ../core

type Subject*[T] = ref object of Observable[T]
  nextProc: proc(value: T)

proc newSubject*[T](): Subject[T] =
  privateAccess(Observable)
  privateAccess(Subscription)
  
  let subj = Subject[T](
    completed: false,
    observers: @[]
  )
  
  subj.subscribeProc = proc(observer: Observer[T]): Subscription =
    if subj.completed:
      return
    
    subj.observers.add(observer)
    
    return Subscription(
      unsubscribeProc: proc() = subj.removeObserver(observer)
    )
  
  subj.nextProc = proc(value: T) =
    for observer in subj.observers:
      observer.next(value)
    
  subj.completeProc = proc() =
    for observer in subj.observers:
      if observer.hasCompleteCallback():
        observer.complete()
    
    subj.completed = true
    subj.observers = @[]
  
  return subj

proc next*[T](subj: Subject[T], values: varargs[T]) =
  privateAccess(Observable)
  if subj.completed:
    return
  
  for value in values:
      subj.nextProc(value)

proc complete*[T](subj: Subject[T]) =
  privateAccess(Observable)
  if subj.completed:
    return
  
  subj.completeProc()

proc asObservable*[T](source: Subject[T]): Observable[T] = source