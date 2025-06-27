## Summary

A versatile package that simplifies type conversions, inspections, nested data access, sync/async operations and more.

## Quickstart

```dart
enum Alphabet { A, B, C }

enum Status { pending, active, done }

void main() async {
  // --- Type Checking ---
  print('\n*** Type Checking Utilities ***');
  print('isNullable<String?>: ${isNullable<String?>()}'); // true
  print('isSubtype<int, num>: ${isSubtype<int, num>()}'); // true
  print('typeEquality<int, int>: ${typeEquality<int, int>()}'); // true
  print('typeEquality<int, String>: ${typeEquality<int, String>()}'); // false

  // --- Type Conversion ---
  print('\n*** Type Conversion Utilities ***');
  print("letIntOrNull('55'): ${letIntOrNull('55')}"); // 55
  print(
    "letMapOrNull from JSON: ${letMapOrNull<String, dynamic>('{"a": 1}')}",
  ); // {a: 1}
  print(
    "letListOrNull from CSV: ${letListOrNull<int>('1, 2, 3')}",
  ); // [1, 2, 3]

  // --- Enum Helpers ---
  print('\n*** Enum Helpers ***');
  print(
    "Alphabet.values.valueOf('B'): ${Alphabet.values.valueOf('B')}",
  ); // Alphabet.B

  // --- Function and FutureOr Extensions ---
  print('\n*** Function and FutureOr Extensions ***');
  int Function(int) addOne = (i) => i + 1;
  print('Function.tryCall: ${addOne.tryCall<int, int>([5])}'); // 6

  FutureOr<int> futureOrValue = Future.value(10);
  print('futureOrValue.isFuture: ${futureOrValue.isFuture}'); // true
  print('futureOrValue.toFuture(): ${await futureOrValue.toFuture()}'); // 10

  // --- Asynchronous Helpers ---
  print('\n*** Asynchronous Helpers ***');
  // `consec` for handling a mix of sync/async values
  final result = await consec(Future.value(5), (val) => val * 2);
  print('consec result: $result'); // 10

  // `Waiter` for deferred, batched execution
  final taskQueue = Waiter<String>();
  taskQueue.add(() => 'Task 1');
  taskQueue.add(() async => 'Task 2');
  final waiterResults = await taskQueue.wait();
  print('Waiter results: $waiterResults'); // (Task 1, Task 2)
}
```
