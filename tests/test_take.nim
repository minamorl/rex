# import rex
# import std/[unittest, sugar, importutils]

# suite "Operators - tap":
#   test """
#     GIVEN a cold int observable emitting 4 values
#     WHEN using the take operator with a count of 2
#     THEN it should emit only 2 values and not have any subscribers
#   """:
#     privateAccess(Observable)
#     # GIVEN
#     var receivedValues: seq[int] = @[]
#     let parentObservable = newObservable[int](
#       proc(observer: Observer[int]) =
#         for i in 1..4:
#           observer.next(i)
#     )
#     let observable = parentObservable.take(2)
    
#     # WHEN
#     observable
#       .subscribe((value: int) => receivedValues.add(value))
    
#     # THEN
#     check receivedValues == @[1, 2]
#     check observable.observers.len == 0
#     check parentObservable.observers.len == 0

#   test """
#     GIVEN a subject int emitting 4 values
#     WHEN using the take operator with a count of 2
#     THEN it should emit only 2 values and not have any subscribers
#   """:
#     privateAccess(Observable)
#     # GIVEN
#     var receivedValues: seq[int] = @[]
#     let parentObservable = newSubject[int]()
#     let observable = parentObservable.take(2)
    
#     # WHEN
#     observable
#       .subscribe((value: int) => receivedValues.add(value))
#     parentObservable.next(1,2,3,4)
#     # THEN
#     check receivedValues == @[1, 2]
#     check observable.observers.len == 0
#     check parentObservable.observers.len == 0

