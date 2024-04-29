import rex
# test_rex.nim

import rex
import std/[unittest, sugar]

suite "Observable":
  test """
    GIVEN a cold observable
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
  
  # TODO tests for observables:
  # test: """
  #   GIVEN a cold observable with a subscriber with an error callback
  #   WHEN subscription callback throws an error
  #   THEN it should call the error callback
  # """
