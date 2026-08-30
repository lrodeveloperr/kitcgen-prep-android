import 'dart:io';

import 'package:kitchen_prep_board/domain/kitchen_models.dart';
import 'package:path_provider/path_provider.dart';

abstract interface class KitchenStore {
  Future<KitchenSnapshot> load();
  Future<void> save(KitchenSnapshot snapshot);
  Future<void> clear();
}

class AtomicFileKitchenStore implements KitchenStore {
  static const _fileName = 'kitchen_prep_board_v2.json';
  static const _backupName = 'kitchen_prep_board_v2.backup.json';

  Future<Directory> _directory() => getApplicationSupportDirectory();

  Future<File> _file(String name) async => File('${(await _directory()).path}/$name');

  @override
  Future<KitchenSnapshot> load() async {
    final primary = await _file(_fileName);
    final backup = await _file(_backupName);
    for (final candidate in <File>[primary, backup]) {
      try {
        if (await candidate.exists()) {
          return KitchenSnapshot.decode(await candidate.readAsString());
        }
      } on Object {
        // Try the next recoverable copy. The controller surfaces a clean empty
        // state only when neither persisted copy can be read.
      }
    }
    return KitchenSnapshot.empty();
  }

  @override
  Future<void> save(KitchenSnapshot snapshot) async {
    final directory = await _directory();
    await directory.create(recursive: true);
    final primary = File('${directory.path}/$_fileName');
    final backup = File('${directory.path}/$_backupName');
    final temporary = File('${directory.path}/$_fileName.tmp');

    await temporary.writeAsString(snapshot.encode(), flush: true);
    if (await primary.exists()) {
      await primary.copy(backup.path);
    }
    if (await primary.exists()) await primary.delete();
    await temporary.rename(primary.path);
  }

  @override
  Future<void> clear() async {
    for (final name in <String>[_fileName, _backupName, '$_fileName.tmp']) {
      final file = await _file(name);
      if (await file.exists()) await file.delete();
    }
  }
}
