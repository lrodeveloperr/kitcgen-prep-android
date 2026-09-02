import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_prep_board/application/kitchen_controller.dart';
import 'package:kitchen_prep_board/data/kitchen_store.dart';
import 'package:kitchen_prep_board/domain/kitchen_models.dart';
import 'package:kitchen_prep_board/features/kitchen_shell.dart';
import 'package:kitchen_prep_board/l10n/kitchen_strings.dart';
import 'package:kitchen_prep_board/services/timer_notifications.dart';

class _MemoryStore implements KitchenStore {
  KitchenSnapshot snapshot = KitchenSnapshot.empty();

  @override
  Future<void> clear() async => snapshot = KitchenSnapshot.empty();

  @override
  Future<KitchenSnapshot> load() async => snapshot;

  @override
  Future<void> save(KitchenSnapshot value) async {
    snapshot = KitchenSnapshot.decode(value.encode());
  }
}

class _SilentNotifications extends TimerNotifications {
  @override
  Future<void> cancel(KitchenTask task) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(KitchenTask task, KitchenStrings strings) async {}
}

Future<({KitchenController controller, KitchenBoard board})>
    _oceanPearlFixture() async {
  final controller = KitchenController(
    store: _MemoryStore(),
    notifications: _SilentNotifications(),
  );
  final board = await controller.createDraft(
    title: 'Dinner Prep',
    mode: BoardMode.home,
    taskNames: const [
      'Chop onions',
      'Heat pan',
      'Add tomatoes',
      'Boil rice',
      'Wash vegetables',
    ],
  );
  final now = DateTime.now().millisecondsSinceEpoch;
  board.status = BoardStatus.active;
  board.tasks[0]
    ..status = TaskStatus.running
    ..durationSeconds = 600
    ..startedAtEpochMs = now - 328000
    ..deadlineEpochMs = now + 272000;
  board.tasks[1].status = TaskStatus.ready;
  board.tasks[2].status = TaskStatus.ready;
  board.tasks[3].status = TaskStatus.waiting;
  board.tasks[4]
    ..status = TaskStatus.done
    ..endedAtEpochMs = now - 60000;
  return (controller: controller, board: board);
}

Widget _testApp(
  KitchenController controller,
  KitchenBoard board, {
  double textScale = 1,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: const Color(0xFF247BD1),
      scaffoldBackgroundColor: const Color(0xFFEEF6FF),
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: RepaintBoundary(
      key: const Key('ocean-pearl-capture'),
      child: LiveBoardPage(controller: controller, board: board),
    ),
  );
}

void main() {
  const viewports = <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(375, 667),
    Size(390, 844),
    Size(430, 932),
    Size(600, 960),
    Size(768, 1024),
    Size(834, 1194),
    Size(1024, 1366),
    Size(1280, 800),
    Size(844, 390),
  ];

  for (final size in viewports) {
    testWidgets(
      'Ocean Pearl fits ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final fixture = await _oceanPearlFixture();
        addTearDown(fixture.controller.dispose);

        await tester.pumpWidget(
          _testApp(fixture.controller, fixture.board),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('Dinner Prep'), findsOneWidget);
        expect(find.text('Chop onions'), findsOneWidget);
        for (final finder in <Finder>[
          find.byType(IconButton),
          find.byType(FilledButton),
          find.byType(OutlinedButton),
        ]) {
          for (var i = 0; i < finder.evaluate().length; i++) {
            final size = tester.getSize(finder.at(i));
            expect(size.width, greaterThanOrEqualTo(44));
            expect(size.height, greaterThanOrEqualTo(44));
          }
        }
      },
    );
  }

  for (final size in const [Size(320, 568), Size(390, 844), Size(768, 1024)]) {
    testWidgets(
      'Ocean Pearl supports large text at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final fixture = await _oceanPearlFixture();
        addTearDown(fixture.controller.dispose);

        await tester.pumpWidget(
          _testApp(fixture.controller, fixture.board, textScale: 1.8),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('Chop onions'), findsOneWidget);
      },
    );
  }

  testWidgets('captures the selected Ocean Pearl target for visual QA',
      (tester) async {
    const capture = bool.fromEnvironment('CAPTURE_OCEAN_PEARL');
    if (!capture) return;
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final fixture = await _oceanPearlFixture();
    addTearDown(fixture.controller.dispose);
    await tester.pumpWidget(_testApp(fixture.controller, fixture.board));
    await tester.pump();
    await expectLater(
      find.byKey(const Key('ocean-pearl-capture')),
      matchesGoldenFile('goldens/ocean_pearl_phone.png'),
    );
  });

  testWidgets('PressBench bottom bar changes all four destinations',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final fixture = await _oceanPearlFixture();
    addTearDown(fixture.controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorSchemeSeed: const Color(0xFF247BD1),
          scaffoldBackgroundColor: const Color(0xFFEEF6FF),
        ),
        home: KitchenShell(controller: fixture.controller),
      ),
    );
    await tester.pump();

    for (final destination in const ['Boards', 'New', 'Settings', 'Home']) {
      await tester.tap(find.bySemanticsLabel(destination));
      await tester.pump();
      if (destination == 'Home') {
        expect(find.text('Kitchen Prep Board'), findsOneWidget);
      } else {
        expect(find.text(destination), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    }
  });
}
