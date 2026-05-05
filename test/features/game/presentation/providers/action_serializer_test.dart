import 'dart:async';

import 'package:dart_lodge/features/game/presentation/providers/action_serializer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runs queued actions in submission order', () async {
    final serializer = ActionSerializer();
    final order = <int>[];

    final futures = [
      serializer.run(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        order.add(1);
      }),
      serializer.run(() async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        order.add(2);
      }),
      serializer.run(() async {
        order.add(3);
      }),
    ];

    await Future.wait(futures);

    expect(order, [1, 2, 3]);
  });

  test('actions never interleave', () async {
    final serializer = ActionSerializer();
    var concurrent = 0;
    var maxConcurrent = 0;

    Future<void> work() => serializer.run(() async {
          concurrent++;
          if (concurrent > maxConcurrent) maxConcurrent = concurrent;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          concurrent--;
        });

    await Future.wait([work(), work(), work(), work(), work()]);

    expect(maxConcurrent, 1);
  });

  test('error in one action does not poison the queue', () async {
    final serializer = ActionSerializer();
    final order = <int>[];

    final failing = serializer.run<void>(() async {
      throw StateError('boom');
    });
    final after = serializer.run(() async {
      order.add(2);
    });

    await expectLater(failing, throwsA(isA<StateError>()));
    await after;

    expect(order, [2]);
  });

  test('returns the action result', () async {
    final serializer = ActionSerializer();
    final result = await serializer.run(() async => 42);
    expect(result, 42);
  });

  test('queued action waits for prior in-flight action', () async {
    final serializer = ActionSerializer();
    final firstStarted = Completer<void>();
    final firstCanComplete = Completer<void>();
    final secondStarted = Completer<void>();

    final first = serializer.run(() async {
      firstStarted.complete();
      await firstCanComplete.future;
    });
    final second = serializer.run(() async {
      secondStarted.complete();
    });

    await firstStarted.future;
    expect(secondStarted.isCompleted, isFalse,
        reason: 'second action must not start until first completes');

    firstCanComplete.complete();
    await Future.wait([first, second]);
    expect(secondStarted.isCompleted, isTrue);
  });
}
