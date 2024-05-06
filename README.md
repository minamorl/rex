# Rex

Rex is a reactive extensions library for Nim, providing a way to create and manipulate observable streams of data. It follows the Observable pattern and offers a range of operators to transform, filter, and combine observables.

## Features

- Create observable objects with a generic type parameter
- Subscribe to an observable to receive emitted values
- Emit values to all subscribed observers
- Operators to transform, filter, and combine observables, including:
  - `map`: Transform the values emitted by an observable
  - `filter`: Filter the values emitted by an observable based on a predicate
  - `take`: Emit only the first n values from an observable
  - `tap`: Perform side effects for each value emitted by an observable
  - `combineLatest`: Combine the latest values emitted by multiple observables
  - `throttle`: Emit values from an observable, but throttled by a specified duration
- Support for both cold and hot observables
- Ability to create custom operators

## Usage

### Creating an Observable

To create an observable, use the `newObservable` proc and provide a value or a procedure that emits values:

```nim
let coldObservable = newObservable[int](5)

let coldObservable2 = newObservable[int](
  proc(observer: Observer[int]) {.async.} =
    await observer.next(1)
    await observer.next(2)
    await observer.next(3)
)
```

### Subscribing to an Observable

To subscribe to an observable and receive emitted values, use the subscribe proc:

```nim
let subscription = myObservable.subscribe(
  proc(value: int) =
    echo "Received value: ", value
)
```

### Using Operators

Rex provides a range of operators to transform, filter, and combine observables. Here are a few examples:

```nim
let mappedObservable = myObservable.map(proc(value: int): int = value * 2)

let filteredObservable = myObservable.filter(proc(value: int): bool = value mod 2 == 0)

let combinedObservable = combineLatest(observable1, observable2)

let throttledObservable = myObservable.throttle(proc(value: int): Duration = initDuration(milliseconds = 50))
```

### Creating a Subject

Subjects are a special type of observable that allow you to emit values to multiple subscribers. You can create a subject using the newSubject proc:

```nim
let subject = newSubject[int]()
subject.subscribe(proc(value: int) = echo "Received value: ", value)
subject.nextBlock(1)
subject.nextBlock(2)
```

## Example

```nim
import rex

let observable = newObservable[int](
  proc(observer: Observer[int]) {.async.} =
    await observer.next(1)
    await observer.next(2)
    await observer.next(3)
)

let mappedObservable = observable.map(proc(value: int): int = value * 2)

mappedObservable.subscribe(proc(value: int) = echo "Received value: ", value)
```

Output:
```
Received value: 2
Received value: 4
Received value: 6
```

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.

## License
MIT
