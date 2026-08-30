import 'dart:math' as math;

import 'kitchen_models.dart';

class DependencyCycleException implements Exception {
  const DependencyCycleException();
  @override
  String toString() => 'Dependency cycle prevents automatic scheduling';
}

class ResourceUnavailableException implements Exception {
  const ResourceUnavailableException(this.resourceId);
  final String resourceId;
  @override
  String toString() => 'Resource unavailable: $resourceId';
}

class ScheduledTask {
  const ScheduledTask({
    required this.taskId,
    required this.startAtEpochMs,
    required this.endAtEpochMs,
  });
  final String taskId;
  final int startAtEpochMs;
  final int endAtEpochMs;
}

class ScheduleResult {
  const ScheduleResult({
    required this.tasks,
    required this.earliestFinishEpochMs,
    required this.latenessMs,
  });
  final List<ScheduledTask> tasks;
  final int earliestFinishEpochMs;
  final int latenessMs;

  bool get isLate => latenessMs > 0;
}

class _Allocation {
  const _Allocation(this.start, this.end, this.units);
  final int start;
  final int end;
  final int units;
}

class SchedulingEngine {
  const SchedulingEngine._();

  static ScheduleResult schedule(KitchenBoard board, int nowEpochMs) {
    if (board.tasks.isEmpty) {
      return ScheduleResult(
        tasks: const <ScheduledTask>[],
        earliestFinishEpochMs: nowEpochMs,
        latenessMs: 0,
      );
    }
    final ordered = _topologicalOrder(board.tasks);
    final criticalMs = _criticalPathMs(ordered, board);
    final target = board.timingMode == TimingMode.readyAt
        ? board.targetReadyAtEpochMs
        : null;
    final desiredBase = target == null ? nowEpochMs : target - criticalMs;
    final base = math.max(nowEpochMs, desiredBase).toInt();

    final allocations = <String, List<_Allocation>>{};
    final result = <String, ScheduledTask>{};

    for (final task in ordered) {
      var depEnd = base;
      for (final dependencyId in task.dependencyIds) {
        final dependency = result[dependencyId];
        if (dependency != null) depEnd = math.max(depEnd, dependency.endAtEpochMs).toInt();
      }
      final durationMs = math.max(0, task.durationSeconds ?? 0).toInt() * 1000;
      var start = math.max(base, depEnd).toInt();
      start = _findResourceSlot(board, task, start, durationMs, allocations);
      final end = start + durationMs;
      result[task.id] = ScheduledTask(
        taskId: task.id,
        startAtEpochMs: start,
        endAtEpochMs: end,
      );
      for (final requirement in task.resourceRequirements) {
        allocations
            .putIfAbsent(requirement.resourceId, () => <_Allocation>[])
            .add(_Allocation(start, end, requirement.units));
      }
    }

    final values = <ScheduledTask>[for (final task in ordered) result[task.id]!];
    final finish = values.map((item) => item.endAtEpochMs).fold<int>(
      nowEpochMs,
      (value, end) => math.max(value, end).toInt(),
    );
    final lateness = target == null ? 0 : math.max(0, finish - target).toInt();
    return ScheduleResult(
      tasks: values,
      earliestFinishEpochMs: finish,
      latenessMs: lateness,
    );
  }

  static void applySuggestions(KitchenBoard board, int nowEpochMs) {
    final result = schedule(board, nowEpochMs);
    final byId = {for (final item in result.tasks) item.taskId: item};
    for (final task in board.tasks) {
      final scheduled = byId[task.id];
      task.suggestedStartEpochMs = scheduled?.startAtEpochMs;
      task.suggestedEndEpochMs = scheduled?.endAtEpochMs;
    }
  }

  static void recomputeAvailability(KitchenBoard board) {
    final terminal = <String, bool>{
      for (final task in board.tasks) task.id: task.isTerminal,
    };
    for (final task in board.tasks) {
      if (task.status == TaskStatus.running || task.isTerminal) continue;
      final unresolved = task.dependencyIds.any((id) => terminal[id] != true);
      task.status = unresolved ? TaskStatus.blocked : TaskStatus.ready;
    }
  }

  static List<KitchenTask> _topologicalOrder(List<KitchenTask> tasks) {
    final byId = {for (final task in tasks) task.id: task};
    final indegree = {for (final task in tasks) task.id: 0};
    final outgoing = <String, List<String>>{};
    for (final task in tasks) {
      for (final dependencyId in task.dependencyIds) {
        if (!byId.containsKey(dependencyId)) continue;
        if (dependencyId == task.id) throw const DependencyCycleException();
        indegree[task.id] = (indegree[task.id] ?? 0) + 1;
        outgoing.putIfAbsent(dependencyId, () => <String>[]).add(task.id);
      }
    }
    final ready = <KitchenTask>[
      for (final task in tasks)
        if ((indegree[task.id] ?? 0) == 0) task,
    ];
    ready.sort((a, b) => _taskOrder(tasks, a, b));
    final output = <KitchenTask>[];
    while (ready.isNotEmpty) {
      final task = ready.removeAt(0);
      output.add(task);
      for (final child in outgoing[task.id] ?? const <String>[]) {
        indegree[child] = (indegree[child] ?? 0) - 1;
        if (indegree[child] == 0) {
          ready.add(byId[child]!);
          ready.sort((a, b) => _taskOrder(tasks, a, b));
        }
      }
    }
    if (output.length != tasks.length) throw const DependencyCycleException();
    return output;
  }

  static int _taskOrder(List<KitchenTask> tasks, KitchenTask a, KitchenTask b) {
    final priority = b.priority.index.compareTo(a.priority.index);
    if (priority != 0) return priority;
    return tasks.indexOf(a).compareTo(tasks.indexOf(b));
  }

  static int _criticalPathMs(List<KitchenTask> order, KitchenBoard board) {
    final longest = <String, int>{};
    for (final task in order) {
      var before = 0;
      for (final dependencyId in task.dependencyIds) {
        before = math.max(before, longest[dependencyId] ?? 0).toInt();
      }
      longest[task.id] =
          before + math.max(0, task.durationSeconds ?? 0).toInt() * 1000;
    }
    return longest.values.fold<int>(
      0,
      (value, duration) => math.max(value, duration).toInt(),
    );
  }

  static int _findResourceSlot(
    KitchenBoard board,
    KitchenTask task,
    int earliest,
    int durationMs,
    Map<String, List<_Allocation>> allocations,
  ) {
    if (durationMs <= 0 || task.resourceRequirements.isEmpty) return earliest;
    for (final requirement in task.resourceRequirements) {
      final resource = board.resourceById(requirement.resourceId);
      if (resource == null || !resource.available || requirement.units > resource.capacity) {
        throw ResourceUnavailableException(requirement.resourceId);
      }
    }
    var candidate = earliest;
    for (var attempts = 0; attempts < 10000; attempts++) {
      int? nextCandidate;
      for (final requirement in task.resourceRequirements) {
        final resource = board.resourceById(requirement.resourceId)!;
        final overlaps = (allocations[requirement.resourceId] ?? const <_Allocation>[])
            .where((item) => item.start < candidate + durationMs && item.end > candidate)
            .toList();
        final used = overlaps.fold<int>(0, (sum, item) => sum + item.units);
        if (used + requirement.units > resource.capacity) {
          final next = overlaps.map((item) => item.end).fold<int?>(null, (value, end) {
            if (value == null || end < value) return end;
            return value;
          });
          nextCandidate =
              math.max(candidate + 1, next ?? candidate + durationMs).toInt();
          break;
        }
      }
      if (nextCandidate == null) return candidate;
      candidate = nextCandidate;
    }
    throw StateError('Unable to find a resource-capacity-safe schedule.');
  }
}
