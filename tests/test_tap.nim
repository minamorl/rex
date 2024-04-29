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
    
    # THEN
    check receivedValues == @[obsValue]
    check tapValues == @[obsValue]

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
    
    # THEN
    check beforeValues == @[5]
    check afterValues == @[10]
    check receivedValues == @[10]