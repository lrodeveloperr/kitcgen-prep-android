import 'package:kitchen_prep_board/domain/kitchen_models.dart';
import 'package:kitchen_prep_board/domain/timer_logic.dart';
import 'package:kitchen_prep_board/domain/workflow_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Need never drops below zero', () {
    final item = StationItem(id: 'a', name: 'Onion', have: 8, par: 5);
    expect(item.need, 0);
    expect(item.surplus, 3);
    item.setHave(2);
    expect(item.need, 3);
    expect(item.verified, isFalse);
  });

  test('Timer expiry never marks task done', () {
    final task = KitchenTask(id: 't', name: 'Chop', durationSeconds: 60);
    startTask(task, 1000);
    final reading = readTimer(task, 62000);
    expect(reading.expired, isTrue);
    expect(task.status, TaskStatus.running);
  });

  test('Active board protection prevents replacement', () {
    final engine = KitchenWorkflowEngine();
    final first = engine.createDraft(
      title: 'First',
      mode: BoardMode.home,
      nowEpochMs: 100,
      taskNames: const ['A'],
    );
    final second = engine.createDraft(
      title: 'Second',
      mode: BoardMode.home,
      nowEpochMs: 200,
      taskNames: const ['B'],
    );
    engine.startBoard(first, 300);
    expect(() => engine.startBoard(second, 400), throwsStateError);
    expect(engine.snapshot.activeBoardId, first.id);
  });

  test('Duplicate resets live execution state and Have values', () {
    final engine = KitchenWorkflowEngine();
    final source = engine.createDraft(
      title: 'Prep',
      mode: BoardMode.station,
      nowEpochMs: 100,
      taskNames: const ['Dice'],
      stationItemNames: const ['Onion'],
    );
    source.tasks.first.status = TaskStatus.done;
    source.stationItems.first
      ..par = 10
      ..have = 3
      ..prepared = 7
      ..verified = true;

    final copy = engine.duplicateBoard(source, 500);
    expect(copy.tasks.first.status, TaskStatus.waiting);
    expect(copy.stationItems.first.par, 10);
    expect(copy.stationItems.first.have, 0);
    expect(copy.stationItems.first.prepared, 0);
    expect(copy.stationItems.first.verified, isFalse);
  });

  test('Snapshot round-trips', () {
    final engine = KitchenWorkflowEngine();
    engine.createDraft(
      title: 'Prep',
      mode: BoardMode.home,
      nowEpochMs: 100,
      taskNames: const ['Slice'],
    );
    final decoded = KitchenSnapshot.decode(engine.snapshot.encode());
    expect(decoded.boards.single.title, 'Prep');
    expect(decoded.boards.single.tasks.single.name, 'Slice');
  });
}
