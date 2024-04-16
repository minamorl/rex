# Rex

Rex is a simple implementation of the Observable pattern in Nim. It provides a way to create observable objects that can notify subscribers when values are emitted.

## Features

- Create observable objects with a generic type parameter
- Subscribe to an observable to receive emitted values
- Emit values to all subscribed observers
- Enable an observable to start emitting values

## Usage

### Creating an Observable

To create an observable, use the create proc and provide a process that emits values:

```nim
let myObservable = create[int](proc(observable: Observable[int]) =
    observable.next(1)
    observable.next(2)
    observable.next(3)
)
```

### Subscribing to an Observable

To subscribe to an observable and receive emitted values, use the subscribe proc:

```nim
myObservable.subscribe(proc(value: int) =
    echo "Received value: ", value
)
```

### Enabling an Observable

To start emitting values from an observable, use the enable proc:

```nim
myObservable.enable()
```

## Example

Here's a complete example that demonstrates how to use the rex library:

```nim
import rex

let myObservable = create[string](proc(observable: Observable[string]) =
    observable.next("Hello")
    observable.next("World")
)


myObservable.subscribe(proc(value: string) =
    echo "Received value: ", value
)

myObservable.enable()
```

Output:
```
Received value: Hello
Received value: World

```
## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.

## License
MIT
