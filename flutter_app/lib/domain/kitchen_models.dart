import 'dart:convert';

enum BoardMode { home, station }
enum BoardStatus { draft, active, paused, completed, closedIncomplete }
enum TaskStatus { waiting, ready, running, done, skipped }
enum TaskKind { step, singleTimer }

int _asInt(Object? value, [int fallback = 0]) =>
    value is int ? value : int.tryParse('$value') ?? fallback;
double _asDouble(Object? value, [double fallback = 0]) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;
String? _asNullableString(Object? value) => value == null ? null : '$value';

T _enumByName<T extends Enum>(Iterable<T> values, Object? raw, T fallback) {
  final name = '$raw';
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

class KitchenTask {
  KitchenTask({
    required this.id,
    required this.name,
    this.kind = TaskKind.step,
    this.durationSeconds,
    this.status = TaskStatus.waiting,
    this.startedAtEpochMs,
    this.deadlineEpochMs,
    this.pausedRemainingMs,
    this.note,
  });

  final String id;
  String name;
  TaskKind kind;
  int? durationSeconds;
  TaskStatus status;
  int? startedAtEpochMs;
  int? deadlineEpochMs;
  int? pausedRemainingMs;
  String? note;

  bool get isTerminal => status == TaskStatus.done || status == TaskStatus.skipped;
  bool get hasTimer => durationSeconds != null && durationSeconds! > 0;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'kind': kind.name,
        'durationSeconds': durationSeconds,
        'status': status.name,
        'startedAtEpochMs': startedAtEpochMs,
        'deadlineEpochMs': deadlineEpochMs,
        'pausedRemainingMs': pausedRemainingMs,
        'note': note,
      };

  factory KitchenTask.fromJson(Map<String, Object?> json) => KitchenTask(
        id: '${json['id']}',
        name: '${json['name'] ?? ''}',
        kind: _enumByName(TaskKind.values, json['kind'], TaskKind.step),
        durationSeconds: json['durationSeconds'] == null
            ? null
            : _asInt(json['durationSeconds']),
        status: _enumByName(TaskStatus.values, json['status'], TaskStatus.waiting),
        startedAtEpochMs: json['startedAtEpochMs'] == null
            ? null
            : _asInt(json['startedAtEpochMs']),
        deadlineEpochMs: json['deadlineEpochMs'] == null
            ? null
            : _asInt(json['deadlineEpochMs']),
        pausedRemainingMs: json['pausedRemainingMs'] == null
            ? null
            : _asInt(json['pausedRemainingMs']),
        note: _asNullableString(json['note']),
      );

  KitchenTask duplicate({required String newId}) => KitchenTask(
        id: newId,
        name: name,
        kind: kind,
        durationSeconds: durationSeconds,
        note: note,
      );
}

class StationItem {
  StationItem({
    required this.id,
    required this.name,
    this.have = 0,
    this.par = 0,
    this.prepared = 0,
    this.verified = false,
    this.unit = '',
  });

  final String id;
  String name;
  double have;
  double par;
  double prepared;
  bool verified;
  String unit;

  double get need => (par - have).clamp(0, double.infinity).toDouble();
  double get surplus => (have - par).clamp(0, double.infinity).toDouble();
  double get remainingToPrepare =>
      (need - prepared).clamp(0, double.infinity).toDouble();

  void setHave(double value) {
    if (!value.isFinite || value < 0) throw ArgumentError.value(value, 'have');
    have = value;
    verified = false;
  }

  void setPar(double value) {
    if (!value.isFinite || value < 0) throw ArgumentError.value(value, 'par');
    par = value;
    verified = false;
  }

  void setPrepared(double value) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(value, 'prepared');
    }
    prepared = value;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'have': have,
        'par': par,
        'prepared': prepared,
        'verified': verified,
        'unit': unit,
      };

  factory StationItem.fromJson(Map<String, Object?> json) => StationItem(
        id: '${json['id']}',
        name: '${json['name'] ?? ''}',
        have: _asDouble(json['have']),
        par: _asDouble(json['par']),
        prepared: _asDouble(json['prepared']),
        verified: json['verified'] == true,
        unit: '${json['unit'] ?? ''}',
      );

  StationItem duplicate({required String newId}) => StationItem(
        id: newId,
        name: name,
        par: par,
        unit: unit,
      );
}

class KitchenBoard {
  KitchenBoard({
    required this.id,
    required this.title,
    required this.mode,
    required this.createdAtEpochMs,
    required this.updatedAtEpochMs,
    this.status = BoardStatus.draft,
    List<KitchenTask>? tasks,
    List<StationItem>? stationItems,
    this.endedAtEpochMs,
    this.endReason,
  })  : tasks = tasks ?? <KitchenTask>[],
        stationItems = stationItems ?? <StationItem>[];

  final String id;
  String title;
  BoardMode mode;
  BoardStatus status;
  final List<KitchenTask> tasks;
  final List<StationItem> stationItems;
  final int createdAtEpochMs;
  int updatedAtEpochMs;
  int? endedAtEpochMs;
  String? endReason;

  bool get isActive => status == BoardStatus.active || status == BoardStatus.paused;
  bool get isTerminal =>
      status == BoardStatus.completed || status == BoardStatus.closedIncomplete;
  int get doneCount => tasks.where((task) => task.status == TaskStatus.done).length;
  int get runningCount => tasks.where((task) => task.status == TaskStatus.running).length;
  int get waitingCount => tasks.where((task) => !task.isTerminal && task.status != TaskStatus.running).length;
  int get unfinishedCount => tasks.where((task) => !task.isTerminal).length;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'title': title,
        'mode': mode.name,
        'status': status.name,
        'tasks': tasks.map((task) => task.toJson()).toList(),
        'stationItems': stationItems.map((item) => item.toJson()).toList(),
        'createdAtEpochMs': createdAtEpochMs,
        'updatedAtEpochMs': updatedAtEpochMs,
        'endedAtEpochMs': endedAtEpochMs,
        'endReason': endReason,
      };

  factory KitchenBoard.fromJson(Map<String, Object?> json) => KitchenBoard(
        id: '${json['id']}',
        title: '${json['title'] ?? ''}',
        mode: _enumByName(BoardMode.values, json['mode'], BoardMode.home),
        status: _enumByName(BoardStatus.values, json['status'], BoardStatus.draft),
        tasks: ((json['tasks'] as List<Object?>?) ?? const <Object?>[])
            .whereType<Map<Object?, Object?>>()
            .map((raw) => KitchenTask.fromJson(raw.map((k, v) => MapEntry('$k', v))))
            .toList(),
        stationItems: ((json['stationItems'] as List<Object?>?) ?? const <Object?>[])
            .whereType<Map<Object?, Object?>>()
            .map((raw) => StationItem.fromJson(raw.map((k, v) => MapEntry('$k', v))))
            .toList(),
        createdAtEpochMs: _asInt(json['createdAtEpochMs']),
        updatedAtEpochMs: _asInt(json['updatedAtEpochMs']),
        endedAtEpochMs: json['endedAtEpochMs'] == null
            ? null
            : _asInt(json['endedAtEpochMs']),
        endReason: _asNullableString(json['endReason']),
      );

  KitchenBoard duplicate({required String newId, required int nowEpochMs}) => KitchenBoard(
        id: newId,
        title: title,
        mode: mode,
        createdAtEpochMs: nowEpochMs,
        updatedAtEpochMs: nowEpochMs,
        tasks: <KitchenTask>[
          for (var i = 0; i < tasks.length; i++)
            tasks[i].duplicate(newId: '${newId}_task_$i'),
        ],
        stationItems: <StationItem>[
          for (var i = 0; i < stationItems.length; i++)
            stationItems[i].duplicate(newId: '${newId}_item_$i'),
        ],
      );
}

class KitchenSnapshot {
  KitchenSnapshot({
    required this.schemaVersion,
    required this.boards,
    this.activeBoardId,
    this.languageOverride,
    this.regionOverride,
  });

  static const currentSchemaVersion = 2;
  final int schemaVersion;
  final List<KitchenBoard> boards;
  String? activeBoardId;
  String? languageOverride;
  String? regionOverride;

  KitchenBoard? get activeBoard {
    final id = activeBoardId;
    if (id == null) return null;
    for (final board in boards) {
      if (board.id == id && board.isActive) return board;
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'activeBoardId': activeBoardId,
        'languageOverride': languageOverride,
        'regionOverride': regionOverride,
        'boards': boards.map((board) => board.toJson()).toList(),
      };

  String encode() => jsonEncode(toJson());

  factory KitchenSnapshot.empty() => KitchenSnapshot(
        schemaVersion: currentSchemaVersion,
        boards: <KitchenBoard>[],
      );

  factory KitchenSnapshot.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<Object?, Object?>) {
      throw const FormatException('Kitchen snapshot must be an object.');
    }
    final json = decoded.map((k, v) => MapEntry('$k', v));
    final version = _asInt(json['schemaVersion'], 1);
    if (version > currentSchemaVersion) {
      throw FormatException('Unsupported future schema version $version.');
    }
    return KitchenSnapshot(
      schemaVersion: currentSchemaVersion,
      activeBoardId: _asNullableString(json['activeBoardId']),
      languageOverride: _asNullableString(json['languageOverride']),
      regionOverride: _asNullableString(json['regionOverride']),
      boards: ((json['boards'] as List<Object?>?) ?? const <Object?>[])
          .whereType<Map<Object?, Object?>>()
          .map((raw) => KitchenBoard.fromJson(raw.map((k, v) => MapEntry('$k', v))))
          .toList(),
    );
  }
}
