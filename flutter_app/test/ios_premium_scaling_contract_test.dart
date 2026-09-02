import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_prep_board/features/kitchen_shell.dart';

void main() {
  const viewports = <Size>[
    Size(320, 568),
    Size(375, 667),
    Size(390, 844),
    Size(430, 932),
    Size(768, 1024),
    Size(1024, 1366),
  ];

  for (final size in viewports) {
    testWidgets('iOS premium frame fits ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: PageFrame(
                    title: 'Kitchen Prep',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Dinner prep'),
                                SizedBox(height: 8),
                                Text('2 now · 3 waiting · 4 next'),
                                SizedBox(height: 10),
                                FilledButton(onPressed: null, child: Text('Continue')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 50),
                NavigationBar(
                  destinations: [
                    NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                    NavigationDestination(icon: Icon(Icons.view_list), label: 'Boards'),
                    NavigationDestination(icon: Icon(Icons.add), label: 'New'),
                    NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Kitchen Prep'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });
  }
}
