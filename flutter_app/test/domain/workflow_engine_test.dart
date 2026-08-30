import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_prep_board/domain/kitchen_models.dart';
import 'package:kitchen_prep_board/domain/scheduling_engine.dart';
import 'package:kitchen_prep_board/domain/timer_logic.dart';
import 'package:kitchen_prep_board/domain/workflow_engine.dart';

void main() {
  test('Need never drops below zero and verification resets', () {
    final item = StationItem(id: 'a', name: 'Onion', have: 8, par: 5)
      ..verified = true;
    expect(item.need, 0);
    expect(item.surplus, 3);
    item.setHave(2);
    expect(item.need, 3);
    expect(item.verified, isFalse);
  });

  test('Timer expiry never marks task done', () {
    final task = KitchenTask(
      id: 't',
      name: 'Chop',
      durationSeconds: 60,
      status: TaskStatus.ready,
    );
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

  test('Duplicate resets live values and preserves dependency structure', () {
    final engine = KitchenWorkflowEngine();
    final source = engine.createDraft(
      title: 'Prep',
      mode: BoardMode.station,
      nowEpochMs: 100,
      taskNames: const ['Dice', 'Cook'],
      stationItemNames: const ['Onion'],
    );
    source.tasks[1].dependencyIds.add(source.tasks[0].id);
    source.tasks[0].status = TaskStatus.done;
    source.stationItems.first
      ..par = 10
      ..have = 3
      ..prepared = 7
      ..verified = true;

    final copy = engine.duplicateBoard(source, 500);
    expect(copy.tasks.first.status, TaskStatus.waiting);
    expect(copy.tasks[1].dependencyIds, [copy.tasks[0].id]);
    expect(copy.stationItems.first.par, 10);
    expect(copy.stationItems.first.have, 0);
    expect(copy.stationItems.first.prepared, 0);
    expect(copy.stationItems.first.verified, isFalse);
  });

  test('Scheduler respects dependencies and resource capacity', () {
    final board = KitchenBoard(
      id: 'b',
      title: 'Prep',
      mode: BoardMode.home,
      createdAtEpochMs: 0,
      updatedAtEpochMs: 0,
      resources: [KitchenResource(id: 'knife', name: 'Knife')],
      tasks: [
        KitchenTask(
          id: 'a',
          name: 'A',
          durationSeconds: 60,
          resourceRequirements: [
            TaskResourceRequirement(resourceId: 'knife'),
          ],
        ),
        KitchenTask(
          id: 'b',
          name: 'B',
          durationSeconds: 60,
          resourceRequirements: [
            TaskResourceRequirement(resourceId: 'knife'),
          ],
        ),
        KitchenTask(
          id: 'c',
          name: 'C',
          durationSeconds: 30,
          dependencyIds: ['a'],
        ),
      ],
    );
    final result = SchedulingEngine.schedule(board, 1000);
    final byId = {for (final item in result.tasks) item.taskId: item};
    expect(byId['b']!.startAtEpochMs, greaterThanOrEqualTo(byId['a']!.endAtEpochMs));
    expect(byId['c']!.startAtEpochMs, greaterThanOrEqualTo(byId['a']!.endAtEpochMs));
  });

  test('Dependency cycles are rejected', () {
    final board = KitchenBoard(
      id: 'b',
      title: 'Prep',
      mode: BoardMode.home,
      createdAtEpochMs: 0,
      updatedAtEpochMs: 0,
      tasks: [
        KitchenTask(id: 'a', name: 'A', dependencyIds: ['b']),
        KitchenTask(id: 'b', name: 'B', dependencyIds: ['a']),
      ],
    );
    expect(
      () => SchedulingEngine.schedule(board, 0),
      throwsA(isA<DependencyCycleException>()),
    );
  });

  test('Unavailable resources never produce unsafe schedule', () {
    final board = KitchenBoard(
      id: 'b',
      title: 'Prep',
      mode: BoardMode.home,
      createdAtEpochMs: 0,
      updatedAtEpochMs: 0,
      resources: [
        KitchenResource(id: 'oven', name: 'Oven', available: false),
      ],
      tasks: [
        KitchenTask(
          id: 'a',
          name: 'A',
          durationSeconds: 60,
          resourceRequirements: [
            TaskResourceRequirement(resourceId: 'oven'),
          ],
        ),
      ],
    );
    expect(
      () => SchedulingEngine.schedule(board, 0),
      throwsA(isA<ResourceUnavailableException>()),
    );
  });

  test('Snapshot round-trips preferences and advanced task fields', () {
    final engine = KitchenWorkflowEngine();
    final board = engine.createDraft(
      title: 'Prep',
      mode: BoardMode.home,
      nowEpochMs: 100,
      taskNames: const ['Slice', 'Cook'],
    );
    board.tasks[1]
      ..dependencyIds.add(board.tasks[0].id)
      ..priority = TaskPriority.high;
    engine.snapshot
      ..languageOverride = 'fr'
      ..regionOverride = 'CA'
      ..keepScreenAwake = true;
    final decoded = KitchenSnapshot.decode(engine.snapshot.encode());
    expect(decoded.languageOverride, 'fr');
    expect(decoded.regionOverride, 'CA');
    expect(decoded.keepScreenAwake, isTrue);
    expect(decoded.boards.single.tasks[1].priority, TaskPriority.high);
    expect(decoded.boards.single.tasks[1].dependencyIds.length, 1);
  });
}
