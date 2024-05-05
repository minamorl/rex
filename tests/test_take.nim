import rex
import std/[unittest, sugar, importutils]

suite "Operators - tap":
  test """
    GIVEN a cold int observable emitting 4 values
    WHEN using the take operator with a count of 2
    THEN it should emit only 2 values and not have any subscribers
  """:
    privateAccess(Observable)
    # GIVEN
    var receivedValues: seq[int] = @[]
    let parentObservable = newObservable[int](
      proc(observer: Observer[int]) {.async.} =
        for i in 1..4:
          await observer.next(i)
    )
    let observable = parentObservable.take(2)
    
    # WHEN
    observable
      .subscribe((value: int) => receivedValues.add(value))
      .doWork()
    
    # THEN
    check receivedValues == @[1, 2]
    check observable.observers.len == 0
    check parentObservable.observers.len == 0

  test """
    GIVEN a subject int emitting 4 values
    WHEN using the take operator with a count of 2
    THEN it should emit only 2 values and not have any subscribers
  """:
    privateAccess(Observable)
    # GIVEN
    var receivedValues: seq[int] = @[]
    let subject = newSubject[int]()
    let observable = subject.take(2)

    # WHEN
    observable
      .subscribe((value: int) => receivedValues.add(value))

    subject.nextBlock(1)
    subject.nextBlock(2)
    subject.nextBlock(3)
    
    # THEN
    check receivedValues == @[1, 2]
    check observable.observers.len == 0
    check subject.observers.len == 0

  test """
    GIVEN a subject int with a take operator with a count of 2
    WHEN subscribing with a complete callback
    THEN it should run the complete callback only once after emitting 2 values and no more after emitting further values
  """:
    privateAccess(Observable)
    # GIVEN
    var receivedValues: seq[int] = @[]
    let subject = newSubject[int]()
    let observable = subject.take(2)
    var completedCalls = 0

    # WHEN
    observable
      .subscribe(
        next = (value: int) => receivedValues.add(value),
        complete = proc()  {.closure.} = completedCalls.inc
      )

    subject.nextBlock(1)
    subject.nextBlock(2)
    subject.nextBlock(2)
    
    # THEN
    check receivedValues == @[1, 2]
    check completedCalls == 1
    check observable.observers.len == 0
    check subject.observers.len == 0

  test """
    GIVEN a subject int with a take operator with a count of 2 that has already received 2 values
    WHEN subscribing again with a complete callback
    THEN it should run the complete callback only once after emitting 2 values and no more after emitting further values
  """:
    privateAccess(Observable)
    # GIVEN
    var receivedValues: seq[int] = @[]
    let subject = newSubject[int]()
    let observable = subject.take(2)
    observable.subscribe(proc(value: int) = discard value)
    subject.nextBlock(0, 0)
    var completedCalls = 0

    # WHEN
    observable
      .subscribe(
        next = (value: int) => receivedValues.add(value),
        complete = proc()  {.closure.} = completedCalls.inc
      )

    subject.nextBlock(1)
    subject.nextBlock(2)
    
    # THEN
    check receivedValues == @[1, 2]
    check completedCalls == 1
    check observable.observers.len == 0
    check subject.observers.len == 0

