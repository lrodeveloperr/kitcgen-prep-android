import 'kitchen_models.dart';

class TimerReading {
  const TimerReading({required this.remainingMs, required this.expired});
  final int remainingMs;
  final bool expired;
}

TimerReading readTimer(KitchenTask task, int nowEpochMs) {
  if (task.status != TaskStatus.running || task.deadlineEpochMs == null) {
    return const TimerReading(remainingMs: 0, expired: false);
  }
  final remaining = task.deadlineEpochMs! - nowEpochMs;
  return TimerReading(
    remainingMs: remaining > 0 ? remaining : 0,
    expired: remaining <= 0,
  );
}

void startTask(KitchenTask task, int nowEpochMs) {
  if (task.isTerminal || task.status == TaskStatus.blocked) return;
  task.status = TaskStatus.running;
  task.startedAtEpochMs ??= nowEpochMs;
  task.endedAtEpochMs = null;
  final durationMs =
      task.pausedRemainingMs ?? ((task.durationSeconds ?? 0) * 1000);
  task.deadlineEpochMs = durationMs > 0 ? nowEpochMs + durationMs : null;
  task.pausedRemainingMs = null;
}

void pauseTask(KitchenTask task, int nowEpochMs) {
  if (task.status != TaskStatus.running) return;
  if (task.deadlineEpochMs != null) {
    task.pausedRemainingMs =
        (task.deadlineEpochMs! - nowEpochMs).clamp(0, 1 << 62).toInt();
  }
  task.deadlineEpochMs = null;
  task.status = TaskStatus.ready;
}

void extendTask(KitchenTask task, int nowEpochMs, Duration extension) {
  if (extension.inMilliseconds <= 0) return;
  if (task.status == TaskStatus.running) {
    task.deadlineEpochMs =
        (task.deadlineEpochMs ?? nowEpochMs) + extension.inMilliseconds;
  } else if (task.pausedRemainingMs != null) {
    task.pausedRemainingMs = task.pausedRemainingMs! + extension.inMilliseconds;
  } else {
    task.durationSeconds = (task.durationSeconds ?? 0) + extension.inSeconds;
  }
}

void completeTask(KitchenTask task, int nowEpochMs) {
  task.status = TaskStatus.done;
  task.endedAtEpochMs = nowEpochMs;
  task.deadlineEpochMs = null;
  task.pausedRemainingMs = null;
}

void skipTask(KitchenTask task, int nowEpochMs) {
  task.status = TaskStatus.skipped;
  task.endedAtEpochMs = nowEpochMs;
  task.deadlineEpochMs = null;
  task.pausedRemainingMs = null;
}

void restoreTask(KitchenTask task) {
  task.status = TaskStatus.waiting;
  task.startedAtEpochMs = null;
  task.endedAtEpochMs = null;
  task.deadlineEpochMs = null;
  task.pausedRemainingMs = null;
}

/// Reconciles persisted timers after resume/process death/reboot. Expired timers
/// stay running and become "attention required" in presentation; expiry never
/// marks a task done or food-safe.
List<String> reconcileExpiredTimers(KitchenBoard board, int nowEpochMs) {
  final expiredIds = <String>[];
  for (final task in board.tasks) {
    if (task.status == TaskStatus.running &&
        task.deadlineEpochMs != null &&
        task.deadlineEpochMs! <= nowEpochMs) {
      expiredIds.add(task.id);
    }
  }
  return expiredIds;
}
