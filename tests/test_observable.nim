import rex
# test_rex.nim

import rex
import std/[unittest, sugar, importutils]

suite "Observable":
  test """
    GIVEN a cold observable created from value
    WHEN subscribing to it
    THEN it should emit the value it contains
  """:
    # GIVEN
    var receivedValues: seq[int] = @[]
    let obsValue = 5
    let observer = newObserver[int]((value: int) => receivedValues.add(value))
    let observable = newObservable[int](obsValue)
    
    # WHEN
    observable.subscribe(observer)
    
    # THEN
    check receivedValues == @[obsValue]
  
  test """
    GIVEN a cold observable created from observable callback
    WHEN subscribing to it
    THEN it should emit the values that the callback emits
  """:
    # GIVEN
    var receivedValues: seq[int] = @[]
    let obsValue1 = 5
    let obsValue2 = 3
    let obsValue3 = 4
    let observable = newObservable[int](
      proc(observer: Observer[int]) =
        observer.next(obsValue1)
        observer.next(obsValue2)
        observer.next(obsValue3) 
    )
    
    # WHEN
    observable.subscribe((value: int) => receivedValues.add(value))
    
    # THEN
    check receivedValues == @[obsValue1, obsValue2, obsValue3]
  
  test """
    GIVEN a cold observable
    WHEN subscribing to it with a complete callback
    THEN it should call the complete callback after emitting the value
  """:
    # GIVEN
    var receivedValues: seq[int] = @[]
    var completedValues: seq[int] = @[]
    let obsValue = 5
    let observable = newObservable[int](obsValue)
    
    # WHEN
    observable.subscribe(
      (value: int) => receivedValues.add(value),
      error = nil,
      complete = () => completedValues.add(obsValue)
    )
    
    # THEN
    check receivedValues == @[obsValue]
    check completedValues == @[obsValue]

  test """
    GIVEN a cold observable with one subscriber
    WHEN subscribing to it
    THEN it should emit the value it contains once for each subscriber in total
  """:
    # GIVEN
    var receivedValues1: seq[int] = @[]
    var receivedValues2: seq[int] = @[]
    let obsValue = 5
    let observable = newObservable[int](obsValue)
    observable.subscribe((value: int) => receivedValues1.add(value))
    check receivedValues1 == @[obsValue]
    
    # WHEN
    observable.subscribe((value: int) => receivedValues2.add(value))
    
    # THEN
    check receivedValues1 == @[obsValue]
    check receivedValues2 == @[obsValue]
  
  test """
    GIVEN a cold observable with one subscriber
    WHEN unsubscribing from it
    THEN it should not have any observers/subscribers
  """:
    # GIVEN
    var receivedValues: seq[int] = @[]
    let observable = newObservable[int](5)
    let subscription = observable.subscribe((value: int) => receivedValues.add(value))
    
    # WHEN
    subscription.unsubscribe()
    
    # THEN
    privateAccess(Observable[int])
    check observable.observers.len == 0
      
  test """
    GIVEN a cold observable with a subscriber with an error callback
    WHEN observable callback throws an error
    THEN it should call the error callback
  """:
    # GIVEN
    var receivedErrors: seq[ref CatchableError] = @[]
    var receivedValues: seq[int] = @[]
    let observable = newObservable[int](
      proc(observer: Observer[int]) =
        observer.next(5)
        
        raise newException(ValueError, "Some error")
    )
    
    # WHEN
    observable.subscribe(
      next = (value: int) => receivedValues.add(value),
      error = (error: ref CatchableError) => receivedErrors.add(error)
    )
    
    check receivedValues == @[5]
    check receivedErrors.len == 1
    check receivedErrors[0].msg == "Some error"
  
  test """
    GIVEN a cold observable with a subscriber without an error callback
    WHEN observable callback throws an error
    THEN it should do nothing
  """:
    # GIVEN
    var receivedValues: seq[int] = @[]
    let observable = newObservable[int](
      proc(observer: Observer[int]) =
        observer.next(5)
        
        raise newException(ValueError, "Some error")
    )
    
    # WHEN
    observable.subscribe(
      next = (value: int) => receivedValues.add(value)
    )
    
    check receivedValues == @[5]

  test """
    GIVEN a cold observable with multiple subscriptions with an error callback
    WHEN observable callback throws an error
    THEN it should call the error callback on each subscription once
  """:
    # GIVEN
    var receivedErrors1: seq[ref CatchableError] = @[]
    var receivedErrors2: seq[ref CatchableError] = @[]
    let observable = newObservable[int](
      proc(observer: Observer[int]) =
        observer.next(5)
        
        raise newException(ValueError, "Some error")
    )
    
    # WHEN
    observable.subscribe(
      next = (value: int) => echo "",
      error = (error: ref CatchableError) => receivedErrors1.add(error)
    )
    observable.subscribe(
      next = (value: int) => echo "",
      error = (error: ref CatchableError) => receivedErrors2.add(error)
    )
    
    # THEN
    check receivedErrors1.len == 1
    check receivedErrors1[0].msg == "Some error"
    check receivedErrors2.len == 1
    check receivedErrors2[0].msg == "Some error"

  test """
    GIVEN a cold observable with a subscriber with an error callback
    WHEN subscription callback throws an error
    THEN it should call the error callback
  """:
    # GIVEN
    var receivedErrors: seq[ref CatchableError] = @[]
    var receivedValues: seq[int] = @[]
    let observable = newObservable[int](
      proc(observer: Observer[int]) =
        observer.next(5)
        observer.next(4)
        observer.next(3)
    )
    
    # WHEN
    observable.subscribe(
      next = proc(value: int) = 
        receivedValues.add(value)
        raise newException(ValueError, "Some error"),
      error = (error: ref CatchableError) => receivedErrors.add(error)
    )
    
    check receivedValues == @[5, 4, 3]
    check receivedErrors.len == 3
    check receivedErrors[0].msg == "Some error"

  test """
    GIVEN a cold observable with multiple subscriptions with an error callback
    WHEN subscription callback throws an error
    THEN it should call the error callback for that subscription
  """:
    # GIVEN
    var receivedErrors1: seq[ref CatchableError] = @[]
    var receivedErrors2: seq[ref CatchableError] = @[]
    var receivedValues1: seq[int] = @[]
    var receivedValues2: seq[int] = @[]
    let observable = newObservable[int](
      proc(observer: Observer[int]) =
        observer.next(5)
        observer.next(4)
        observer.next(3)
    )
    
    # WHEN
    observable.subscribe((value: int) => receivedValues1.add(value))
    observable.subscribe(
      next = proc(value: int) = raise newException(ValueError, "Some error"),
      error = (error: ref CatchableError) => receivedErrors1.add(error)
    )    
    observable.subscribe(
      next = proc(value: int) = raise newException(ValueError, "Some error"),
      error = (error: ref CatchableError) => receivedErrors2.add(error)
    )
    observable.subscribe((value: int) => receivedValues2.add(value))
    
    check receivedErrors1.len == 3
    check receivedErrors1[0].msg == "Some error"
    check receivedErrors2.len == 3
    check receivedErrors2[0].msg == "Some error"
    check receivedValues1 == @[5, 4, 3]
    check receivedValues2 == @[5, 4, 3]