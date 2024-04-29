import rex
# test_rex.nim

import rex
import std/[times, os, unittest, sugar]

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

suite "Subject":
  test """
    GIVEN an int subject
    WHEN subscribing to it
    THEN it should not do anything
  """:
    # GIVEN
    let subject = newSubject[int]()
    var receivedValues: seq[int] = @[]
    let observer = newObserver[int]((value: int) => receivedValues.add(value))
    
    # WHEN
    subject.subscribe(observer)
    
    # THEN
    let expected: seq[int] = @[]
    check receivedValues == expected
  
  test """
    GIVEN an int subject that was subscribed to
    WHEN calling next on it with 1 value
    THEN it should emit that value to the subscriber
  """:
    # GIVEN
    let subject = newSubject[int]()
    var receivedValues: seq[int] = @[]
    
    # WHEN
    subject.subscribe((value: int) => receivedValues.add(value))
    subject.next(1)
    
    # THEN
    check receivedValues == @[1]
  
  test """
    GIVEN an int subject that was subscribed to
    WHEN calling next on it with 2 values
    THEN it should emit those values to the subscriber
  """:
    # GIVEN
    let subject = newSubject[int]()
    var receivedValues: seq[int] = @[]
    
    # WHEN
    subject.subscribe((value: int) => receivedValues.add(value))
    subject.next(1)
    subject.next(2)
    
    # THEN
    check receivedValues == @[1, 2]
    
  test """
    GIVEN an int subject with multiple subscribers
    WHEN calling next on it
    THEN it should emit the value to all subscribers
  """:
    # GIVEN
    let subject = newSubject[int]()
    var receivedValues1: seq[int] = @[]
    var receivedValues2: seq[int] = @[]
    
    # WHEN
    subject.subscribe((value: int) => receivedValues1.add(value))
    subject.subscribe((value: int) => receivedValues2.add(value))
    subject.next(1)
    
    # THEN
    check receivedValues1 == @[1]
    check receivedValues2 == @[1]

  test """
    GIVEN an int subject that was subscribed to with a complete callback
    WHEN calling complete on it
    THEN it should call the complete callback on the observer
  """:
    # GIVEN
    let subject = newSubject[int]()
    var receivedValues: seq[int] = @[]
    var completeValues: seq[int] = @[]
    subject.subscribe(
      (value: int) => receivedValues.add(value),
      nil,
      () => completeValues.add(1)
    )
    
    # WHEN
    subject.complete()
    
    # THEN
    let expectedReceivedValues: seq[int] = @[]
    check receivedValues == expectedReceivedValues
    check completeValues == @[1]

  # TODO tests for Subjects:
  # test: """
  #   GIVEN a cold observable with a subscriber with an error callback
  #   WHEN subscription callback throws an error
  #   THEN it should call the error callback
  # """

suite "Operators - map":
  test """
    GIVEN a cold int observable
    WHEN using the map operator to double the value
    THEN it should generate a new cold observable that emits the mapped value on subscribe
  """:
    # GIVEN
    var receivedValues: seq[int] = @[]
    let obsValue = 5
    let observable = newObservable[int](obsValue)
    let mappedObservable = observable.map((value: int) => value * 2)
    
    # WHEN
    mappedObservable.subscribe((value: int) => receivedValues.add(value))
    
    # THEN
    check receivedValues == @[obsValue * 2]

  test """
    GIVEN a cold int observable
    WHEN using the map operator to transform the value into a string
    THEN it should generate a new cold observable that emits the mapped value on subscribe
  """:
    # GIVEN
    var receivedValues: seq[string] = @[]
    let observable = newObservable[int](5)
    let mappedObservable = observable.map((value: int) => $value)
    
    # WHEN
    mappedObservable.subscribe((value: string) => receivedValues.add(value))
    
    # THEN
    check receivedValues == @["5"]
  
  test """
    GIVEN a cold int observable and a mapped observable created from it
    WHEN subscribing to both
    THEN both observables should only emit their respective values once
  """:
    # GIVEN
    var receivedValues1: seq[int] = @[]
    var receivedValues2: seq[int] = @[]
    let observable = newObservable[int](5)
    let mappedObservable = observable.map((value: int) => value * 2)
    
    # WHEN
    observable.subscribe((value: int) => receivedValues1.add(value))
    mappedObservable.subscribe((value: int) => receivedValues2.add(value))
    
    # THEN
    check receivedValues1 == @[5]
    check receivedValues2 == @[10]

  test """
    GIVEN a cold int observable
    WHEN using the map operator multiple times
    THEN it should generate a new cold observable that emits the mapped value on subscribe
  """:
    # GIVEN
    var receivedValues: seq[string] = @[]
    let observable = newObservable[int](5)
    let mappedObservable = observable
      .map((value: int) => value * 2)
      .map((value: int) => $value)
    
    # WHEN
    mappedObservable.subscribe((value: string) => receivedValues.add(value))
    
    # THEN
    check receivedValues == @["10"]
  