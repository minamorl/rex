import rex
import std/[unittest, sugar, os, times]

suite "Operators - throttle":
  test """
    GIVEN a cold int observable that emits a lot of values
    WHEN using the throttle operator to block 50ms
    THEN it should only emit a value again after 50ms have passed
  """:
    # Given
    let observable = newObservable[int](
      proc(obs: Observer[int]) =
        obs.next(1)
        obs.next(2)
        obs.next(3)
        sleep(10)
        obs.next(4)
        sleep(10)
        obs.next(5)
    )
      .throttle(proc(value: int): Duration = initDuration(milliseconds = 10))
    
    # When
    var receivedValues: seq[int] = @[]
    observable.subscribe((value: int) => receivedValues.add(value))
    
    # Then
    assert receivedValues == @[1, 4, 5]

  test """
    GIVEN a subject that emits a lot of values
    WHEN using the throttle operator to block 50ms
    THEN it should only emit a value again after 50ms have passed
  """:
    # Given
    let subject = newSubject[int]()
    var receivedValues: seq[int] = @[]
    let throttleObservable = subject
      .throttle((value: int) => initDuration(milliseconds = 10))
    
    # When
    throttleObservable.subscribe((value: int) => receivedValues.add(value))
    
    subject.next(1)
    subject.next(2)
    sleep(10)
    subject.next(3)
    sleep(10)
    subject.next(4)
    
    # Then
    assert receivedValues == @[1, 3, 4]

  test """
    GIVEN a map-observable based on a cold int observable that emits a lot of values
    WHEN using the throttle operator to block 50ms
    THEN it should only emit a value again after 50ms have passed
  """:
    # Given
    let observable = newObservable[int](
      proc(obs: Observer[int]) =
        obs.next(1)
        obs.next(2)
        obs.next(3)
        sleep(10)
        obs.next(4)
        sleep(10)
        obs.next(5)
    )
      .throttle((value: int) => initDuration(milliseconds = 10))
      .map((value: int) => value*2)
    
    # When
    var receivedValues: seq[int] = @[]
    observable.subscribe((value: int) => receivedValues.add(value))
    
    # Then
    assert receivedValues == @[2, 8, 10]
