import rex
import std/sugar

### TESTCODE
let intObserver = newObserver[int](
  proc(value: int) = echo("Int Observer: ", value),
  proc(error: CatchableError) = echo("Int Observer error: ", error),
  proc() = echo("Int Observer complete")
)

let strObserver = newObserver[string](
  proc(value: string) = echo("String Observer: ", value),
  proc(error: CatchableError) = echo("String Observer error: ", error),
  proc() = echo("String Observer complete")
)

# let obs = newObservable[int](5)
# let x = obs.map(proc(x: int): string = $x)

# x.subscribe(strObserver)
# obs.subscribe(intObserver)
# complete(obs)

echo "=================="
let subj = newSubject[int]()
let obs2 = subj.asObservable()

import std/strutils 

obs2
  .map((value: int) => $value)
  .map((value: string) => parseInt(value))
  .filter((value: int) => value mod 2 == 0)
  .filter((value: int) => value > 0)
  .subscribe(intObserver)

# obs2.forward(4)

obs2.subscribe(intObserver)

echo subj.repr
subj.next(1,2,3)
subj.complete()