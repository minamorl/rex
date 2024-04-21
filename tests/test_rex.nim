# test_rex.nim

import rex
import std/[times, os, unittest]

suite "Observable":
  test "subscribe and next":
    var receivedValues: seq[int] = @[]

    proc observer(value: int) =
      receivedValues.add(value)

    let observable = create[int](
      proc(obs: Observable[int]) =
        obs.subscribe(observer)
        obs.next(1)
        obs.next(2)
        obs.next(3)
    )


    assert receivedValues == @[1, 2, 3]

  test "multiple observers":
    var observer1Values: seq[int] = @[]
    var observer2Values: seq[int] = @[]

    proc observer1(value: int) =
      observer1Values.add(value)

    proc observer2(value: int) =
      observer2Values.add(value)

    let observable = create[int](
      proc(obs: Observable[int]) =
        obs.subscribe(observer1)
        obs.subscribe(observer2)
        obs.next(10)
        obs.next(20)
    )


    assert observer1Values == @[10, 20]
    assert observer2Values == @[10, 20]

  test "late subscriber gets last value":
    var receivedValue: int = 0

    proc lateObserver(value: int) =
      receivedValue = value

    let observable = create[int](
      proc(obs: Observable[int]) =
        obs.next(1)
        obs.next(2)
        obs.next(3)
    )

    observable.subscribe(lateObserver)
    assert receivedValue == 3

suite "Operators - map": 
  test "map from int to int":
    # Given
    let observable = create[int](
      proc(obs: Observable[int]) =
        obs.next(1)
    )
    
    let mappedObservable = observable
      .map(proc(value: int): int = value * 2)
    
    # When
    var receivedValues: seq[int] = @[]
    mappedObservable.subscribe(proc(value: int) = receivedValues.add(value))
    
    observable.next(2)
    observable.next(3)
    
    # Then
    assert receivedValues == @[2, 4, 6]
    
  test "map from int to string":
    # Given
    let observable = create[int](
      proc(obs: Observable[int]) =
        obs.next(1)
    )
    
    let mappedObservable = observable
      .map(proc(value: int): string = $value)
    
    # When
    var receivedValues: seq[string] = @[]
    mappedObservable.subscribe(proc(value: string) = receivedValues.add(value))
    
    observable.next(2)
    observable.next(3)
    
    # Then
    assert receivedValues == @["1", "2", "3"]

suite "Operators - tap":
  test "tap":
    # Given
    let observable = create[int](
      proc(obs: Observable[int]) =
        obs.next(1)
    )
    
    var receivedValues: seq[int] = @[]
    let tappedObservable = observable
      .tap(proc(value: int) = receivedValues.add(value))
    
    # When
    observable.next(2)
    observable.next(3)
    
    # Then
    assert receivedValues == @[1, 2, 3]

suite "Operators - filter":
  test "filter":
    # Given
    let observable = create[int](
      proc(obs: Observable[int]) =
        obs.next(1)
        obs.next(2)
        obs.next(3)
    )
    
    let filteredObservable = observable
      .filter(proc(value: int): bool = value mod 2 == 0)
    
    # When
    var receivedValues: seq[int] = @[]
    filteredObservable.subscribe(proc(value: int) = receivedValues.add(value))
    
    observable.next(2)
    observable.next(3)
    
    # Then
    assert receivedValues == @[2]

suite "Operators - throttle":
  test "throttle":
    # Given
    let observable = create[int](
      proc(obs: Observable[int]) =
        obs.next(1)
    )
    
    let throttledObservable = observable
      .throttle(proc(value: int): Duration = initDuration(milliseconds = 100))

    # When
    var receivedValues: seq[int] = @[]
    throttledObservable.subscribe(proc(value: int) = receivedValues.add(value))
    
    observable.next(2)
    sleep(100)
    observable.next(3)
    
    # Then
    assert receivedValues == @[1, 3]

suite "Operators - combine 2 parameters":
  test "combine of same type":
    # Given
    let observable1 = create[int](
      proc(obs: Observable[int]) =
        obs.next(1)
    )
    
    let observable2 = create[int](
      proc(obs: Observable[int]) =
        obs.next(2)
    )
    
    let combinedObservable = combine(observable1, observable2)
    
    # When
    var receivedValues: seq[(int, int)] = @[]
    combinedObservable.subscribe(proc(value: (int, int)) = receivedValues.add(value))
    
    observable1.next(3)
    observable2.next(4)
    
    # Then
    assert receivedValues == @[(1, 2), (3, 2), (3, 4)]
  
  test "combine of different types":
    # Given
    let observable1 = create[int](
      proc(obs: Observable[int]) =
        obs.next(1)
    )
    
    let observable2 = create[string](
      proc(obs: Observable[string]) =
        obs.next("2")
    )
    
    let combinedObservable = combine(observable1, observable2)
    
    # When
    var receivedValues: seq[(int, string)] = @[]
    combinedObservable.subscribe(proc(value: (int, string)) = receivedValues.add(value))
    
    observable1.next(3)
    observable2.next("4")
    
    # Then
    assert receivedValues == @[(1, "2"), (3, "2"), (3, "4")]

suite "Operators - combine 3 parameters":
  test "combine of same type":
    # Given
    let observable1 = create[int](
      proc(obs: Observable[int]) =
        obs.next(1)
    )
    let observable2 = create[int](
      proc(obs: Observable[int]) =
        obs.next(2)
    )
    let observable3 = create[int](
      proc(obs: Observable[int]) =
        obs.next(3)
    )
    
    let combinedObservable = combine(observable1, observable2, observable3)
    
    # When
    var receivedValues: seq[(int, int, int)] = @[]
    combinedObservable.subscribe(proc(value: (int, int, int)) = receivedValues.add(value))
    
    observable1.next(3)
    observable2.next(4)
    observable3.next(5)
    
    # Then
    assert receivedValues == @[(1, 2, 3), (3, 2, 3), (3, 4, 3), (3, 4, 5)]
  
  test "combine of different types":
    # Given
    let observable1 = create[int](
      proc(obs: Observable[int]) =
        obs.next(1)
    )
    
    let observable2 = create[string](
      proc(obs: Observable[string]) =
        obs.next("2")
    )
    
    let observable3 = create[bool](
      proc(obs: Observable[bool]) =
        obs.next(true)
    )
    
    let combinedObservable = combine(observable1, observable2, observable3)
    
    # When
    var receivedValues: seq[(int, string, bool)] = @[]
    combinedObservable.subscribe(proc(value: (int, string, bool)) = receivedValues.add(value))
    
    observable1.next(3)
    observable2.next("4")
    observable3.next(false)
    
    # Then
    assert receivedValues == @[(1, "2", true), (3, "2", true), (3, "4", true), (3, "4", false)]

suite "Operators - combine 4 parameters":
  test "combine of same type":
    # Given
    let observable1 = create[int](
      proc(obs: Observable[int]) =
        obs.next(1)
    )
    let observable2 = create[int](
      proc(obs: Observable[int]) =
        obs.next(2)
    )
    let observable3 = create[int](
      proc(obs: Observable[int]) =
        obs.next(3)
    )
    let observable4 = create[int](
      proc(obs: Observable[int]) =
        obs.next(4)
    )
    
    let combinedObservable = combine(observable1, observable2, observable3, observable4)
    
    # When
    var receivedValues: seq[(int, int, int, int)] = @[]
    combinedObservable.subscribe(proc(value: (int, int, int, int)) = receivedValues.add(value))
    
    observable1.next(3)
    observable2.next(4)
    observable3.next(5)
    observable4.next(6)
    
    # Then
    assert receivedValues == @[(1, 2, 3, 4), (3, 2, 3, 4), (3, 4, 3, 4), (3, 4, 5, 4), (3, 4, 5, 6)]
