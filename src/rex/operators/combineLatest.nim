import ./operatorTypes
import std/[importutils, options]

type CombinationMember[T] = ref tuple[obs: Observable[T], latest: Option[T]]

proc combineLatest*[A, B](
  source1Obs: Observable[A],
  source2Obs: Observable[B] 
): Observable[(A, B)] =
  privateAccess(Observable)
  privateAccess(Subscription)
  
  let combinedObservable = Observable[(A, B)](
    completed: source1Obs.completed and source2Obs.completed,
    observers: @[]
  )
  
  let source1: CombinationMember[A] = new(CombinationMember[A])
  source1[] = (source1Obs, none(A))
  let source2: CombinationMember[B] = new (CombinationMember[B])
  source2[] = (source2Obs, none(B))
  
  combinedObservable.completeProc = proc() {.async.} =
    await completeOperatorObservable(combinedObservable)
  
  combinedObservable.subscribeProc = proc(observer: Observer[(A, B)]): Subscription =
    proc onSource1Next(value: A) {.async.} =
      source1.latest = some(value)
      if source1.latest.isSome() and source2.latest.isSome():
        await observer.next((source1.latest.get(), source2.latest.get()))
    let source1Observer = newForwardingObserver(observer, onSource1Next)
    let subscription1 = source1.obs.subscribe(source1Observer)
    
    proc onSource2Next(value: B) {.async.} =
      source2.latest = some(value)
      if source1.latest.isSome() and source2.latest.isSome():
        await observer.next((source1.latest.get(), source2.latest.get()))
    let source2Observer = newForwardingObserver(observer, onSource2Next)
    let subscription2 = source2.obs.subscribe(source2Observer)
    
    return Subscription(
      unsubscribeProc: proc() =
        subscription1.unsubscribe()
        subscription2.unsubscribe()
    )

  return combinedObservable