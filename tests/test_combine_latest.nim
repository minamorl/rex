import rex
import std/[unittest, sugar]

suite "Operators - combineLatest":
  test """
    GIVEN two cold int observables of a single initial value
    WHEN using the combineLatest operator
    THEN it should generate a new cold observable that emits the last initial value of both of them
  """:
    # GIVEN
    var receivedValues: seq[(int, string)] = @[]
    let obsValue1 = 5
    let obsValue2 = "3"
    let observable1 = newObservable[int](obsValue1)
    let observable2 = newObservable[string](obsValue2)
    let combinedObservable: Observable[(int, string)] = combineLatest(observable1, observable2)
    
    # WHEN
    combinedObservable.subscribe((value: (int, string)) => receivedValues.add(value))
    
    # THEN
    let expected: seq[(int, string)] = @[
      (obsValue1, obsValue2)
    ]
    check receivedValues == expected

  test """
    GIVEN two cold int observables that contain multiple values
    WHEN using the combineLatest operator
    THEN it should generate a new cold observable that emits the last initial value of both of them
  """:
    # GIVEN
    var receivedValues: seq[(int, string)] = @[]
    let obsValue1 = 5
    let obsValue2 = "3"
    let observable1 = newObservable[int](
      proc(obs: Observer[int]) {.async.} =
        await obs.next(5)
        await obs.next(4)
        await obs.next(3)
    )
    let observable2 = newObservable[string](
      proc(obs: Observer[string]) {.async.} =
        await obs.next("Bla")
        await obs.next("Blubb")
        await obs.next("Blubba")
    )
    let combinedObservable: Observable[(int, string)] = combineLatest(observable1, observable2)
    
    # WHEN
    combinedObservable
      .subscribe((value: (int, string)) => receivedValues.add(value))
      .doWork()
    
    # THEN
    let expected: seq[(int, string)] = @[
      (3, "Bla"),
      (3, "Blubb"),
      (3, "Blubba")
    ]
    check receivedValues == expected

  test """
    GIVEN a cold int observables that contain multiple values and a string subject
    WHEN using the combineLatest operator
    THEN it should generate a new hot observable that does not emit initially but emits the last value of the cold observable with whatever the subject emits
  """:
    # TODO: Fix this test, this should work as expected
    # GIVEN
    var receivedValues: seq[(int, string)] = @[]
    let obsValue1 = 5
    let obsValue2 = "3"
    let observable1 = newObservable[int](
      proc(obs: Observer[int]) {.async.} =
        await obs.next(5)
        await obs.next(4)
        await obs.next(3)
    )
    let observable2 = newSubject[string]()
    let combinedObservable: Observable[(int, string)] = combineLatest(observable1, observable2)
    
    # WHEN
    combinedObservable
      .subscribe((value: (int, string)) => receivedValues.add(value))
      .doWork()
    observable2.nextBlock("Bla")
    observable2.nextBlock("Blubb")
    observable2.nextBlock("Blubba")
    
    # THEN
    let expected: seq[(int, string)] = @[
      (3, "Bla"),
      (3, "Blubb"),
      (3, "Blubba")
    ]
    check receivedValues == expected
