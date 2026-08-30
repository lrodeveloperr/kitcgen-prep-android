import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_prep_board/application/kitchen_controller.dart';
import 'package:kitchen_prep_board/data/kitchen_store.dart';
import 'package:kitchen_prep_board/domain/kitchen_models.dart';
import 'package:kitchen_prep_board/l10n/kitchen_strings.dart';
import 'package:kitchen_prep_board/services/timer_notifications.dart';

class _ControlledStore implements KitchenStore {
  final savedSources = <String>[];
  bool failNext = false;
  Completer<void>? _saveStarted;
  Completer<void>? _saveRelease;

  Future<void> blockNextSave() {
    _saveStarted = Completer<void>();
    _saveRelease = Completer<void>();
    return _saveStarted!.future;
  }

  void releaseSave() => _saveRelease?.complete();

  @override
  Future<void> clear() async {}

  @override
  Future<KitchenSnapshot> load() async => KitchenSnapshot.empty();

  @override
  Future<void> save(KitchenSnapshot snapshot) async {
    final started = _saveStarted;
    final release = _saveRelease;
    if (started != null && !started.isCompleted) started.complete();
    if (release != null) await release.future;
    _saveStarted = null;
    _saveRelease = null;
    if (failNext) {
      failNext = false;
      throw StateError('simulated save failure');
    }
    savedSources.add(snapshot.encode());
  }
}

class _FakeNotifications extends TimerNotifications {
  @override
  Future<void> cancel(KitchenTask task) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(KitchenTask task, KitchenStrings strings) async {}
}

void main() {
  final strings = KitchenStrings(const Locale('en'));

  test('failed saves restore the last durable snapshot', () async {
    final store = _ControlledStore();
    final controller = KitchenController(
      store: store,
      notifications: _FakeNotifications(),
    );
    final board = await controller.createDraft(
      title: 'Dinner',
      mode: BoardMode.home,
      taskNames: const ['Chop'],
    );

    store.failNext = true;
    await expectLater(
      controller.addTaskToDraft(board, 'Plate'),
      throwsA(isA<KitchenSaveException>()),
    );

    expect(
      controller.snapshot.boards.single.tasks.map((task) => task.name),
      ['Chop'],
    );
    expect(store.savedSources, hasLength(1));
  });

  test('an in-flight save owns an immutable snapshot', () async {
    final store = _ControlledStore();
    final controller = KitchenController(
      store: store,
      notifications: _FakeNotifications(),
    );
    final board = await controller.createDraft(
      title: 'Dinner',
      mode: BoardMode.home,
      taskNames: const ['Chop'],
    );

    final started = store.blockNextSave();
    final save = controller.addTaskToDraft(board, 'Plate');
    await started;
    board.tasks.last.name = 'Changed after save began';
    store.releaseSave();
    await save;

    final persisted = KitchenSnapshot.decode(store.savedSources.last);
    expect(persisted.boards.single.tasks.last.name, 'Plate');
  });

  test('undo waits for the finish save before restoring the engine', () async {
    final store = _ControlledStore();
    final controller = KitchenController(
      store: store,
      notifications: _FakeNotifications(),
    );
    final board = await controller.createDraft(
      title: 'Dinner',
      mode: BoardMode.home,
      taskNames: const ['Chop'],
    );
    await controller.startBoard(board);

    final started = store.blockNextSave();
    final finish = controller.finishBoard(board);
    await started;
    expect(controller.activeBoard, isNull);

    final undo = controller.undoLastFinish(strings);
    await Future<void>.delayed(Duration.zero);
    expect(controller.activeBoard, isNull);

    store.releaseSave();
    await finish;
    expect(await undo, isTrue);
    expect(controller.activeBoard, isNotNull);
  });

  test('addTime updates the board timestamp', () async {
    final store = _ControlledStore();
    final controller = KitchenController(
      store: store,
      notifications: _FakeNotifications(),
    );
    final board = await controller.createDraft(
      title: 'Dinner',
      mode: BoardMode.home,
      taskNames: const ['Bake'],
    );
    final task = board.tasks.single;
    await controller.updateTask(
      board,
      task,
      durationSeconds: 60,
      kind: TaskKind.singleTimer,
    );
    await controller.startBoard(board);
    await controller.startTask(board, task, strings);
    board.updatedAtEpochMs = 0;

    await controller.addTime(
      board,
      task,
      const Duration(minutes: 1),
      strings,
    );

    expect(board.updatedAtEpochMs, greaterThan(0));
  });

  test('startTask is a no-op while the board is paused', () async {
    final store = _ControlledStore();
    final controller = KitchenController(
      store: store,
      notifications: _FakeNotifications(),
    );
    final board = await controller.createDraft(
      title: 'Dinner',
      mode: BoardMode.home,
      taskNames: const ['Chop'],
    );
    final task = board.tasks.single;
    await controller.startBoard(board);
    await controller.pauseBoard(board);
    final savesBeforeStart = store.savedSources.length;

    await controller.startTask(board, task, strings);

    expect(task.status, isNot(TaskStatus.running));
    expect(store.savedSources, hasLength(savesBeforeStart));
  });
}
