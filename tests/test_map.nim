import rex
import std/[times, os, unittest, sugar]

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
  