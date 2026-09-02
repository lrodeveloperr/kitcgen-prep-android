from pathlib import Path
import re

shell = Path('lib/features/kitchen_shell.dart')
text = shell.read_text()

# Keep Android presentation unchanged. All premium behavior is guarded by the
# existing _usesCalmWorkbench() iOS/macOS condition.
colors_old = '''abstract final class _WorkbenchColors {
  static const sage = Color(0xFF315D4B);
  static const sageSoft = Color(0xFFDDE9E1);
  static const paper = Color(0xFFFFFCF5);
  static const charcoal = Color(0xFF1F2B26);
  static const orange = Color(0xFFE6843D);
  static const orangeSoft = Color(0xFFFFE5D2);
  static const line = Color(0xFFE1E5DD);
  static const muted = Color(0xFF65706A);
}'''
colors_new = '''abstract final class _WorkbenchColors {
  static const sage = Color(0xFF315D4B);
  static const sageDeep = Color(0xFF173A2F);
  static const sageSoft = Color(0xFFDDE9E1);
  static const paper = Color(0xFFFFFEFA);
  static const canvas = Color(0xFFF4F1E8);
  static const charcoal = Color(0xFF17231F);
  static const orange = Color(0xFFE6843D);
  static const orangeSoft = Color(0xFFFFE5D2);
  static const gold = Color(0xFFD3A443);
  static const line = Color(0xFFDCE1D9);
  static const muted = Color(0xFF65706A);
  static const shadow = Color(0x24182B24);
}'''
if colors_old in text:
    text = text.replace(colors_old, colors_new)
elif colors_new not in text:
    raise SystemExit('Unexpected workbench color block')

# Replace the large iOS navigation title that pushed useful content down the screen.
frame_start = text.index('class PageFrame extends StatelessWidget {')
frame_end = text.index('\nclass HomePage extends StatelessWidget {', frame_start)
old_frame = text[frame_start:frame_end]
if 'SliverAppBar.large' not in old_frame and 'compactHeight' not in old_frame:
    raise SystemExit('Unexpected PageFrame implementation')
new_frame = r'''class PageFrame extends StatelessWidget {
  const PageFrame({required this.title, required this.child, this.action, super.key});
  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    if (!_usesCalmWorkbench(context)) {
      return SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  title: Text(title),
                  actions: action == null ? null : [action!],
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverToBoxAdapter(child: child),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final media = MediaQuery.of(context);
    final compactHeight = media.size.height <= 700;
    final compactWidth = media.size.width <= 360;
    final horizontal = compactWidth ? 14.0 : 18.0;
    final titleStyle = (compactHeight
            ? Theme.of(context).textTheme.titleLarge
            : Theme.of(context).textTheme.headlineSmall)
        ?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.45,
      color: _WorkbenchColors.charcoal,
    );

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    compactHeight ? 8 : 12,
                    horizontal,
                    compactHeight ? 10 : 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                      ),
                      if (action != null) ...[
                        const SizedBox(width: 10),
                        action!,
                      ],
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 20),
                sliver: SliverToBoxAdapter(child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
'''
text = text[:frame_start] + new_frame + text[frame_end:]

# Premium iOS empty-state / hero surface. Android branch remains untouched.
text = text.replace(
'''                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  color: _WorkbenchColors.paper,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _WorkbenchColors.line),
                ),''',
'''                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.sizeOf(context).height <= 700 ? 18 : 22,
                  20,
                  20,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFFEFA), Color(0xFFF0F5F1)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _WorkbenchColors.line),
                  boxShadow: const [
                    BoxShadow(
                      color: _WorkbenchColors.shadow,
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),''',
1,
)
text = text.replace(
'''                        width: 88,
                        height: 88,''',
'''                        width: MediaQuery.sizeOf(context).height <= 700 ? 62 : 74,
                        height: MediaQuery.sizeOf(context).height <= 700 ? 62 : 74,''',
1,
)

# Add depth to the active-board summary while preserving its data and actions.
active_old = '''          color: _WorkbenchColors.paper,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _WorkbenchColors.line),'''
active_new = '''          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFEFA), Color(0xFFF0F5F1)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _WorkbenchColors.line),
          boxShadow: const [
            BoxShadow(
              color: _WorkbenchColors.shadow,
              blurRadius: 22,
              offset: Offset(0, 9),
            ),
          ],'''
if active_old in text:
    text = text.replace(active_old, active_new, 1)

# Avoid squeezing four metrics into an unreadable row on 320/375pt widths.
metric_re = re.compile(r'''            Row\(\n              children: \[\n                Expanded\(\n                  child: _LaneMetric\(\n                    label: s\.t\('now'\),.*?                \),\n              \],\n            \),''', re.S)
metric_new = r'''            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 350 ? 2 : 4;
                final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: width,
                      child: _LaneMetric(
                        label: s.t('now'),
                        value: now,
                        color: _WorkbenchColors.orange,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _LaneMetric(
                        label: s.t('next'),
                        value: next,
                        color: _WorkbenchColors.sage,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _LaneMetric(
                        label: s.t('waiting'),
                        value: waiting,
                        color: _WorkbenchColors.muted,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _LaneMetric(
                        label: s.t('done'),
                        value: board.doneCount,
                        color: const Color(0xFF6E8C65),
                      ),
                    ),
                  ],
                );
              },
            ),'''
text, replaced = metric_re.subn(metric_new, text, count=1)
if replaced == 0 and 'final columns = constraints.maxWidth < 350 ? 2 : 4;' not in text:
    raise SystemExit('Active summary metric row not found')

# Premium grocery-selection rows: clearer selected state, tactile surfaces, no added taps.
old_rows = '''          for (final item in filtered)
            CheckboxListTile(
              value: selected.contains(item.id),
              title: Text(item.display(locale)),
              dense: true,
              onChanged: (_) => setState(() {
                selected.contains(item.id)
                    ? selected.remove(item.id)
                    : selected.add(item.id);
              }),
            ),'''
new_rows = '''          for (final item in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: _usesCalmWorkbench(context)
                    ? (selected.contains(item.id)
                        ? _WorkbenchColors.sageSoft.withValues(alpha: 0.78)
                        : _WorkbenchColors.paper)
                    : Colors.transparent,
                elevation: _usesCalmWorkbench(context) ? 1.0 : 0,
                shadowColor: _WorkbenchColors.shadow,
                borderRadius: BorderRadius.circular(16),
                child: CheckboxListTile(
                  value: selected.contains(item.id),
                  title: Text(
                    item.display(locale),
                    style: TextStyle(
                      fontWeight: _usesCalmWorkbench(context)
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onChanged: (_) => setState(() {
                    selected.contains(item.id)
                        ? selected.remove(item.id)
                        : selected.add(item.id);
                  }),
                ),
              ),
            ),'''
if old_rows in text:
    text = text.replace(old_rows, new_rows, 1)

# Make the live-board lane control feel like a timeline/workbench, but keep lane logic unchanged.
lanes_old = '''    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _WorkbenchColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _WorkbenchColors.line),
      ),'''
lanes_new = '''    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFEFA), Color(0xFFF3F7F4)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _WorkbenchColors.line),
        boxShadow: const [
          BoxShadow(
            color: _WorkbenchColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),'''
if lanes_old in text:
    text = text.replace(lanes_old, lanes_new, 1)

# Turn the active timer in the iOS task card into a visual hero while keeping all timer semantics.
needle = '''    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 4, 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _WorkbenchColors.line),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),'''
replacement = '''    final totalMs = task.durationSeconds == null
        ? 0
        : task.durationSeconds! * 1000;
    final progress = totalMs <= 0
        ? 0.0
        : (reading.remainingMs / totalMs).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 4, 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _WorkbenchColors.line),
        ),
      ),
      child: Row(
        children: [
          if (isRunning && task.deadlineEpochMs != null)
            SizedBox(
              width: 34,
              height: 34,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3.5,
                    backgroundColor: _WorkbenchColors.orangeSoft,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      _WorkbenchColors.orange,
                    ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.timer_outlined,
                      size: 15,
                      color: _WorkbenchColors.orange,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),'''
if needle in text:
    text = text.replace(needle, replacement, 1)

shell.write_text(text)

# iOS-only theme polish. Android theme branch remains exactly as-is.
main = Path('lib/main.dart')
m = main.read_text()
m = m.replace(
'''            cardTheme: CardThemeData(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: useIOSWorkbench
                  ? const Color(0xFFFFFCF5)
                  : colors.surfaceContainerLow,''',
'''            cardTheme: CardThemeData(
              margin: EdgeInsets.zero,
              elevation: useIOSWorkbench ? 2.5 : 0,
              shadowColor: const Color(0x26182B24),
              color: useIOSWorkbench
                  ? const Color(0xFFFFFEFA)
                  : colors.surfaceContainerLow,'''
)
m = m.replace(
'''            navigationBarTheme: NavigationBarThemeData(
              height: useIOSWorkbench ? 68 : 80,''',
'''            navigationBarTheme: NavigationBarThemeData(
              height: useIOSWorkbench ? 62 : 80,'''
)
main.write_text(m)

# Scaling contract: tests the actual compact frame with banner + nav pressure.
test = Path('test/ios_premium_scaling_contract_test.dart')
test.write_text(r'''import 'package:flutter/material.dart';
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
          home: const Scaffold(
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
''')
