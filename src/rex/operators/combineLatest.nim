import ./operatorTypes
import std/[importutils, options]

type CombinationMember[T] = ref tuple[obs: Observable[T], latest: Option[T]]

proc combinedComplete[T](observable: Observable[T]) =
  privateAccess(Observable)
  if observable.completed:
    return
  
  for observer in observable.observers:
    if observer.hasCompleteCallback():
      observer.complete()
  
  observable.observers = @[]
  observable.completed = true

proc combineLatest*[A, B](
  source1Obs: Observable[A],
  source2Obs: Observable[B] 
): Observable[(A, B)] =
  privateAccess(Observable)
  let combinedObservable = Observable[(A, B)](
    completed: source1Obs.completed and source2Obs.completed,
    observers: @[]
  )
  
  let source1: CombinationMember[A] = new(CombinationMember[A])
  source1[] = (source1Obs, none(A))
  let source2: CombinationMember[B] = new (CombinationMember[B])
  source2[] = (source2Obs, none(B))
  
  combinedObservable.completeProc = proc() =
    combinedComplete(combinedObservable)
  
  combinedObservable.subscribeProc = proc(observer: Observer[(A, B)]) =
    proc onSource1Next(value: A) =
      source1.latest = some(value)
      if source1.latest.isSome() and source2.latest.isSome():
        observer.next((source1.latest.get(), source2.latest.get()))
    let source1Observer = newForwardingObserver(observer, onSource1Next)
    source1.obs.subscribe(source1Observer)
    
    proc onSource2Next(value: B) =
      source2.latest = some(value)
      if source1.latest.isSome() and source2.latest.isSome():
        observer.next((source1.latest.get(), source2.latest.get()))
    let source2Observer = newForwardingObserver(observer, onSource2Next)
    source2.obs.subscribe(source2Observer)

  return combinedObservable