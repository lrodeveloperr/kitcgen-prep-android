import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:kitchen_prep_board/data/kitchen_store.dart';
import 'package:kitchen_prep_board/domain/kitchen_models.dart';
import 'package:kitchen_prep_board/domain/scheduling_engine.dart';
import 'package:kitchen_prep_board/domain/timer_logic.dart' as timers;
import 'package:kitchen_prep_board/domain/workflow_engine.dart';
import 'package:kitchen_prep_board/l10n/kitchen_strings.dart';
import 'package:kitchen_prep_board/services/monetization_service.dart';
import 'package:kitchen_prep_board/services/timer_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class KitchenController extends ChangeNotifier with WidgetsBindingObserver {
  KitchenController({
    KitchenStore? store,
    TimerNotifications? notifications,
    MonetizationService? monetization,
  })  : store = store ?? AtomicFileKitchenStore(),
        notifications = notifications ?? TimerNotifications(),
        monetization = monetization ?? MonetizationService();

  final KitchenStore store;
  final TimerNotifications notifications;
  final MonetizationService monetization;
  KitchenWorkflowEngine engine = KitchenWorkflowEngine();
  bool ready = false;
  List<String> expiredTaskIds = const <String>[];
  Timer? _ticker;
  Future<void>? _saveInFlight;
  Locale _systemLocale = const Locale('en');
  String? _lastClosedSnapshot;
  int? _lastClosedAtEpochMs;

  KitchenSnapshot get snapshot => engine.snapshot;
  KitchenBoard? get activeBoard => snapshot.activeBoard;
  KitchenBoard? get recoverableDraft {
    for (final board in snapshot.boards) {
      if (board.status == BoardStatus.draft) return board;
    }
    return null;
  }

  Locale? get localeOverride {
    final value = snapshot.languageOverride;
    if (value == null || value.isEmpty) return null;
    if (value == 'zh_Hans') {
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
    }
    if (value == 'zh_Hant') {
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
    }
    return Locale(value);
  }

  KitchenStrings get strings => KitchenStrings(localeOverride ?? _systemLocale);

  Future<void> initialize(Locale systemLocale) async {
    _systemLocale = systemLocale;
    WidgetsBinding.instance.addObserver(this);
    engine = KitchenWorkflowEngine(snapshot: await store.load());
    expiredTaskIds = engine.reconcile(DateTime.now().millisecondsSinceEpoch);
    await notifications.initialize(strings);
    await WakelockPlus.toggle(enable: snapshot.keepScreenAwake);
    unawaited(monetization.initialize());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final ids = engine.reconcile(DateTime.now().millisecondsSinceEpoch);
      if (!listEquals(ids, expiredTaskIds)) {
        expiredTaskIds = ids;
        notifyListeners();
      } else if ((activeBoard?.runningCount ?? 0) > 0) {
        notifyListeners();
      }
    });
    ready = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final previous = _saveInFlight;
    if (previous != null) await previous;
    final operation = store.save(snapshot);
    _saveInFlight = operation;
    try {
      await operation;
    } finally {
      if (identical(_saveInFlight, operation)) _saveInFlight = null;
    }
  }

  Future<KitchenBoard> createDraft({
    required String title,
    required BoardMode mode,
    required Iterable<String> taskNames,
    Iterable<String> stationItemNames = const <String>[],
    String sourceType = 'manual',
    String? originalText,
    String? referenceUrl,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final board = engine.createDraft(
      title: title,
      mode: mode,
      nowEpochMs: now,
      taskNames: taskNames,
      stationItemNames: stationItemNames,
      sourceType: sourceType,
      originalText: originalText,
      referenceUrl: referenceUrl,
    );
    await _save();
    notifyListeners();
    return board;
  }

  Future<KitchenBoard> createDraftFromText({
    required String title,
    required BoardMode mode,
    required String text,
    String sourceType = 'paste',
  }) {
    final tasks = text
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.replaceFirst(RegExp(r'^\s*(?:[-*•]|\d+[.)])\s*'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return createDraft(
      title: title,
      mode: mode,
      taskNames: tasks,
      sourceType: sourceType,
      originalText: text,
    );
  }

  Future<void> recordCatalogueUse(Iterable<String> ids) async {
    for (final id in ids) {
      snapshot.catalogueUsage[id] = (snapshot.catalogueUsage[id] ?? 0) + 1;
    }
    await _save();
  }

  Future<void> updateTask(
    KitchenBoard board,
    KitchenTask task, {
    String? name,
    int? durationSeconds,
    bool clearDuration = false,
    TaskKind? kind,
    TaskPriority? priority,
    List<String>? dependencyIds,
    List<TaskResourceRequirement>? resourceRequirements,
  }) async {
    if (name != null && name.trim().isNotEmpty) task.name = name.trim();
    if (clearDuration) {
      task.durationSeconds = null;
    } else if (durationSeconds != null) {
      task.durationSeconds = durationSeconds > 0 ? durationSeconds : null;
    }
    if (kind != null) task.kind = kind;
    if (priority != null) task.priority = priority;
    final previousDependencies = List<String>.of(task.dependencyIds);
    if (dependencyIds != null) {
      task.dependencyIds
        ..clear()
        ..addAll(dependencyIds.where((id) => id != task.id));
    }
    if (resourceRequirements != null) {
      task.resourceRequirements
        ..clear()
        ..addAll(resourceRequirements);
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    board.updatedAtEpochMs = now;
    try {
      if (board.status == BoardStatus.draft) {
        engine.prepareDraft(board, now);
      } else {
        engine.taskStateChanged(board, now);
      }
    } on DependencyCycleException {
      task.dependencyIds
        ..clear()
        ..addAll(previousDependencies);
      rethrow;
    }
    await _save();
    notifyListeners();
  }

  Future<void> addTaskToDraft(KitchenBoard board, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    board.tasks.add(KitchenTask(id: 'task_$stamp', name: trimmed));
    board.updatedAtEpochMs = DateTime.now().millisecondsSinceEpoch;
    await _save();
    notifyListeners();
  }

  Future<void> removeTaskFromDraft(KitchenBoard board, KitchenTask task) async {
    board.tasks.removeWhere((candidate) => candidate.id == task.id);
    for (final candidate in board.tasks) {
      candidate.dependencyIds.remove(task.id);
    }
    board.updatedAtEpochMs = DateTime.now().millisecondsSinceEpoch;
    await _save();
    notifyListeners();
  }

  Future<void> duplicateTaskInDraft(KitchenBoard board, KitchenTask task) async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final index = board.tasks.indexOf(task);
    final copy = KitchenTask(
      id: 'task_$stamp',
      name: task.name,
      kind: task.kind,
      durationSeconds: task.durationSeconds,
      priority: task.priority,
      note: task.note,
      sourceItemId: task.sourceItemId,
    );
    board.tasks.insert(index + 1, copy);
    board.updatedAtEpochMs = DateTime.now().millisecondsSinceEpoch;
    await _save();
    notifyListeners();
  }

  Future<void> reorderTasks(KitchenBoard board, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final task = board.tasks.removeAt(oldIndex);
    board.tasks.insert(newIndex.clamp(0, board.tasks.length).toInt(), task);
    board.updatedAtEpochMs = DateTime.now().millisecondsSinceEpoch;
    await _save();
    notifyListeners();
  }

  Future<void> moveTaskToTop(KitchenBoard board, KitchenTask task) async {
    final index = board.tasks.indexOf(task);
    if (index <= 0) return;
    board.tasks
      ..removeAt(index)
      ..insert(0, task);
    engine.taskStateChanged(board, DateTime.now().millisecondsSinceEpoch);
    await _save();
    notifyListeners();
  }

  Future<void> setTiming(
    KitchenBoard board, {
    required TimingMode mode,
    int? targetReadyAtEpochMs,
    String? timeZoneId,
  }) async {
    board.timingMode = mode;
    board.targetReadyAtEpochMs = mode == TimingMode.readyAt ? targetReadyAtEpochMs : null;
    if (timeZoneId != null) board.targetTimeZoneId = timeZoneId;
    engine.prepareDraft(board, DateTime.now().millisecondsSinceEpoch);
    await _save();
    notifyListeners();
  }

  ScheduleResult? scheduleFor(KitchenBoard board) {
    try {
      return SchedulingEngine.schedule(board, DateTime.now().millisecondsSinceEpoch);
    } on Object {
      return null;
    }
  }

  Future<void> addResource(KitchenBoard board, String name, {int capacity = 1}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    board.resources.add(
      KitchenResource(
        id: 'resource_${DateTime.now().microsecondsSinceEpoch}',
        name: trimmed,
        capacity: capacity.clamp(1, 9999).toInt(),
      ),
    );
    await _save();
    notifyListeners();
  }

  Future<void> updateResource(
    KitchenBoard board,
    KitchenResource resource, {
    String? name,
    int? capacity,
    bool? available,
  }) async {
    if (name != null && name.trim().isNotEmpty) resource.name = name.trim();
    if (capacity != null) resource.capacity = capacity.clamp(1, 9999).toInt();
    if (available != null) resource.available = available;
    await _save();
    notifyListeners();
  }

  Future<void> startBoard(KitchenBoard board) async {
    engine.startBoard(board, DateTime.now().millisecondsSinceEpoch);
    await _save();
    notifyListeners();
  }

  Future<void> pauseBoard(KitchenBoard board) async {
    engine.pauseNewTasks(board, DateTime.now().millisecondsSinceEpoch);
    await _save();
    notifyListeners();
  }

  Future<void> resumeBoard(KitchenBoard board) async {
    engine.resumeBoard(board, DateTime.now().millisecondsSinceEpoch);
    await _save();
    notifyListeners();
  }

  Future<void> startTask(KitchenBoard board, KitchenTask task, KitchenStrings strings) async {
    if (board.status == BoardStatus.paused) return;
    if (task.status != TaskStatus.ready && task.status != TaskStatus.waiting) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    timers.startTask(task, now);
    board.updatedAtEpochMs = now;
    if (task.deadlineEpochMs != null && snapshot.timerAlertsEnabled) {
      await notifications.requestPermission();
      await notifications.schedule(task, strings);
    }
    await _save();
    notifyListeners();
  }

  Future<void> pauseTaskTimer(KitchenBoard board, KitchenTask task) async {
    timers.pauseTask(task, DateTime.now().millisecondsSinceEpoch);
    await notifications.cancel(task);
    board.updatedAtEpochMs = DateTime.now().millisecondsSinceEpoch;
    await _save();
    notifyListeners();
  }

  Future<void> resumeTaskTimer(
    KitchenBoard board,
    KitchenTask task,
    KitchenStrings strings,
  ) async {
    timers.startTask(task, DateTime.now().millisecondsSinceEpoch);
    if (task.deadlineEpochMs != null && snapshot.timerAlertsEnabled) {
      await notifications.schedule(task, strings);
    }
    await _save();
    notifyListeners();
  }

  Future<void> addTime(
    KitchenTask task,
    Duration extension,
    KitchenStrings strings,
  ) async {
    timers.extendTask(task, DateTime.now().millisecondsSinceEpoch, extension);
    await notifications.cancel(task);
    if (task.deadlineEpochMs != null && snapshot.timerAlertsEnabled) {
      await notifications.schedule(task, strings);
    }
    await _save();
    notifyListeners();
  }

  Future<void> markDone(KitchenBoard board, KitchenTask task) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    timers.completeTask(task, now);
    await notifications.cancel(task);
    engine.taskStateChanged(board, now);
    await _save();
    notifyListeners();
  }

  Future<void> markSkipped(KitchenBoard board, KitchenTask task) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    timers.skipTask(task, now);
    await notifications.cancel(task);
    engine.taskStateChanged(board, now);
    await _save();
    notifyListeners();
  }

  Future<void> restore(KitchenBoard board, KitchenTask task) async {
    timers.restoreTask(task);
    engine.taskStateChanged(board, DateTime.now().millisecondsSinceEpoch);
    await _save();
    notifyListeners();
  }

  Future<void> finishBoard(KitchenBoard board) async {
    _lastClosedSnapshot = snapshot.encode();
    _lastClosedAtEpochMs = DateTime.now().millisecondsSinceEpoch;
    engine.finishBoard(board, DateTime.now().millisecondsSinceEpoch);
    await notifications.cancelAll();
    await _save();
    notifyListeners();
  }

  Future<bool> undoLastFinish(KitchenStrings strings) async {
    final source = _lastClosedSnapshot;
    final closedAt = _lastClosedAtEpochMs;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (source == null || closedAt == null || now - closedAt > 10000) {
      _lastClosedSnapshot = null;
      _lastClosedAtEpochMs = null;
      return false;
    }

    engine = KitchenWorkflowEngine(snapshot: KitchenSnapshot.decode(source));
    _lastClosedSnapshot = null;
    _lastClosedAtEpochMs = null;
    expiredTaskIds = engine.reconcile(now);
    await notifications.cancelAll();
    final board = activeBoard;
    if (board != null && snapshot.timerAlertsEnabled) {
      for (final task in board.tasks) {
        if (task.status == TaskStatus.running &&
            task.deadlineEpochMs != null &&
            task.deadlineEpochMs! > now) {
          await notifications.schedule(task, strings);
        }
      }
    }
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> deleteBoard(KitchenBoard board) async {
    engine.deleteBoard(board);
    await _save();
    notifyListeners();
  }

  Future<KitchenBoard> duplicateBoard(KitchenBoard board) async {
    final copy = engine.duplicateBoard(board, DateTime.now().millisecondsSinceEpoch);
    await _save();
    notifyListeners();
    return copy;
  }

  Future<KitchenTemplate> saveTemplate(KitchenBoard board) async {
    final template = engine.saveTemplate(board, DateTime.now().millisecondsSinceEpoch);
    await _save();
    notifyListeners();
    return template;
  }

  Future<KitchenBoard> createFromTemplate(KitchenTemplate template) async {
    final board = engine.createFromTemplate(template, DateTime.now().millisecondsSinceEpoch);
    await _save();
    notifyListeners();
    return board;
  }

  Future<void> renameTemplate(KitchenTemplate template, String title) async {
    engine.renameTemplate(
      template,
      title,
      DateTime.now().millisecondsSinceEpoch,
    );
    await _save();
    notifyListeners();
  }

  Future<KitchenTemplate> duplicateTemplate(KitchenTemplate template) async {
    final now = DateTime.now();
    final suffix =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final copy = engine.duplicateTemplate(
      template,
      '${template.title} · $suffix',
      now.millisecondsSinceEpoch,
    );
    await _save();
    notifyListeners();
    return copy;
  }

  Future<void> deleteTemplate(KitchenTemplate template) async {
    engine.deleteTemplate(template);
    await _save();
    notifyListeners();
  }

  Future<void> updateStationItem(
    KitchenBoard board,
    StationItem item, {
    double? have,
    double? par,
    double? prepared,
    bool? verified,
    String? unit,
  }) async {
    if (have != null) item.setHave(have);
    if (par != null) item.setPar(par);
    if (prepared != null) item.setPrepared(prepared);
    if (verified != null) item.verified = verified;
    if (unit != null && item.unit != unit) {
      item.unit = unit;
      item.verified = false;
    }
    board.updatedAtEpochMs = DateTime.now().millisecondsSinceEpoch;
    await _save();
    notifyListeners();
  }

  Future<void> applyUnitToStationItems(KitchenBoard board, String unit) async {
    for (final item in board.stationItems) {
      if (item.unit != unit) {
        item.unit = unit;
        item.verified = false;
      }
    }
    board.updatedAtEpochMs = DateTime.now().millisecondsSinceEpoch;
    await _save();
    notifyListeners();
  }

  Future<void> handoff(
    KitchenBoard board, {
    required String note,
    required bool keepTimersRunning,
  }) async {
    board.handoffNote = note.trim().isEmpty ? null : note.trim();
    if (!keepTimersRunning) {
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final task in board.tasks.where((task) => task.status == TaskStatus.running)) {
        timers.pauseTask(task, now);
        await notifications.cancel(task);
      }
    }
    engine.pauseNewTasks(board, DateTime.now().millisecondsSinceEpoch);
    await _save();
    notifyListeners();
  }

  Future<void> setTimerAlerts(bool enabled, KitchenStrings strings) async {
    if (enabled) {
      final granted = await notifications.requestPermission();
      snapshot.timerAlertsEnabled = granted;
      if (granted) {
        final board = activeBoard;
        if (board != null) {
          for (final task in board.tasks) {
            if (task.status == TaskStatus.running && task.deadlineEpochMs != null) {
              await notifications.schedule(task, strings);
            }
          }
        }
      }
    } else {
      snapshot.timerAlertsEnabled = false;
      await notifications.cancelAll();
    }
    await _save();
    notifyListeners();
  }

  Future<void> setKeepScreenAwake(bool enabled) async {
    snapshot.keepScreenAwake = enabled;
    await WakelockPlus.toggle(enable: enabled);
    await _save();
    notifyListeners();
  }

  Future<void> setLanguage(String? value, Locale systemLocale) async {
    _systemLocale = systemLocale;
    snapshot.languageOverride = value;
    await _save();
    await notifications.initialize(strings);
    notifyListeners();
  }

  Future<void> setRegion(String? regionCode) async {
    snapshot.regionOverride = regionCode;
    await _save();
    notifyListeners();
  }

  Future<void> setUnits({required String unitSystem, required String temperatureUnit}) async {
    snapshot.unitSystem = unitSystem;
    snapshot.temperatureUnit = temperatureUnit;
    await _save();
    notifyListeners();
  }

  Future<void> clearLocalData() async {
    await notifications.cancelAll();
    await store.clear();
    engine = KitchenWorkflowEngine();
    expiredTaskIds = const <String>[];
    await WakelockPlus.disable();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      expiredTaskIds = engine.reconcile(DateTime.now().millisecondsSinceEpoch);
      unawaited(notifications.refreshTimeZone());
      unawaited(_save());
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    monetization.dispose();
    super.dispose();
  }
}
