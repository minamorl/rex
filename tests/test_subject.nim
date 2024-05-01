import rex
import std/[unittest, sugar, importutils]

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

  test """
    GIVEN an int subject with one subscriber
    WHEN unsubscribing from it
    THEN it should not have any observers/subscribers
  """:
    # GIVEN
    let observable = newSubject[int]()
    let subscription = observable.subscribe((value: int) => echo value)
    privateAccess(Observable[int])
    check observable.observers.len == 1
    
    # WHEN
    subscription.unsubscribe()
    
    # THEN
    check observable.observers.len == 0
  
  # TODO tests for Subjects:
  # test: """
  #   GIVEN a cold observable with a subscriber with an error callback
  #   WHEN subscription callback throws an error
  #   THEN it should call the error callback
  # """
