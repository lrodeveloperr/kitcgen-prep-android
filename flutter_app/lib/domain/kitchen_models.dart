import 'dart:convert';

enum BoardMode { home, station }
enum BoardStatus { draft, active, paused, completed, closedIncomplete }
enum TaskStatus { waiting, blocked, ready, running, done, skipped }
enum TaskKind { step, singleTimer }
enum TaskPriority { none, low, normal, high }
enum TimingMode { startNow, readyAt }

int _asInt(Object? value, [int fallback = 0]) =>
    value is int ? value : int.tryParse('$value') ?? fallback;
double _asDouble(Object? value, [double fallback = 0]) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;
String? _asNullableString(Object? value) => value == null ? null : '$value';

Map<String, Object?> _stringMap(Object? value) {
  if (value is! Map) return <String, Object?>{};
  return value.map((key, item) => MapEntry('$key', item));
}

List<Object?> _list(Object? value) => value is List ? value.cast<Object?>() : const <Object?>[];

T _enumByName<T extends Enum>(Iterable<T> values, Object? raw, T fallback) {
  final name = '$raw';
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

class TaskResourceRequirement {
  TaskResourceRequirement({required this.resourceId, this.units = 1});

  String resourceId;
  int units;

  Map<String, Object?> toJson() => <String, Object?>{
        'resourceId': resourceId,
        'units': units,
      };

  factory TaskResourceRequirement.fromJson(Map<String, Object?> json) =>
      TaskResourceRequirement(
        resourceId: '${json['resourceId'] ?? ''}',
        units: _asInt(json['units'], 1).clamp(1, 9999).toInt(),
      );
}

class KitchenResource {
  KitchenResource({
    required this.id,
    required this.name,
    this.capacity = 1,
    this.available = true,
  });

  final String id;
  String name;
  int capacity;
  bool available;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'capacity': capacity,
        'available': available,
      };

  factory KitchenResource.fromJson(Map<String, Object?> json) => KitchenResource(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        capacity: _asInt(json['capacity'], 1).clamp(1, 9999).toInt(),
        available: json['available'] != false,
      );

  KitchenResource duplicate({required String newId}) => KitchenResource(
        id: newId,
        name: name,
        capacity: capacity,
        available: available,
      );
}

class KitchenTask {
  KitchenTask({
    required this.id,
    required this.name,
    this.kind = TaskKind.step,
    this.durationSeconds,
    this.status = TaskStatus.waiting,
    this.priority = TaskPriority.none,
    List<String>? dependencyIds,
    List<TaskResourceRequirement>? resourceRequirements,
    this.startedAtEpochMs,
    this.endedAtEpochMs,
    this.deadlineEpochMs,
    this.pausedRemainingMs,
    this.suggestedStartEpochMs,
    this.suggestedEndEpochMs,
    this.note,
    this.sourceItemId,
  })  : dependencyIds = dependencyIds ?? <String>[],
        resourceRequirements = resourceRequirements ?? <TaskResourceRequirement>[];

  final String id;
  String name;
  TaskKind kind;
  int? durationSeconds;
  TaskStatus status;
  TaskPriority priority;
  final List<String> dependencyIds;
  final List<TaskResourceRequirement> resourceRequirements;
  int? startedAtEpochMs;
  int? endedAtEpochMs;
  int? deadlineEpochMs;
  int? pausedRemainingMs;
  int? suggestedStartEpochMs;
  int? suggestedEndEpochMs;
  String? note;
  String? sourceItemId;

  bool get isTerminal => status == TaskStatus.done || status == TaskStatus.skipped;
  bool get hasTimer => durationSeconds != null && durationSeconds! > 0;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'kind': kind.name,
        'durationSeconds': durationSeconds,
        'status': status.name,
        'priority': priority.name,
        'dependencyIds': dependencyIds,
        'resourceRequirements': resourceRequirements.map((item) => item.toJson()).toList(),
        'startedAtEpochMs': startedAtEpochMs,
        'endedAtEpochMs': endedAtEpochMs,
        'deadlineEpochMs': deadlineEpochMs,
        'pausedRemainingMs': pausedRemainingMs,
        'suggestedStartEpochMs': suggestedStartEpochMs,
        'suggestedEndEpochMs': suggestedEndEpochMs,
        'note': note,
        'sourceItemId': sourceItemId,
      };

  factory KitchenTask.fromJson(Map<String, Object?> json) => KitchenTask(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        kind: _enumByName(TaskKind.values, json['kind'], TaskKind.step),
        durationSeconds:
            json['durationSeconds'] == null ? null : _asInt(json['durationSeconds']),
        status: _enumByName(TaskStatus.values, json['status'], TaskStatus.waiting),
        priority: _enumByName(TaskPriority.values, json['priority'], TaskPriority.none),
        dependencyIds: _list(json['dependencyIds']).map((item) => '$item').toList(),
        resourceRequirements: _list(json['resourceRequirements'])
            .map(_stringMap)
            .map(TaskResourceRequirement.fromJson)
            .where((item) => item.resourceId.isNotEmpty)
            .toList(),
        startedAtEpochMs:
            json['startedAtEpochMs'] == null ? null : _asInt(json['startedAtEpochMs']),
        endedAtEpochMs:
            json['endedAtEpochMs'] == null ? null : _asInt(json['endedAtEpochMs']),
        deadlineEpochMs:
            json['deadlineEpochMs'] == null ? null : _asInt(json['deadlineEpochMs']),
        pausedRemainingMs:
            json['pausedRemainingMs'] == null ? null : _asInt(json['pausedRemainingMs']),
        suggestedStartEpochMs: json['suggestedStartEpochMs'] == null
            ? null
            : _asInt(json['suggestedStartEpochMs']),
        suggestedEndEpochMs: json['suggestedEndEpochMs'] == null
            ? null
            : _asInt(json['suggestedEndEpochMs']),
        note: _asNullableString(json['note']),
        sourceItemId: _asNullableString(json['sourceItemId']),
      );

  KitchenTask duplicate({
    required String newId,
    required Map<String, String> taskIdMap,
    required Map<String, String> resourceIdMap,
  }) =>
      KitchenTask(
        id: newId,
        name: name,
        kind: kind,
        durationSeconds: durationSeconds,
        priority: priority,
        dependencyIds: dependencyIds
            .map((id) => taskIdMap[id])
            .whereType<String>()
            .toList(),
        resourceRequirements: <TaskResourceRequirement>[
          for (final requirement in resourceRequirements)
            if (resourceIdMap[requirement.resourceId] != null)
              TaskResourceRequirement(
                resourceId: resourceIdMap[requirement.resourceId]!,
                units: requirement.units,
              ),
        ],
        note: note,
        sourceItemId: sourceItemId,
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
    this.sourceItemId,
  });

  final String id;
  String name;
  double have;
  double par;
  double prepared;
  bool verified;
  String unit;
  String? sourceItemId;

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
    if (!value.isFinite || value < 0) throw ArgumentError.value(value, 'prepared');
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
        'sourceItemId': sourceItemId,
      };

  factory StationItem.fromJson(Map<String, Object?> json) => StationItem(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        have: _asDouble(json['have']),
        par: _asDouble(json['par']),
        prepared: _asDouble(json['prepared']),
        verified: json['verified'] == true,
        unit: '${json['unit'] ?? ''}',
        sourceItemId: _asNullableString(json['sourceItemId']),
      );

  StationItem duplicate({required String newId}) => StationItem(
        id: newId,
        name: name,
        par: par,
        unit: unit,
        sourceItemId: sourceItemId,
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
    this.timingMode = TimingMode.startNow,
    this.targetReadyAtEpochMs,
    this.targetTimeZoneId = '',
    this.sourceType = 'manual',
    this.originalText,
    this.referenceUrl,
    this.note,
    this.handoffNote,
    List<KitchenTask>? tasks,
    List<StationItem>? stationItems,
    List<KitchenResource>? resources,
    this.endedAtEpochMs,
    this.endReason,
  })  : tasks = tasks ?? <KitchenTask>[],
        stationItems = stationItems ?? <StationItem>[],
        resources = resources ?? <KitchenResource>[];

  final String id;
  String title;
  BoardMode mode;
  BoardStatus status;
  TimingMode timingMode;
  int? targetReadyAtEpochMs;
  String targetTimeZoneId;
  String sourceType;
  String? originalText;
  String? referenceUrl;
  String? note;
  String? handoffNote;
  final List<KitchenTask> tasks;
  final List<StationItem> stationItems;
  final List<KitchenResource> resources;
  final int createdAtEpochMs;
  int updatedAtEpochMs;
  int? endedAtEpochMs;
  String? endReason;

  bool get isActive => status == BoardStatus.active || status == BoardStatus.paused;
  bool get isTerminal =>
      status == BoardStatus.completed || status == BoardStatus.closedIncomplete;
  int get doneCount => tasks.where((task) => task.status == TaskStatus.done).length;
  int get runningCount => tasks.where((task) => task.status == TaskStatus.running).length;
  int get readyCount => tasks.where((task) => task.status == TaskStatus.ready).length;
  int get blockedCount => tasks.where((task) => task.status == TaskStatus.blocked).length;
  int get waitingCount => tasks
      .where((task) => task.status == TaskStatus.waiting || task.status == TaskStatus.blocked)
      .length;
  int get unfinishedCount => tasks.where((task) => !task.isTerminal).length;

  KitchenTask? taskById(String id) {
    for (final task in tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  KitchenResource? resourceById(String id) {
    for (final resource in resources) {
      if (resource.id == id) return resource;
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'title': title,
        'mode': mode.name,
        'status': status.name,
        'timingMode': timingMode.name,
        'targetReadyAtEpochMs': targetReadyAtEpochMs,
        'targetTimeZoneId': targetTimeZoneId,
        'sourceType': sourceType,
        'originalText': originalText,
        'referenceUrl': referenceUrl,
        'note': note,
        'handoffNote': handoffNote,
        'tasks': tasks.map((task) => task.toJson()).toList(),
        'stationItems': stationItems.map((item) => item.toJson()).toList(),
        'resources': resources.map((resource) => resource.toJson()).toList(),
        'createdAtEpochMs': createdAtEpochMs,
        'updatedAtEpochMs': updatedAtEpochMs,
        'endedAtEpochMs': endedAtEpochMs,
        'endReason': endReason,
      };

  factory KitchenBoard.fromJson(Map<String, Object?> json) => KitchenBoard(
        id: '${json['id'] ?? ''}',
        title: '${json['title'] ?? ''}',
        mode: _enumByName(BoardMode.values, json['mode'], BoardMode.home),
        status: _enumByName(BoardStatus.values, json['status'], BoardStatus.draft),
        timingMode: _enumByName(TimingMode.values, json['timingMode'], TimingMode.startNow),
        targetReadyAtEpochMs: json['targetReadyAtEpochMs'] == null
            ? null
            : _asInt(json['targetReadyAtEpochMs']),
        targetTimeZoneId: '${json['targetTimeZoneId'] ?? ''}',
        sourceType: '${json['sourceType'] ?? 'manual'}',
        originalText: _asNullableString(json['originalText']),
        referenceUrl: _asNullableString(json['referenceUrl']),
        note: _asNullableString(json['note']),
        handoffNote: _asNullableString(json['handoffNote']),
        tasks: _list(json['tasks']).map(_stringMap).map(KitchenTask.fromJson).toList(),
        stationItems:
            _list(json['stationItems']).map(_stringMap).map(StationItem.fromJson).toList(),
        resources:
            _list(json['resources']).map(_stringMap).map(KitchenResource.fromJson).toList(),
        createdAtEpochMs: _asInt(json['createdAtEpochMs']),
        updatedAtEpochMs: _asInt(json['updatedAtEpochMs']),
        endedAtEpochMs:
            json['endedAtEpochMs'] == null ? null : _asInt(json['endedAtEpochMs']),
        endReason: _asNullableString(json['endReason']),
      );

  KitchenBoard duplicate({required String newId, required int nowEpochMs}) {
    final taskIdMap = <String, String>{
      for (var i = 0; i < tasks.length; i++) tasks[i].id: '${newId}_task_$i',
    };
    final resourceIdMap = <String, String>{
      for (var i = 0; i < resources.length; i++) resources[i].id: '${newId}_resource_$i',
    };
    return KitchenBoard(
      id: newId,
      title: title,
      mode: mode,
      timingMode: timingMode,
      targetTimeZoneId: targetTimeZoneId,
      sourceType: 'duplicate',
      createdAtEpochMs: nowEpochMs,
      updatedAtEpochMs: nowEpochMs,
      tasks: <KitchenTask>[
        for (final task in tasks)
          task.duplicate(
            newId: taskIdMap[task.id]!,
            taskIdMap: taskIdMap,
            resourceIdMap: resourceIdMap,
          ),
      ],
      stationItems: <StationItem>[
        for (var i = 0; i < stationItems.length; i++)
          stationItems[i].duplicate(newId: '${newId}_item_$i'),
      ],
      resources: <KitchenResource>[
        for (var i = 0; i < resources.length; i++)
          resources[i].duplicate(newId: resourceIdMap[resources[i].id]!),
      ],
    );
  }
}

class KitchenTemplate {
  KitchenTemplate({
    required this.id,
    required this.title,
    required this.board,
    required this.createdAtEpochMs,
    required this.updatedAtEpochMs,
  });

  final String id;
  String title;
  KitchenBoard board;
  final int createdAtEpochMs;
  int updatedAtEpochMs;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'title': title,
        'board': board.toJson(),
        'createdAtEpochMs': createdAtEpochMs,
        'updatedAtEpochMs': updatedAtEpochMs,
      };

  factory KitchenTemplate.fromJson(Map<String, Object?> json) => KitchenTemplate(
        id: '${json['id'] ?? ''}',
        title: '${json['title'] ?? ''}',
        board: KitchenBoard.fromJson(_stringMap(json['board'])),
        createdAtEpochMs: _asInt(json['createdAtEpochMs']),
        updatedAtEpochMs: _asInt(json['updatedAtEpochMs']),
      );
}

class KitchenSnapshot {
  KitchenSnapshot({
    required this.schemaVersion,
    required this.boards,
    List<KitchenTemplate>? templates,
    Map<String, int>? catalogueUsage,
    this.activeBoardId,
    this.languageOverride,
    this.regionOverride,
    this.timerAlertsEnabled = false,
    this.keepScreenAwake = false,
    this.unitSystem = 'auto',
    this.temperatureUnit = 'auto',
    this.lastMode = BoardMode.home,
  })  : templates = templates ?? <KitchenTemplate>[],
        catalogueUsage = catalogueUsage ?? <String, int>{};

  static const currentSchemaVersion = 3;
  final int schemaVersion;
  final List<KitchenBoard> boards;
  final List<KitchenTemplate> templates;
  final Map<String, int> catalogueUsage;
  String? activeBoardId;
  String? languageOverride;
  String? regionOverride;
  bool timerAlertsEnabled;
  bool keepScreenAwake;
  String unitSystem;
  String temperatureUnit;
  BoardMode lastMode;

  KitchenBoard? get activeBoard {
    final id = activeBoardId;
    if (id == null) return null;
    for (final board in boards) {
      if (board.id == id && board.isActive) return board;
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': currentSchemaVersion,
        'activeBoardId': activeBoardId,
        'languageOverride': languageOverride,
        'regionOverride': regionOverride,
        'timerAlertsEnabled': timerAlertsEnabled,
        'keepScreenAwake': keepScreenAwake,
        'unitSystem': unitSystem,
        'temperatureUnit': temperatureUnit,
        'lastMode': lastMode.name,
        'catalogueUsage': catalogueUsage,
        'boards': boards.map((board) => board.toJson()).toList(),
        'templates': templates.map((template) => template.toJson()).toList(),
      };

  String encode() => jsonEncode(toJson());

  factory KitchenSnapshot.empty() => KitchenSnapshot(
        schemaVersion: currentSchemaVersion,
        boards: <KitchenBoard>[],
      );

  factory KitchenSnapshot.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Kitchen snapshot must be an object.');
    }
    final json = _stringMap(decoded);
    final version = _asInt(json['schemaVersion'], 1);
    if (version > currentSchemaVersion) {
      throw FormatException('Unsupported future schema version $version.');
    }
    final usageRaw = _stringMap(json['catalogueUsage']);
    return KitchenSnapshot(
      schemaVersion: currentSchemaVersion,
      activeBoardId: _asNullableString(json['activeBoardId']),
      languageOverride: _asNullableString(json['languageOverride']),
      regionOverride: _asNullableString(json['regionOverride']),
      timerAlertsEnabled: json['timerAlertsEnabled'] == true,
      keepScreenAwake: json['keepScreenAwake'] == true,
      unitSystem: '${json['unitSystem'] ?? 'auto'}',
      temperatureUnit: '${json['temperatureUnit'] ?? 'auto'}',
      lastMode: _enumByName(BoardMode.values, json['lastMode'], BoardMode.home),
      catalogueUsage: <String, int>{
        for (final entry in usageRaw.entries) entry.key: _asInt(entry.value),
      },
      boards: _list(json['boards']).map(_stringMap).map(KitchenBoard.fromJson).toList(),
      templates:
          _list(json['templates']).map(_stringMap).map(KitchenTemplate.fromJson).toList(),
    );
  }
}
