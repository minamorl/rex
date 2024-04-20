# test_rex.nim

import unittest
import rex

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
