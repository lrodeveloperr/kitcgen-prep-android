import 'kitchen_models.dart';
import 'scheduling_engine.dart';
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
    String sourceType = 'manual',
    String? originalText,
    String? referenceUrl,
  }) {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Board title must not be empty.');
    }
    final boardId = _id('board', nowEpochMs);
    final board = KitchenBoard(
      id: boardId,
      title: normalizedTitle,
      mode: mode,
      sourceType: sourceType,
      originalText: originalText,
      referenceUrl: referenceUrl,
      createdAtEpochMs: nowEpochMs,
      updatedAtEpochMs: nowEpochMs,
      tasks: <KitchenTask>[
        for (final name in taskNames.where((value) => value.trim().isNotEmpty))
          KitchenTask(id: _id('task', nowEpochMs), name: name.trim()),
      ],
      stationItems: <StationItem>[
        for (final name in stationItemNames.where((value) => value.trim().isNotEmpty))
          StationItem(id: _id('item', nowEpochMs), name: name.trim()),
      ],
    );
    snapshot.boards.insert(0, board);
    snapshot.lastMode = mode;
    return board;
  }

  void prepareDraft(KitchenBoard board, int nowEpochMs) {
    if (board.status != BoardStatus.draft) return;
    try {
      SchedulingEngine.applySuggestions(board, nowEpochMs);
    } on ResourceUnavailableException {
      for (final task in board.tasks) {
        task.suggestedStartEpochMs = null;
        task.suggestedEndEpochMs = null;
      }
    }
    board.updatedAtEpochMs = nowEpochMs;
  }

  void startBoard(KitchenBoard board, int nowEpochMs) {
    final current = snapshot.activeBoard;
    if (current != null && current.id != board.id) {
      throw StateError('An active board already exists.');
    }
    SchedulingEngine.applySuggestions(board, nowEpochMs);
    board.status = BoardStatus.active;
    SchedulingEngine.recomputeAvailability(board);
    board.updatedAtEpochMs = nowEpochMs;
    snapshot.activeBoardId = board.id;
    snapshot.lastMode = board.mode;
  }

  void pauseNewTasks(KitchenBoard board, int nowEpochMs) {
    if (!board.isActive) return;
    board.status = BoardStatus.paused;
    board.updatedAtEpochMs = nowEpochMs;
  }

  void resumeBoard(KitchenBoard board, int nowEpochMs) {
    if (board.status != BoardStatus.paused) return;
    board.status = BoardStatus.active;
    SchedulingEngine.recomputeAvailability(board);
    SchedulingEngine.applySuggestions(board, nowEpochMs);
    board.updatedAtEpochMs = nowEpochMs;
  }

  void taskStateChanged(KitchenBoard board, int nowEpochMs) {
    SchedulingEngine.recomputeAvailability(board);
    try {
      SchedulingEngine.applySuggestions(board, nowEpochMs);
    } on ResourceUnavailableException {
      // The UI exposes resource correction; state availability itself remains valid.
    }
    board.updatedAtEpochMs = nowEpochMs;
  }

  void finishBoard(KitchenBoard board, int nowEpochMs) {
    if (!board.isActive) return;
    final unfinished = board.unfinishedCount;
    for (final task in board.tasks) {
      task.deadlineEpochMs = null;
      task.pausedRemainingMs = null;
    }
    board.status =
        unfinished == 0 ? BoardStatus.completed : BoardStatus.closedIncomplete;
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
    copy.title = source.title;
    snapshot.boards.insert(0, copy);
    return copy;
  }

  KitchenTemplate saveTemplate(KitchenBoard source, int nowEpochMs) {
    final boardCopy = source.duplicate(
      newId: _id('template_board', nowEpochMs),
      nowEpochMs: nowEpochMs,
    );
    final template = KitchenTemplate(
      id: _id('template', nowEpochMs),
      title: source.title,
      board: boardCopy,
      createdAtEpochMs: nowEpochMs,
      updatedAtEpochMs: nowEpochMs,
    );
    snapshot.templates.insert(0, template);
    return template;
  }

  KitchenBoard createFromTemplate(KitchenTemplate template, int nowEpochMs) {
    final copy = template.board.duplicate(
      newId: _id('board', nowEpochMs),
      nowEpochMs: nowEpochMs,
    );
    copy.title = template.title;
    snapshot.boards.insert(0, copy);
    return copy;
  }

  void renameTemplate(
    KitchenTemplate template,
    String title,
    int nowEpochMs,
  ) {
    final normalized = title.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Template title must not be empty.');
    }
    template.title = normalized;
    template.updatedAtEpochMs = nowEpochMs;
  }

  KitchenTemplate duplicateTemplate(
    KitchenTemplate source,
    String title,
    int nowEpochMs,
  ) {
    final normalized = title.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Template title must not be empty.');
    }
    final boardCopy = source.board.duplicate(
      newId: _id('template_board', nowEpochMs),
      nowEpochMs: nowEpochMs,
    );
    boardCopy.title = normalized;
    final template = KitchenTemplate(
      id: _id('template', nowEpochMs),
      title: normalized,
      board: boardCopy,
      createdAtEpochMs: nowEpochMs,
      updatedAtEpochMs: nowEpochMs,
    );
    snapshot.templates.insert(0, template);
    return template;
  }

  void deleteTemplate(KitchenTemplate template) {
    snapshot.templates.removeWhere((candidate) => candidate.id == template.id);
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
