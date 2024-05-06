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
      proc(obs: Observer[int]) {.async.} =
        await obs.next(1)
        await obs.next(2)
        await obs.next(3)
        await sleepAsync(10)
        await obs.next(4)
        await sleepAsync(10)
        await obs.next(5)
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
    
    subject.nextBlock(1)
    subject.nextBlock(2)
    sleep(10)
    subject.nextBlock(3)
    sleep(10)
    subject.nextBlock(4)
    
    # Then
    assert receivedValues == @[1, 3, 4]

  test """
    GIVEN a map-observable based on a cold int observable that emits a lot of values
    WHEN using the throttle operator to block 50ms
    THEN it should only emit a value again after 50ms have passed
  """:
    # Given
    let observable = newObservable[int](
      proc(obs: Observer[int]) {.async.} =
        await obs.next(1)
        await obs.next(2)
        await obs.next(3)
        await sleepAsync(10)
        await obs.next(4)
        await sleepAsync(10)
        await obs.next(5)
    )
      .throttle((value: int) => initDuration(milliseconds = 10))
      .map((value: int) => value*2)
    
    # When
    var receivedValues: seq[int] = @[]
    observable.subscribe((value: int) => receivedValues.add(value))
    
    # Then
    assert receivedValues == @[2, 8, 10]
