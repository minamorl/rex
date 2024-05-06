import rex
import std/[unittest, sugar]

suite "Operators - tap":
  test """
    GIVEN a cold int observable
    WHEN using the tap operator to push values into a seq
    THEN it should emit the exact same values in tap and subscribe block
  """:
    # GIVEN
    var tapValues: seq[int] = @[]
    var receivedValues: seq[int] = @[]
    let obsValue = 5
    
    # WHEN
    newObservable[int](obsValue)
      .tap((value: int) => tapValues.add(value))
      .subscribe((value: int) => receivedValues.add(value))
      .doWork()
    
    # THEN
    check receivedValues == @[obsValue]
    check tapValues == @[obsValue]

  test """
    GIVEN a cold int observable created via emission proc
    WHEN using the tap operator to push values into a seq
    THEN it should emit the exact same values in tap and subscribe block
  """:
    # GIVEN
    var tapValues: seq[int] = @[]
    var receivedValues: seq[int] = @[]
    let obsValue = 5
    let observable = newObservable[int](
      proc(observer: Observer[int]) {.async.} =
        await observer.next(5)
        await observer.next(4)
        await observer.next(3)
    )
    
    # WHEN
    observable
      .tap((value: int) => tapValues.add(value))
      .subscribe((value: int) => receivedValues.add(value))
      .doWork()
    
    # THEN
    check receivedValues == @[5,4,3]
    check tapValues == @[5,4,3]

  test """
    GIVEN a cold int observable created via map operator
    WHEN tapping the observable
    THEN it should emit the values in tap and map as normal
  """:
    # GIVEN
    var beforeValues: seq[int] = @[]
    var receivedValues: seq[int] = @[]
    var afterValues: seq[int] = @[]
    
    let observable = newObservable[int](5)
    let mappedObservable = observable.map((value: int) => value * 2)
    
    # WHEN
    newObservable(5)
      .tap((value: int) => beforeValues.add(value))
      .map((value: int) => value * 2)
      .tap((value: int) => afterValues.add(value))
      .subscribe((value: int) => receivedValues.add(value))
      .doWork()
    
    # THEN
    check beforeValues == @[5]
    check afterValues == @[10]
    check receivedValues == @[10]