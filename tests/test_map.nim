import rex
import std/[unittest, sugar]

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
    GIVEN a cold int observable created from observable callback
    WHEN using the map operator to double the value
    THEN it should generate a new cold observable that emits the mapped value on subscribe
  """:
    # GIVEN
    var receivedValues: seq[int] = @[]
    let obsValue1 = 5
    let obsValue2 = 3
    let obsValue3 = 4
    let observable = newObservable[int](
      proc(observer: Observer[int]) =
        observer.next(obsValue1)
        observer.next(obsValue2)
        observer.next(obsValue3) 
    )
    let mappedObservable = observable.map((value: int) => value * 2)
    
    # WHEN
    mappedObservable.subscribe((value: int) => receivedValues.add(value))
    
    # THEN
    check receivedValues == @[obsValue1*2, obsValue2*2, obsValue3*2]

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
  
  test """
    GIVEN a cold int observable
    WHEN using the map operator that throws an exception
    THEN it should call the error callback
  """:
    # GIVEN
    var receivedErrors: seq[ref CatchableError] = @[]
    let observable = newObservable[int](5)
    let mappedObservable = observable
      .map(proc(value: int): int = raise newException(ValueError, "Some error"))
    
    # WHEN
    mappedObservable.subscribe(
      next = proc(value: int) = discard,
      error = (error: ref CatchableError) => receivedErrors.add(error)
    )
    
    # THEN
    check receivedErrors.len == 1
    check receivedErrors[0].msg == "Some error"

  test """
    GIVEN a cold int observable that throws an exception
    WHEN using the map operator
    THEN it should call the error callback
  """:
    # GIVEN
    var receivedErrors: seq[ref CatchableError] = @[]
    let observable = newObservable[int](
      proc(observer: Observer[int]) =
        observer.next(4)
        raise newException(ValueError, "Some error")
    )
    let mappedObservable = observable
      .map(proc(value: int): int = value*2)
    
    # WHEN
    mappedObservable.subscribe(
      next = proc(value: int) = discard,
      error = (error: ref CatchableError) => receivedErrors.add(error)
    )
    
    # THEN
    check receivedErrors.len == 1
    check receivedErrors[0].msg == "Some error"