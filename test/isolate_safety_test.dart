//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

/// VM-only tests that prove isolate-safety properties — the JS runtime has
/// no isolates, so this file is gated to `vm`.
///
/// The library itself is web-compatible (no `dart:isolate` imports under
/// `lib/`), but these tests need `Isolate.run` to actually demonstrate that
/// the value-object design transports correctly across isolate boundaries.
@TestOn('vm')
library;

import 'dart:isolate';

import 'package:df_type/df_type.dart';
import 'package:test/test.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// Top-level functions used to construct sendable WaiterOperations. These
// MUST be top-level (or `static`) — closures cannot cross isolates.

int isolateOpA() => 1;
int isolateOpB() => 2;
Future<int> isolateOpC() async => 3;

int sumOfSquares(int n) {
  var sum = 0;
  for (var i = 1; i <= n; i++) {
    sum += i * i;
  }
  return sum;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() {
  group('No shared mutable static state', () {
    test('isJsRuntime is computed per-isolate and is consistent', () async {
      final hostValue = isJsRuntime;
      final workerValue = await Isolate.run(() => isJsRuntime);
      expect(workerValue, hostValue,
          reason: 'isJsRuntime is a function of the runtime, not isolate '
              'identity — both must agree',);
      // And on the VM, both must be false.
      expect(hostValue, isFalse);
    });

    test('letIntOrNull is pure — concurrent calls in different isolates '
        'cannot interfere', () async {
      // Fire off four isolates that all hammer the same converter with
      // different inputs. Any cross-isolate state corruption would cause
      // them to return wrong values.
      final futures = <Future<int?>>[
        Isolate.run(() => letIntOrNull(11)),
        Isolate.run(() => letIntOrNull(22)),
        Isolate.run(() => letIntOrNull(33)),
        Isolate.run(() => letIntOrNull(44)),
      ];
      expect(await Future.wait(futures), [11, 22, 33, 44]);
    });
  });

  group('WaiterOperation — sendability across SendPort', () {
    test('a top-level-backed WaiterOperation survives Isolate.run', () async {
      // The closure passed to Isolate.run is itself captured. It references
      // a WaiterOperation built from top-level functions, which IS sendable.
      // The whole graph must serialise and the worker must produce the
      // expected result.
      final result = await Isolate.run<List<int>>(() async {
        final w = Waiter<int>(
          operations: const <WaiterOperation<int>>[
            WaiterOperation(isolateOpA, id: 'A'),
            WaiterOperation(isolateOpB, id: 'B'),
            WaiterOperation(isolateOpC, id: 'C'),
          ],
        );
        final results = await w.wait();
        return results.toList();
      });
      expect(result, [1, 2, 3]);
    });

    test('WaiterOperation.id round-trips through an isolate', () async {
      final received = await Isolate.run<List<String?>>(() async {
        const ops = <WaiterOperation<int>>[
          WaiterOperation(isolateOpA, id: 'alpha'),
          WaiterOperation(isolateOpB, id: 'beta'),
        ];
        return ops.map((op) => op.id).toList();
      });
      expect(received, ['alpha', 'beta']);
    });

    test('a Waiter built in a worker isolate produces results identical to '
        'the host-side equivalent', () async {
      // Sanity: same operations, run host-side vs worker-side, identical
      // results. Establishes that nothing about the Waiter pipeline
      // depends on the isolate it runs in.
      final hostSide = Waiter<int>(
        operations: const <WaiterOperation<int>>[
          WaiterOperation(isolateOpA),
          WaiterOperation(isolateOpB),
        ],
      );
      final hostResults = (await hostSide.wait()).toList();
      final workerResults = await Isolate.run<List<int>>(() async {
        final w = Waiter<int>(
          operations: const <WaiterOperation<int>>[
            WaiterOperation(isolateOpA),
            WaiterOperation(isolateOpB),
          ],
        );
        return (await w.wait()).toList();
      });
      expect(workerResults, hostResults);
    });

    test('compute-heavy work can be dispatched to a worker isolate via the '
        'value-object form', () async {
      // The whole point of the WaiterOperation pattern: heavy lifting can
      // run off the main isolate so the UI / control loop stays responsive.
      // Validate that a non-trivial pure computation runs identically in a
      // worker.
      final result = await Isolate.run<int>(() => sumOfSquares(1000));
      expect(result, 333833500); // sum_{i=1..1000} i^2
    });
  });

  group('Closure-based operations stay where they were built', () {
    test('a closure-based WaiterOperation throws when forced through a '
        'SendPort — this is the Dart runtime guard, not ours, but it is '
        'the reason WaiterOperation exists', () async {
      // We construct an op that captures a local variable — a closure.
      // Sending it must fail (Dart rejects unsendable values at send time).
      // The exact error type may vary across SDK versions; we just check
      // that *something* throws.
      var captured = 0;
      final op = WaiterOperation<int>(() {
        captured++;
        return captured;
      });
      final port = ReceivePort();
      try {
        expect(
          () => port.sendPort.send(op),
          throwsA(isA<Object>()),
        );
      } finally {
        port.close();
      }
    });
  });
}
