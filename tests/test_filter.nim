import rex
import std/[unittest, sugar]

suite "Operators - filter":
  test """
    GIVEN a cold int observable of the value 4
    WHEN using the filter operator to ignore values that are divisible by 2
    THEN it should not emit any value
  """:
    # GIVEN
    var receivedValues: seq[int] = @[]
    let obsValue = 4
    let observable = newObservable[int](obsValue)
    let filteredObservable = observable.filter((value: int) => value mod 2 != 0)
    
    # WHEN
    filteredObservable.subscribe((value: int) => receivedValues.add(value))
    
    # THEN
    let expected: seq[int] = @[]
    check receivedValues == expected

  test """
    GIVEN a cold int observable of the value 3
    WHEN using the filter operator to ignore values that are divisible by 2
    THEN it should emit the value 3
  """:
    # GIVEN
    var receivedValues: seq[int] = @[]
    let observable = newObservable[int](3)
    let mappedObservable = observable.filter((value: int) => value mod 2 != 0)
    
    # WHEN
    mappedObservable.subscribe((value: int) => receivedValues.add(value))
    
    # THEN
    check receivedValues == @[3]
  
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
  