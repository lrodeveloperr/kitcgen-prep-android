import 'kitchen_models.dart';
import 'timer_logic.dart';

class KitchenWorkflowEngine {
  KitchenWorkflowEngine({KitchenSnapshot? snapshot})
      : snapshot = snapshot ?? KitchenSnapshot.empty();

  KitchenSnapshot snapshot;
  int _sequence = 0;

  String _id(String prefix, int nowEpochMs) =>
      '${prefix}_${nowEpochMs}_${_sequence++}';

  KitchenBoard createDraft({
    required String title,
    required BoardMode mode,
    required int nowEpochMs,
    Iterable<String> taskNames = const <String>[],
    Iterable<String> stationItemNames = const <String>[],
  }) {
    final boardId = _id('board', nowEpochMs);
    final board = KitchenBoard(
      id: boardId,
      title: title.trim().isEmpty ? 'Prep board' : title.trim(),
      mode: mode,
      createdAtEpochMs: nowEpochMs,
      updatedAtEpochMs: nowEpochMs,
      tasks: <KitchenTask>[
        for (final name in taskNames.where((value) => value.trim().isNotEmpty))
          KitchenTask(id: _id('task', nowEpochMs), name: name.trim()),
      ],
      stationItems: <StationItem>[
        for (final name
            in stationItemNames.where((value) => value.trim().isNotEmpty))
          StationItem(id: _id('item', nowEpochMs), name: name.trim()),
      ],
    );
    snapshot.boards.insert(0, board);
    return board;
  }

  void startBoard(KitchenBoard board, int nowEpochMs) {
    final current = snapshot.activeBoard;
    if (current != null && current.id != board.id) {
      throw StateError('An active board already exists.');
    }
    board.status = BoardStatus.active;
    board.updatedAtEpochMs = nowEpochMs;
    for (final task in board.tasks) {
      if (!task.isTerminal && task.status == TaskStatus.waiting) {
        task.status = TaskStatus.ready;
      }
    }
    snapshot.activeBoardId = board.id;
  }

  void pauseNewTasks(KitchenBoard board, int nowEpochMs) {
    if (!board.isActive) return;
    board.status = BoardStatus.paused;
    board.updatedAtEpochMs = nowEpochMs;
    // Existing running task deadlines intentionally continue.
  }

  void resumeBoard(KitchenBoard board, int nowEpochMs) {
    if (board.status != BoardStatus.paused) return;
    board.status = BoardStatus.active;
    board.updatedAtEpochMs = nowEpochMs;
  }

  void finishBoard(KitchenBoard board, int nowEpochMs) {
    if (!board.isActive) return;
    final unfinished = board.unfinishedCount;
    for (final task in board.tasks) {
      task.deadlineEpochMs = null;
      task.pausedRemainingMs = null;
    }
    board.status = unfinished == 0
        ? BoardStatus.completed
        : BoardStatus.closedIncomplete;
    board.endedAtEpochMs = nowEpochMs;
    board.endReason = unfinished == 0
        ? 'completed'
        : 'closed_with_${unfinished}_unfinished';
    board.updatedAtEpochMs = nowEpochMs;
    if (snapshot.activeBoardId == board.id) snapshot.activeBoardId = null;
  }

  KitchenBoard duplicateBoard(KitchenBoard source, int nowEpochMs) {
    final id = _id('board', nowEpochMs);
    final copy = source.duplicate(newId: id, nowEpochMs: nowEpochMs);
    copy.title = '${source.title} copy';
    snapshot.boards.insert(0, copy);
    return copy;
  }

  void deleteBoard(KitchenBoard board) {
    if (board.isActive) {
      throw StateError('Active board must be finished before deletion.');
    }
    snapshot.boards.removeWhere((candidate) => candidate.id == board.id);
    if (snapshot.activeBoardId == board.id) snapshot.activeBoardId = null;
  }

  List<String> reconcile(int nowEpochMs) {
    final board = snapshot.activeBoard;
    return board == null
        ? const <String>[]
        : reconcileExpiredTimers(board, nowEpochMs);
  }
}
