import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kitchen_prep_board/application/kitchen_controller.dart';
import 'package:kitchen_prep_board/catalogue/kitchen_catalogue.dart';
import 'package:kitchen_prep_board/domain/kitchen_models.dart';
import 'package:kitchen_prep_board/domain/scheduling_engine.dart';
import 'package:kitchen_prep_board/domain/timer_logic.dart';
import 'package:kitchen_prep_board/features/banner_slot.dart';
import 'package:kitchen_prep_board/l10n/kitchen_strings.dart';

KitchenStrings _s(BuildContext context) => KitchenStrings(Localizations.localeOf(context));

bool _usesCommandRail(BuildContext context) =>
    Theme.of(context).brightness == Brightness.light;

abstract final class _WorkbenchColors {
  static const paper = Color(0xFFFFFFFF);
  static const charcoal = Color(0xFF163451);
  static const orange = Color(0xFF247BD1);
  static const orangeDeep = Color(0xFF1769BA);
  static const orangeSoft = Color(0xFFE7F3FF);
  static const blue = Color(0xFF247BD1);
  static const olive = Color(0xFF278E67);
  static const oliveSoft = Color(0xFFE7F6EF);
  static const line = Color(0xFFD7E6F3);
  static const muted = Color(0xFF526D89);
  static const shadow = Color(0x122F5E8B);
}

IconData _categoryIcon(GroceryCategory category) => switch (category) {
      GroceryCategory.produce => Icons.eco_outlined,
      GroceryCategory.meatPoultry => Icons.outdoor_grill_outlined,
      GroceryCategory.seafood => Icons.set_meal_outlined,
      GroceryCategory.dairyEggs => Icons.egg_alt_outlined,
      GroceryCategory.bakeryGrains => Icons.rice_bowl_outlined,
      GroceryCategory.pantry => Icons.shelves,
      GroceryCategory.frozen => Icons.ac_unit_rounded,
      GroceryCategory.beverages => Icons.local_drink_outlined,
      GroceryCategory.herbsSpices => Icons.grass_outlined,
      GroceryCategory.other => Icons.restaurant_menu_rounded,
    };

IconData _taskProcessIcon(KitchenTask task) {
  final name = task.name.toLowerCase();
  bool hasAny(Iterable<String> terms) => terms.any(name.contains);

  if (hasAny(const [
    'wash', 'rinse', 'lavar', 'enjuag', 'rincer', 'laver', 'waschen',
    'spülen', 'lavare', 'sciacqu', 'غسل', 'شطف', '洗', 'すす', '씻',
  ])) {
    return Icons.water_drop_outlined;
  }
  if (hasAny(const [
    'chop', 'slice', 'dice', 'mince', 'cut', 'picar', 'cortar', 'reban',
    'couper', 'hach', 'éminc', 'schneid', 'hack', 'tagli', 'trit',
    'قطع', 'فرم', '切', '刻', '썰', '다지',
  ])) {
    return Icons.restaurant_rounded;
  }
  if (hasAny(const [
    'boil', 'simmer', 'cook', 'heat', 'warm', 'herv', 'cocer', 'cocinar',
    'ferver', 'cozin', 'bouillir', 'mijot', 'cuire', 'koch', 'erhitz',
    'boll', 'cuoc', 'غلي', 'طبخ', 'سخن', '煮', '加熱', '끓', '익히',
  ])) {
    return Icons.soup_kitchen_outlined;
  }
  if (hasAny(const [
    'bake', 'roast', 'grill', 'fry', 'horne', 'asar', 'freír', 'assar',
    'frit', 'rôt', 'back', 'brat', 'forn', 'frig', 'خبز', 'شوي', 'قلي',
    '焼', '튀', '굽',
  ])) {
    return Icons.outdoor_grill_outlined;
  }
  if (hasAny(const [
    'mix', 'stir', 'whisk', 'blend', 'mezcl', 'remov', 'bater', 'mistur',
    'mélang', 'fouett', 'rühr', 'misch', 'mescol', 'sbatt', 'خلط', 'مزج',
    '混', '섞', '젓',
  ])) {
    return Icons.blender_outlined;
  }
  if (hasAny(const [
    'wait', 'rest', 'cool', 'marinat', 'esper', 'repos', 'enfri', 'aguard',
    'descans', 'refroid', 'attendre', 'ruh', 'abkühl', 'riposa', 'raffredd',
    'انتظر', 'راحة', 'برد', '待', '休', '식히', '기다',
  ])) {
    return Icons.hourglass_top_rounded;
  }
  if (hasAny(const [
    'serve', 'plate', 'servir', 'emplat', 'dresser', 'anricht', 'impiatt',
    'قدم', 'تقديم', '盛', '내기',
  ])) {
    return Icons.dinner_dining_outlined;
  }

  final sourceId = task.sourceItemId;
  if (sourceId != null) {
    for (final item in kitchenCatalogue) {
      if (item.id == sourceId) return _categoryIcon(item.category);
    }
  }
  return Icons.checklist_rounded;
}

Future<bool> _runKitchenAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } on KitchenSaveException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s(context).t('saveFailed'))),
      );
    }
    return false;
  }
}

Future<T?> _runKitchenValue<T>(
  BuildContext context,
  Future<T> Function() action,
) async {
  try {
    return await action();
  } on KitchenSaveException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s(context).t('saveFailed'))),
      );
    }
    return null;
  }
}

class KitchenShell extends StatefulWidget {
  const KitchenShell({required this.controller, super.key});
  final KitchenController controller;

  @override
  State<KitchenShell> createState() => _KitchenShellState();
}

class _KitchenShellState extends State<KitchenShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final s = _s(context);
    final pages = <Widget>[
      HomePage(controller: widget.controller, onNew: () => setState(() => index = 2)),
      BoardsPage(controller: widget.controller),
      NewBoardPage(controller: widget.controller),
      SettingsPage(controller: widget.controller),
    ];
    final destinations = <NavigationDestination>[
      NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: s.t('home')),
      NavigationDestination(icon: const Icon(Icons.view_list_outlined), selectedIcon: const Icon(Icons.view_list), label: s.t('boards')),
      NavigationDestination(icon: const Icon(Icons.add_circle_outline), selectedIcon: const Icon(Icons.add_circle), label: s.t('new')),
      NavigationDestination(icon: const Icon(Icons.tune_outlined), selectedIcon: const Icon(Icons.tune), label: s.t('settings')),
    ];

    final content = Column(
      children: [
        Expanded(child: IndexedStack(index: index, children: pages)),
        if (!widget.controller.monetization.removeAds &&
            widget.controller.monetization.canRequestAds &&
            widget.controller.monetization.bannerAdUnitId != null)
          SafeArea(
            top: false,
            child: BannerSlot(service: widget.controller.monetization),
          ),
      ],
    );
    return Scaffold(
      body: content,
      bottomNavigationBar: _PressBenchBottomBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: destinations,
      ),
    );
  }
}

class _PressBenchBottomBar extends StatelessWidget {
  const _PressBenchBottomBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final direction = Directionality.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _WorkbenchColors.paper,
        border: Border(top: BorderSide(color: _WorkbenchColors.line)),
        boxShadow: [
          BoxShadow(
            color: _WorkbenchColors.shadow,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.35,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
              textDirection: direction,
              children: [
                for (var i = 0; i < destinations.length; i++)
                  Expanded(
                    child: _PressBenchDestination(
                      destination: destinations[i],
                      selected: selectedIndex == i,
                      onTap: () => onDestinationSelected(i),
                    ),
                  ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PressBenchDestination extends StatelessWidget {
  const _PressBenchDestination({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _WorkbenchColors.orange : _WorkbenchColors.muted;
    final icon = (selected ? destination.selectedIcon : destination.icon) ??
        const SizedBox.shrink();
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? _WorkbenchColors.orangeSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTheme(
                  data: IconThemeData(color: color, size: 25),
                  child: icon,
                ),
                const SizedBox(height: 3),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame({required this.title, required this.child, this.action, super.key});
  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compactHeight = media.size.height <= 700;
    final compactWidth = media.size.width <= 360;
    final tablet = media.size.width >= 720;
    final horizontal = compactWidth ? 14.0 : tablet ? 32.0 : 18.0;
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
          constraints: const BoxConstraints(maxWidth: 1180),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: _WorkbenchColors.paper,
                    border: Border(
                      bottom: BorderSide(
                        color: _WorkbenchColors.line,
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _WorkbenchColors.shadow,
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      compactHeight ? 7 : 10,
                      horizontal,
                      compactHeight ? 7 : 10,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.asset(
                            'kitchen_prep_mark.png',
                            width: compactHeight ? 38 : 44,
                            height: compactHeight ? 38 : 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
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
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24),
                sliver: SliverToBoxAdapter(child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({required this.controller, required this.onNew, super.key});
  final KitchenController controller;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final s = _s(context);
    final board = controller.activeBoard;
    final draft = controller.recoverableDraft;
    final calm = _usesCommandRail(context);
    return PageFrame(
      title: s.t('appName'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.expiredTaskIds.isNotEmpty) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.notification_important_outlined),
                title: Text(s.t('attention')),
                trailing: Text('${controller.expiredTaskIds.length}'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (board != null) ...[
            ActiveSummary(board: board),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _openLive(context, controller, board),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(s.t('continueBoard')),
            ),
          ] else if (draft != null) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.edit_note_outlined),
                title: Text(draft.title),
                subtitle: Text('${draft.tasks.length} ${s.t('tasks')}'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => BoardReviewPage(controller: controller, board: draft),
              )),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(s.t('continueDraft')),
            ),
          ] else ...[
            if (calm)
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.sizeOf(context).height <= 700 ? 18 : 22,
                  20,
                  20,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFFFFF), Color(0xFFF7FBFF)],
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
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'kitchen_prep_mark.png',
                        width: MediaQuery.sizeOf(context).height <= 700 ? 62 : 74,
                        height: MediaQuery.sizeOf(context).height <= 700 ? 62 : 74,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      s.t('noBoard'),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _WorkbenchColors.charcoal,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.t('trackQuantities'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _WorkbenchColors.muted,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.kitchen_outlined, size: 48),
                      const SizedBox(height: 12),
                      Text(s.t('noBoard'), style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add_rounded),
              label: Text(s.t('startBoard')),
            ),
          ],
          const SizedBox(height: 28),
          Text(s.t('recent'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (controller.snapshot.boards.where((b) => b.isTerminal).isEmpty)
            Text(s.t('noRecent'))
          else
            ...controller.snapshot.boards.where((b) => b.isTerminal).take(4).map(
              (b) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded),
                title: Text(b.title),
                subtitle: Text('${b.tasks.length} ${s.t('tasks')}'),
              ),
            ),
        ],
      ),
    );
  }
}

class ActiveSummary extends StatelessWidget {
  const ActiveSummary({required this.board, super.key});
  final KitchenBoard board;

  @override
  Widget build(BuildContext context) {
    final s = _s(context);
    final running =
        board.tasks.where((t) => t.status == TaskStatus.running).length;
    final ready = board.tasks.where((t) => t.status == TaskStatus.ready).length;
    final waiting = board.tasks
        .where((t) =>
            t.status == TaskStatus.waiting || t.status == TaskStatus.blocked)
        .length;
    final now = running > 0 ? running : (ready > 0 ? 1 : 0);
    final next =
        math.max(ready - (running == 0 && ready > 0 ? 1 : 0), 0).toInt();
    if (_usesCommandRail(context)) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF7FBFF)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _WorkbenchColors.line),
          boxShadow: const [
            BoxShadow(
              color: _WorkbenchColors.shadow,
              blurRadius: 22,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    board.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _WorkbenchColors.charcoal,
                        ),
                  ),
                ),
                if (board.status == BoardStatus.paused)
                  _StatusPill(
                    label: s.t('pausedBoard'),
                    color: _WorkbenchColors.orange,
                    background: _WorkbenchColors.orangeSoft,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
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
                        color: _WorkbenchColors.blue,
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
                        color: _WorkbenchColors.olive,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(board.title, style: Theme.of(context).textTheme.titleLarge),
            if (board.status == BoardStatus.paused) Text(s.t('pausedBoard')),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _Metric(label: s.t('now'), value: now)),
                Expanded(child: _Metric(label: s.t('waiting'), value: waiting)),
                Expanded(child: _Metric(label: s.t('next'), value: next)),
                Expanded(child: _Metric(label: s.t('done'), value: board.doneCount)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LaneMetric extends StatelessWidget {
  const _LaneMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _WorkbenchColors.muted,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text('$value', style: Theme.of(context).textTheme.headlineSmall),
          Text(label, textAlign: TextAlign.center),
        ],
      );
}

Future<void> _openLive(BuildContext context, KitchenController controller, KitchenBoard board) =>
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => LiveBoardPage(controller: controller, board: board),
    ));

class BoardsPage extends StatelessWidget {
  const BoardsPage({required this.controller, super.key});
  final KitchenController controller;

  @override
  Widget build(BuildContext context) {
    final s = _s(context);
    final boards = controller.snapshot.boards;
    final templates = controller.snapshot.templates;
    return PageFrame(
      title: s.t('boards'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (boards.isEmpty && templates.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(s.t('noBoard')),
              ),
            ),
          for (final board in boards)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  board.isActive
                      ? Icons.play_circle_outline
                      : Icons.checklist_rounded,
                ),
                title: Text(board.title),
                subtitle: Text('${board.tasks.length} ${s.t('tasks')}'),
                onTap: () {
                  if (board.isActive) {
                    _openLive(context, controller, board);
                  } else if (board.status == BoardStatus.draft) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BoardReviewPage(
                          controller: controller,
                          board: board,
                        ),
                      ),
                    );
                  }
                },
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'duplicate') {
                      await _runKitchenValue(
                        context,
                        () => controller.duplicateBoard(board),
                      );
                    } else if (value == 'delete') {
                      final ok = await _confirm(
                        context,
                        s.t('confirmDelete'),
                        s,
                        confirmLabel: s.t('delete'),
                      );
                      if (ok && !board.isActive) {
                        await _runKitchenAction(
                          context,
                          () => controller.deleteBoard(board),
                        );
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Text(s.t('duplicate')),
                    ),
                    if (!board.isActive)
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(s.t('delete')),
                      ),
                  ],
                ),
              ),
            ),
          if (templates.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(s.t('templates'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final template in templates)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.content_copy_outlined),
                  title: Text(template.title),
                  subtitle: Text('${template.board.tasks.length} ${s.t('tasks')}'),
                  onTap: () async {
                    final board = await _runKitchenValue(
                      context,
                      () => controller.createFromTemplate(template),
                    );
                    if (board == null || !context.mounted) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BoardReviewPage(
                          controller: controller,
                          board: board,
                        ),
                      ),
                    );
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final title = await _textDialog(
                          context,
                          s.t('edit'),
                          s,
                          initialValue: template.title,
                        );
                        if (title != null && title.trim().isNotEmpty) {
                          await _runKitchenAction(
                            context,
                            () => controller.renameTemplate(template, title),
                          );
                        }
                      } else if (value == 'duplicate') {
                        await _runKitchenValue(
                          context,
                          () => controller.duplicateTemplate(template),
                        );
                      } else if (value == 'delete') {
                        final ok = await _confirm(
                          context,
                          s.t('confirmDelete'),
                          s,
                          confirmLabel: s.t('delete'),
                        );
                        if (ok) {
                          await _runKitchenAction(
                            context,
                            () => controller.deleteTemplate(template),
                          );
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text(s.t('edit'))),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Text(s.t('duplicate')),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(s.t('delete')),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

Future<String?> _textDialog(
  BuildContext context,
  String title,
  KitchenStrings s, {
  String initialValue = '',
}) async {
  final controller = TextEditingController(text: initialValue);
  final value = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.t('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(s.t('done')),
        ),
      ],
    ),
  );
  controller.dispose();
  return value;
}

Future<bool> _confirm(
  BuildContext context,
  String message,
  KitchenStrings s, {
  required String confirmLabel,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;

class NewBoardPage extends StatefulWidget {
  const NewBoardPage({required this.controller, super.key});
  final KitchenController controller;

  @override
  State<NewBoardPage> createState() => _NewBoardPageState();
}

class _NewBoardPageState extends State<NewBoardPage> {
  final selected = <String>{};
  final custom = <String>[];
  String query = '';
  GroceryCategory? category;
  late BoardMode mode;

  @override
  void initState() {
    super.initState();
    mode = widget.controller.snapshot.lastMode;
  }

  @override
  Widget build(BuildContext context) {
    final s = _s(context);
    final locale = Localizations.localeOf(context);
    final allMatches = kitchenCatalogue
        .where((item) => item.matches(query, locale))
        .toList();
    final filtered = allMatches.where((item) {
      if (category != null && item.category != category) return false;
      return true;
    }).toList();
    final frequent = [...kitchenCatalogue]
      ..sort((a, b) {
        final count = (widget.controller.snapshot.catalogueUsage[b.id] ?? 0)
            .compareTo(widget.controller.snapshot.catalogueUsage[a.id] ?? 0);
        if (count != 0) return count;
        return a.display(locale).compareTo(b.display(locale));
      });
    final frequentItems = frequent
        .where((item) => (widget.controller.snapshot.catalogueUsage[item.id] ?? 0) > 0)
        .take(8)
        .toList();
    final selectedItems = [
      for (final item in kitchenCatalogue)
        if (selected.contains(item.id)) item,
    ];
    final count = selected.length + custom.length;

    return PageFrame(
      title: s.t('new'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.t('trackQuantities')),
          const SizedBox(height: 8),
          SegmentedButton<BoardMode>(
            segments: [
              ButtonSegment(
                value: BoardMode.home,
                label: Text(s.t('homeMode')),
                icon: const Icon(Icons.home_outlined),
              ),
              ButtonSegment(
                value: BoardMode.station,
                label: Text(s.t('stationMode')),
                icon: const Icon(Icons.restaurant_outlined),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (value) => setState(() => mode = value.first),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: s.t('search'),
            ),
            onChanged: (value) => setState(() => query = value),
          ),
          if (frequentItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(s.t('recent'), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in frequentItems)
                  FilterChip(
                    label: Text(item.display(locale)),
                    selected: selected.contains(item.id),
                    onSelected: (_) => setState(() {
                      selected.contains(item.id)
                          ? selected.remove(item.id)
                          : selected.add(item.id);
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Icon(Icons.apps_rounded),
                  selected: category == null,
                  onSelected: (_) => setState(() => category = null),
                ),
                const SizedBox(width: 8),
                for (final c in GroceryCategory.values) ...[
                  ChoiceChip(
                    label: Text(c.label(locale)),
                    selected: category == c,
                    onSelected: (_) => setState(
                      () => category = category == c ? null : c,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final item in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: _usesCommandRail(context)
                    ? (selected.contains(item.id)
                        ? _WorkbenchColors.orangeSoft
                        : _WorkbenchColors.paper)
                    : Colors.transparent,
                elevation: _usesCommandRail(context) ? 1.0 : 0,
                shadowColor: _WorkbenchColors.shadow,
                borderRadius: BorderRadius.circular(16),
                child: CheckboxListTile(
                  value: selected.contains(item.id),
                  secondary: Icon(
                    _categoryIcon(item.category),
                    color: selected.contains(item.id)
                        ? _WorkbenchColors.orange
                        : _WorkbenchColors.blue,
                  ),
                  title: Text(
                    item.display(locale),
                    style: TextStyle(
                      fontWeight: _usesCommandRail(context)
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
            ),
          if (query.trim().isNotEmpty && filtered.isEmpty) ...[
            if (category != null && allMatches.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => setState(() => category = null),
                icon: const Icon(Icons.search_rounded),
                label: Text(s.t('searchAll')),
              )
            else
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  final value = query.trim();
                  if (!custom.contains(value)) custom.add(value);
                  query = '';
                }),
                icon: const Icon(Icons.add),
                label: Text(s.t('customItem')),
              ),
          ],
          if (count > 0) ...[
            const SizedBox(height: 16),
            Text(s.t('selected'), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in selectedItems)
                  InputChip(
                    label: Text(item.display(locale)),
                    onDeleted: () => setState(() => selected.remove(item.id)),
                  ),
                for (final item in custom)
                  InputChip(
                    label: Text(item),
                    onDeleted: () => setState(() => custom.remove(item)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _createSelected(context, s, locale),
              child: Text('${s.t('addSelected')} ($count)'),
            ),
          ],
          const SizedBox(height: 16),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(s.t('more')),
            children: [
              ListTile(
                leading: const Icon(Icons.content_paste_outlined),
                title: Text(s.t('pasteTasks')),
                onTap: () => _pasteTasks(context, s),
              ),
              ListTile(
                leading: const Icon(Icons.link_outlined),
                title: Text(s.t('referenceUrl')),
                onTap: () => _referenceUrl(context, s),
              ),
              if (widget.controller.snapshot.templates.isNotEmpty) ...[
                const Divider(),
                for (final template in widget.controller.snapshot.templates)
                  ListTile(
                    leading: const Icon(Icons.copy_all_outlined),
                    title: Text(template.title),
                    subtitle: Text(
                      '${template.board.tasks.length} ${s.t('tasks')}',
                    ),
                    onTap: () async {
                      final board = await _runKitchenValue(
                        context,
                        () => widget.controller.createFromTemplate(template),
                      );
                      if (board == null || !context.mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BoardReviewPage(
                            controller: widget.controller,
                            board: board,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _createSelected(
    BuildContext context,
    KitchenStrings s,
    Locale locale,
  ) async {
    final chosen = [
      for (final item in kitchenCatalogue)
        if (selected.contains(item.id)) item,
    ];
    final names = <String>[...chosen.map((item) => item.display(locale)), ...custom];
    final now = DateTime.now();
    final title = '${s.t('boards')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
    final board = await _runKitchenValue(
      context,
      () => widget.controller.createDraft(
        title: title,
        mode: mode,
        taskNames: names,
        stationItemNames: mode == BoardMode.station ? names : const <String>[],
      ),
    );
    if (board == null) return;
    for (final item in chosen) {
      for (final task in board.tasks) {
        if (task.sourceItemId == null && task.name == item.display(locale)) {
          task.sourceItemId = item.id;
          break;
        }
      }
      for (final station in board.stationItems) {
        if (station.sourceItemId == null && station.name == item.display(locale)) {
          station.sourceItemId = item.id;
          break;
        }
      }
    }
    final usageSaved = await _runKitchenAction(
      context,
      () => widget.controller.recordCatalogueUse(chosen.map((item) => item.id)),
    );
    if (!usageSaved) return;
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BoardReviewPage(controller: widget.controller, board: board),
      ),
    );
    if (mounted) {
      setState(() {
        selected.clear();
        custom.clear();
      });
    }
  }

  Future<void> _pasteTasks(BuildContext context, KitchenStrings s) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('pasteTasks')),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 6,
          maxLines: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(s.t('review')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.trim().isEmpty || !context.mounted) return;
    final board = await _runKitchenValue(
      context,
      () => widget.controller.createDraftFromText(
        title: s.t('boards'),
        mode: mode,
        text: text,
      ),
    );
    if (board == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BoardReviewPage(controller: widget.controller, board: board),
      ),
    );
  }

  Future<void> _referenceUrl(BuildContext context, KitchenStrings s) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('referenceUrl')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(s.t('review')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (url == null || url.isEmpty || !context.mounted) return;
    final board = await _runKitchenValue(
      context,
      () => widget.controller.createDraft(
        title: s.t('boards'),
        mode: mode,
        taskNames: const <String>[],
        sourceType: 'referenceUrl',
        referenceUrl: url,
      ),
    );
    if (board == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BoardReviewPage(controller: widget.controller, board: board),
      ),
    );
  }
}

class BoardReviewPage extends StatefulWidget {
  const BoardReviewPage({required this.controller, required this.board, super.key});
  final KitchenController controller;
  final KitchenBoard board;

  @override
  State<BoardReviewPage> createState() => _BoardReviewPageState();
}

class _BoardReviewPageState extends State<BoardReviewPage> {
  final addController = TextEditingController();

  @override
  void dispose() {
    addController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _s(context);
    final board = widget.board;
    final schedule = widget.controller.scheduleFor(board);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('review'))),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (board.mode == BoardMode.station) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.t('trackQuantities'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: s.t('unit'),
                        icon: const Icon(Icons.straighten_outlined),
                        onSelected: (value) => _runKitchenAction(
                          context,
                          () => widget.controller.applyUnitToStationItems(board, value),
                        ),
                        itemBuilder: (_) => [
                          for (final unit in const [
                            'g', 'kg', 'oz', 'lb', 'ml', 'L', 'cup', 'tbsp', 'tsp', 'pcs'
                          ])
                            PopupMenuItem(value: unit, child: Text(unit)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final item in board.stationItems)
                    StationEditor(
                      controller: widget.controller,
                      board: board,
                      item: item,
                    ),
                  const SizedBox(height: 20),
                ],
                Text(s.t('tasks'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (board.tasks.isEmpty) Text(s.t('emptyTasks')),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: board.tasks.length,
                  onReorder: (oldIndex, newIndex) => _runKitchenAction(
                    context,
                    () => widget.controller.reorderTasks(board, oldIndex, newIndex),
                  ),
                  itemBuilder: (context, index) {
                    final task = board.tasks[index];
                    return Card(
                      key: ValueKey(task.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            TextFormField(
                              key: ValueKey('name_${task.id}'),
                              initialValue: task.name,
                              decoration: InputDecoration(labelText: s.t('taskName')),
                              onChanged: (value) => _runKitchenAction(
                                context,
                                () => widget.controller.updateTask(
                                  board,
                                  task,
                                  name: value,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: task.durationSeconds ?? 0,
                                    decoration: InputDecoration(labelText: s.t('timer')),
                                    items: [
                                      DropdownMenuItem(
                                        value: 0,
                                        child: Text(s.t('noTimer')),
                                      ),
                                      for (final minutes
                                          in const [5, 10, 15, 20, 30, 45, 60, 90])
                                        DropdownMenuItem(
                                          value: minutes * 60,
                                          child: Text('$minutes ${s.t('minutes')}'),
                                        ),
                                    ],
                                    onChanged: (value) => _runKitchenAction(
                                      context,
                                      () => widget.controller.updateTask(
                                        board,
                                        task,
                                        durationSeconds: value,
                                        clearDuration: value == 0,
                                        kind: value == 0
                                            ? TaskKind.step
                                            : TaskKind.singleTimer,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: s.t('duplicate'),
                                  onPressed: () => _runKitchenAction(
                                    context,
                                    () => widget.controller.duplicateTaskInDraft(board, task),
                                  ),
                                  icon: const Icon(Icons.copy_outlined),
                                ),
                                IconButton(
                                  tooltip: s.t('delete'),
                                  onPressed: () => _runKitchenAction(
                                    context,
                                    () => widget.controller.removeTaskFromDraft(board, task),
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                            ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: EdgeInsets.zero,
                              title: Text(s.t('more')),
                              children: [
                                DropdownButtonFormField<TaskPriority>(
                                  value: task.priority,
                                  decoration: InputDecoration(
                                    labelText: s.t('priority'),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: TaskPriority.none,
                                      child: Text(s.t('none')),
                                    ),
                                    DropdownMenuItem(
                                      value: TaskPriority.low,
                                      child: Text(s.t('low')),
                                    ),
                                    DropdownMenuItem(
                                      value: TaskPriority.normal,
                                      child: Text(s.t('normal')),
                                    ),
                                    DropdownMenuItem(
                                      value: TaskPriority.high,
                                      child: Text(s.t('high')),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      _runKitchenAction(
                                        context,
                                        () => widget.controller.updateTask(
                                          board,
                                          task,
                                          priority: value,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: task.dependencyIds.isEmpty
                                      ? ''
                                      : task.dependencyIds.first,
                                  decoration: InputDecoration(
                                    labelText: s.t('dependency'),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: '',
                                      child: Text(s.t('none')),
                                    ),
                                    for (final candidate in board.tasks)
                                      if (candidate.id != task.id)
                                        DropdownMenuItem(
                                          value: candidate.id,
                                          child: Text(candidate.name),
                                        ),
                                  ],
                                  onChanged: (value) async {
                                    try {
                                      await _runKitchenAction(
                                        context,
                                        () => widget.controller.updateTask(
                                          board,
                                          task,
                                          dependencyIds: value == null || value.isEmpty
                                              ? []
                                              : [value],
                                        ),
                                      );
                                    } on DependencyCycleException {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(s.t('attention'))),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: task.resourceRequirements.isEmpty
                                      ? ''
                                      : task.resourceRequirements.first.resourceId,
                                  decoration: InputDecoration(
                                    labelText: s.t('resource'),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: '',
                                      child: Text(s.t('none')),
                                    ),
                                    for (final resource in board.resources)
                                      DropdownMenuItem(
                                        value: resource.id,
                                        child: Text(resource.name),
                                      ),
                                  ],
                                  onChanged: (value) => _runKitchenAction(
                                    context,
                                    () => widget.controller.updateTask(
                                      board,
                                      task,
                                      resourceRequirements: value == null || value.isEmpty
                                          ? []
                                          : [
                                              TaskResourceRequirement(
                                                resourceId: value,
                                              ),
                                            ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: addController,
                        decoration: InputDecoration(labelText: s.t('taskName')),
                        onSubmitted: (_) => _add(context, board),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () => _add(context, board),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(s.t('resource')),
                  children: [
                    for (final resource in board.resources)
                      Card(
                        child: ListTile(
                          leading: Switch(
                            value: resource.available,
                            onChanged: (value) => _runKitchenAction(
                              context,
                              () => widget.controller.updateResource(
                                board,
                                resource,
                                available: value,
                              ),
                            ),
                          ),
                          title: Text(resource.name),
                          subtitle: Text('${s.t('capacity')}: ${resource.capacity}'),
                          trailing: PopupMenuButton<int>(
                            onSelected: (capacity) => _runKitchenAction(
                              context,
                              () => widget.controller.updateResource(
                                board,
                                resource,
                                capacity: capacity,
                              ),
                            ),
                            itemBuilder: (_) => [
                              for (final capacity in const [1, 2, 3, 4, 6, 8])
                                PopupMenuItem(
                                  value: capacity,
                                  child: Text('${s.t('capacity')}: $capacity'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: Text(s.t('addResource')),
                      onTap: () => _addResource(context, s),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(s.t('timing'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<TimingMode>(
                  segments: [
                    ButtonSegment(
                      value: TimingMode.startNow,
                      label: Text(s.t('startNow')),
                      icon: const Icon(Icons.play_arrow_rounded),
                    ),
                    ButtonSegment(
                      value: TimingMode.readyAt,
                      label: Text(s.t('readyAt')),
                      icon: const Icon(Icons.schedule_outlined),
                    ),
                  ],
                  selected: {board.timingMode},
                  onSelectionChanged: (value) async {
                    final mode = value.first;
                    if (mode == TimingMode.startNow) {
                      await _runKitchenAction(
                        context,
                        () => widget.controller.setTiming(
                          board,
                          mode: TimingMode.startNow,
                        ),
                      );
                    } else {
                      await _pickReadyAt(context, board, s);
                    }
                  },
                ),
                if (board.timingMode == TimingMode.readyAt) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(s.t('readyAt')),
                    subtitle: Text(_formatEpoch(context, board.targetReadyAtEpochMs)),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _pickReadyAt(context, board, s),
                  ),
                ],
                if (schedule != null) ...[
                  Card(
                    child: ListTile(
                      leading: Icon(
                        schedule.isLate ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      ),
                      title: Text(s.t('expectedFinish')),
                      subtitle: Text(
                        _formatEpoch(context, schedule.earliestFinishEpochMs),
                      ),
                      trailing: schedule.isLate
                          ? Text(
                              '${s.t('late')} '
                              '${(schedule.latenessMs / 60000).ceil()} ${s.t('minutes')}',
                            )
                          : null,
                    ),
                  ),
                ] else if (board.tasks.isNotEmpty) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_rounded),
                      title: Text(s.t('attention')),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: board.tasks.isEmpty
                      ? null
                      : () => _runKitchenValue(
                            context,
                            () => widget.controller.saveTemplate(board),
                          ),
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: Text(s.t('saveTemplate')),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: board.tasks.isEmpty || schedule == null
                      ? null
                      : () async {
                          try {
                            final saved = await _runKitchenAction(
                              context,
                              () => widget.controller.startBoard(board),
                            );
                            if (!saved) return;
                            if (!context.mounted) return;
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => LiveBoardPage(
                                  controller: widget.controller,
                                  board: board,
                                ),
                              ),
                            );
                          } on Object {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.t('attention'))),
                            );
                          }
                        },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(s.t('startBoard')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context, KitchenBoard board) async {
    final value = addController.text;
    final saved = await _runKitchenAction(
      context,
      () => widget.controller.addTaskToDraft(board, value),
    );
    if (saved) addController.clear();
  }

  Future<void> _addResource(BuildContext context, KitchenStrings s) async {
    final text = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('addResource')),
        content: TextField(controller: text, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, text.text),
            child: Text(s.t('done')),
          ),
        ],
      ),
    );
    text.dispose();
    if (value != null && value.trim().isNotEmpty) {
      await _runKitchenAction(
        context,
        () => widget.controller.addResource(widget.board, value),
      );
    }
  }

  Future<void> _pickReadyAt(
    BuildContext context,
    KitchenBoard board,
    KitchenStrings s,
  ) async {
    final now = DateTime.now();
    final initial = board.targetReadyAtEpochMs == null
        ? now.add(const Duration(hours: 1))
        : DateTime.fromMillisecondsSinceEpoch(board.targetReadyAtEpochMs!);
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: initial.isBefore(now) ? now : initial,
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    final target = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await _runKitchenAction(
      context,
      () => widget.controller.setTiming(
        board,
        mode: TimingMode.readyAt,
        targetReadyAtEpochMs: target.millisecondsSinceEpoch,
        timeZoneId: now.timeZoneName,
      ),
    );
  }
}

class StationEditor extends StatelessWidget {
  const StationEditor({
    required this.controller,
    required this.board,
    required this.item,
    super.key,
  });
  final KitchenController controller;
  final KitchenBoard board;
  final StationItem item;

  @override
  Widget build(BuildContext context) {
    final s = _s(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 150,
                  child: _NumberField(
                    label: s.t('have'),
                    value: item.have,
                    onValue: (value) => _runKitchenAction(
                      context,
                      () => controller.updateStationItem(
                        board,
                        item,
                        have: value,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: _NumberField(
                    label: s.t('par'),
                    value: item.par,
                    onValue: (value) => _runKitchenAction(
                      context,
                      () => controller.updateStationItem(
                        board,
                        item,
                        par: value,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: s.t('need')),
                    child: Text(_num(item.need)),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextFormField(
                    initialValue: item.unit,
                    decoration: InputDecoration(
                      labelText: s.t('unit'),
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (value) => _runKitchenAction(
                          context,
                          () => controller.updateStationItem(
                            board,
                            item,
                            unit: value,
                          ),
                        ),
                        itemBuilder: (_) => [
                          for (final unit in const [
                            'g', 'kg', 'oz', 'lb', 'ml', 'L', 'cup', 'tbsp', 'tsp', 'pcs'
                          ])
                            PopupMenuItem(value: unit, child: Text(unit)),
                        ],
                      ),
                    ),
                    onChanged: (value) => _runKitchenAction(
                      context,
                      () => controller.updateStationItem(board, item, unit: value),
                    ),
                  ),
                ),
              ],
            ),
            if (item.surplus > 0) ...[
              const SizedBox(height: 6),
              Text('+${_num(item.surplus)} ${item.unit}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onValue,
  });
  final String label;
  final double value;
  final ValueChanged<double> onValue;

  @override
  Widget build(BuildContext context) => TextFormField(
        initialValue: _num(value),
        decoration: InputDecoration(labelText: label),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (raw) {
          final normalized = raw.replaceAll(',', '.');
          final parsed = double.tryParse(normalized);
          if (parsed != null && parsed >= 0 && parsed.isFinite) onValue(parsed);
        },
      );
}

String _num(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);

String _formatEpoch(BuildContext context, int? epochMs) {
  if (epochMs == null) return '—';
  final date = DateTime.fromMillisecondsSinceEpoch(epochMs);
  final material = MaterialLocalizations.of(context);
  return '${material.formatMediumDate(date)} · '
      '${material.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
}

class LiveBoardPage extends StatelessWidget {
  const LiveBoardPage({
    required this.controller,
    required this.board,
    super.key,
  });
  final KitchenController controller;
  final KitchenBoard board;

  @override
  Widget build(BuildContext context) {
    final s = _s(context);
    if (_usesCommandRail(context)) {
      return _buildCommandRail(context, s);
    }
    return Scaffold(
      appBar: AppBar(title: Text(board.title)),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final liveTasks = board.tasks.where((task) => !task.isTerminal).toList();
          final terminalTasks = board.tasks.where((task) => task.isTerminal).toList();
          final next = board.tasks.where((task) => task.status == TaskStatus.ready).firstOrNull;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ActiveSummary(board: board),
                  if (controller.expiredTaskIds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.notification_important_outlined),
                        title: Text(s.t('attention')),
                        trailing: Text('${controller.expiredTaskIds.length}'),
                      ),
                    ),
                  ],
                  if (board.runningCount == 0 && next != null) ...[
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.arrow_forward_rounded),
                        title: Text(next.name),
                        subtitle: Text(s.t('next')),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (board.mode == BoardMode.station)
                    for (final item in board.stationItems)
                      LiveStationRow(
                        controller: controller,
                        board: board,
                        item: item,
                      ),
                  if (board.mode == BoardMode.station) const SizedBox(height: 12),
                  for (final task in liveTasks)
                    TaskActionCard(
                      controller: controller,
                      board: board,
                      task: task,
                    ),
                  if (terminalTasks.isNotEmpty)
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text('${s.t('done')} (${terminalTasks.length})'),
                      initiallyExpanded: terminalTasks.length <= 3,
                      children: [
                        for (final task in terminalTasks)
                          TaskActionCard(
                            controller: controller,
                            board: board,
                            task: task,
                          ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              if (board.status == BoardStatus.paused) {
                                await _runKitchenAction(
                                  context,
                                  () => controller.resumeBoard(board),
                                );
                              } else {
                                final ok = await _confirm(
                                  context,
                                  s.t('timersContinue'),
                                  s,
                                  confirmLabel: s.t('pauseNewTasks'),
                                );
                                if (ok) {
                                  await _runKitchenAction(
                                    context,
                                    () => controller.pauseBoard(board),
                                  );
                                }
                              }
                            },
                            icon: Icon(
                              board.status == BoardStatus.paused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                            ),
                            label: Text(
                              board.status == BoardStatus.paused
                                  ? s.t('resume')
                                  : s.t('pauseNewTasks'),
                            ),
                          ),
                          if (board.status == BoardStatus.paused)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(s.t('timersContinue')),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (board.unfinishedCount > 0)
                    OutlinedButton.icon(
                      onPressed: () => _handoff(context, s),
                      icon: const Icon(Icons.sync_alt_rounded),
                      label: Text(s.t('handoff')),
                    ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      final message = board.unfinishedCount == 0
                          ? s.t('closeCompleted')
                          : '${s.t('closeUnfinished')}: ${board.unfinishedCount}';
                      final ok = await _confirm(
                        context,
                        message,
                        s,
                        confirmLabel: board.unfinishedCount == 0
                            ? s.t('closeCompleted')
                            : s.t('closeUnfinished'),
                      );
                      if (!ok) return;
                      final messenger = ScaffoldMessenger.of(context);
                      final saved = await _runKitchenAction(
                        context,
                        () => controller.finishBoard(board),
                      );
                      if (!saved || !context.mounted) return;
                      Navigator.pop(context);
                      messenger.showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 10),
                          content: Text(s.t('saved')),
                          action: SnackBarAction(
                            label: s.t('undo'),
                            onPressed: () => _runKitchenValue(
                              messenger.context,
                              () => controller.undoLastFinish(s),
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.flag_outlined),
                    label: Text(
                      board.unfinishedCount == 0
                          ? s.t('closeCompleted')
                          : '${s.t('closeUnfinished')} (${board.unfinishedCount})',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommandRail(BuildContext context, KitchenStrings s) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'kitchen_prep_mark.png',
                width: 38,
                height: 38,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                board.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _WorkbenchColors.charcoal,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                ),
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: SizedBox(
            height: 1,
            width: double.infinity,
            child: ColoredBox(color: _WorkbenchColors.line),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: s.t('more'),
            onSelected: (value) {
              if (value == 'handoff') {
                _handoff(context, s);
              } else if (value == 'finish') {
                _finishCommandRailBoard(context, s);
              }
            },
            itemBuilder: (context) => [
              if (board.unfinishedCount > 0)
                PopupMenuItem(
                  value: 'handoff',
                  child: Text(s.t('handoff')),
                ),
              PopupMenuItem(
                value: 'finish',
                child: Text(
                  board.unfinishedCount == 0
                      ? s.t('closeCompleted')
                      : s.t('closeUnfinished'),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: !controller.monetization.removeAds &&
              controller.monetization.canRequestAds &&
              controller.monetization.bannerAdUnitId != null
          ? SafeArea(
              top: false,
              child: BannerSlot(service: controller.monetization),
            )
          : null,
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final running = board.tasks
              .where((task) => task.status == TaskStatus.running)
              .firstOrNull;
          final ready = board.tasks
              .where((task) => task.status == TaskStatus.ready)
              .firstOrNull;
          final focus = running ?? ready;
          final attention = controller.expiredTaskIds.isEmpty
              ? null
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _WorkbenchColors.orangeSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _WorkbenchColors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_rounded,
                        color: _WorkbenchColors.orange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.t('attention'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _WorkbenchColors.charcoal,
                          ),
                        ),
                      ),
                      Text(
                        '${controller.expiredTaskIds.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _WorkbenchColors.orange,
                        ),
                      ),
                    ],
                  ),
                );
          final hero = focus == null
              ? _AllClearPanel(board: board)
              : _ActiveTaskHero(
                  controller: controller,
                  board: board,
                  task: focus,
                );
          final lanes = _TaskLanes(
            controller: controller,
            board: board,
            focusTaskId: focus?.id,
          );
          final station = board.mode == BoardMode.station &&
                  board.stationItems.isNotEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      s.t('stationMode').toUpperCase(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: _WorkbenchColors.blue,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                    ),
                    const SizedBox(height: 8),
                    for (final item in board.stationItems)
                      LiveStationRow(
                        controller: controller,
                        board: board,
                        item: item,
                      ),
                  ],
                )
              : null;
          final controls = _BoardControlPanel(
            board: board,
            pauseOrResume: () => _pauseOrResumeBoard(context, s),
            handoff: () => _handoff(context, s),
            finish: () => _finishCommandRailBoard(context, s),
          );

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 820;
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(24, 20, 12, 28),
                            children: [
                              hero,
                              if (attention != null) ...[
                                const SizedBox(height: 12),
                                attention,
                              ],
                              const SizedBox(height: 16),
                              controls,
                            ],
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          flex: 6,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 20, 24, 28),
                            children: [
                              lanes,
                              if (station != null) ...[
                                const SizedBox(height: 24),
                                station,
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      hero,
                      if (attention != null) ...[
                        const SizedBox(height: 12),
                        attention,
                      ],
                      const SizedBox(height: 20),
                      lanes,
                      if (station != null) ...[
                        const SizedBox(height: 24),
                        station,
                      ],
                      const SizedBox(height: 20),
                      controls,
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pauseOrResumeBoard(
    BuildContext context,
    KitchenStrings s,
  ) async {
    if (board.status == BoardStatus.paused) {
      await _runKitchenAction(context, () => controller.resumeBoard(board));
      return;
    }
    final ok = await _confirm(
      context,
      s.t('timersContinue'),
      s,
      confirmLabel: s.t('pauseNewTasks'),
    );
    if (ok && context.mounted) {
      await _runKitchenAction(context, () => controller.pauseBoard(board));
    }
  }

  Future<void> _finishCommandRailBoard(
    BuildContext context,
    KitchenStrings s,
  ) async {
    final message = board.unfinishedCount == 0
        ? s.t('closeCompleted')
        : '${s.t('closeUnfinished')}: ${board.unfinishedCount}';
    final ok = await _confirm(
      context,
      message,
      s,
      confirmLabel: board.unfinishedCount == 0
          ? s.t('closeCompleted')
          : s.t('closeUnfinished'),
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await _runKitchenAction(
      context,
      () => controller.finishBoard(board),
    );
    if (!saved || !context.mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        content: Text(s.t('saved')),
        action: SnackBarAction(
          label: s.t('undo'),
          onPressed: () => _runKitchenValue(
            messenger.context,
            () => controller.undoLastFinish(s),
          ),
        ),
      ),
    );
  }

  Future<void> _handoff(BuildContext context, KitchenStrings s) async {
    final note = TextEditingController(text: board.handoffNote ?? '');
    bool keepTimers = true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(s.t('handoff')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: note, maxLines: 3),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.t('timersContinue')),
                value: keepTimers,
                onChanged: (value) => setState(() => keepTimers = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.t('handoff')),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      final saved = await _runKitchenAction(
        context,
        () => controller.handoff(
          board,
          note: note.text,
          keepTimersRunning: keepTimers,
        ),
      );
      if (saved && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.t('saved'))),
        );
      }
    }
    note.dispose();
  }
}

class _BoardControlPanel extends StatelessWidget {
  const _BoardControlPanel({
    required this.board,
    required this.pauseOrResume,
    required this.handoff,
    required this.finish,
  });

  final KitchenBoard board;
  final VoidCallback pauseOrResume;
  final VoidCallback handoff;
  final VoidCallback finish;

  @override
  Widget build(BuildContext context) {
    final s = _s(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: pauseOrResume,
                icon: Icon(
                  board.status == BoardStatus.paused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                ),
                label: Text(
                  board.status == BoardStatus.paused
                      ? s.t('resume')
                      : s.t('pause'),
                ),
              ),
            ),
            if (board.unfinishedCount > 0) ...[
              const SizedBox(width: 10),
              IconButton.outlined(
                constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
                tooltip: s.t('handoff'),
                onPressed: handoff,
                icon: const Icon(Icons.sync_alt_rounded),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: _WorkbenchColors.charcoal,
            foregroundColor: Colors.white,
          ),
          onPressed: finish,
          icon: const Icon(Icons.flag_outlined),
          label: Text(
            board.unfinishedCount == 0
                ? s.t('closeCompleted')
                : '${s.t('closeUnfinished')} (${board.unfinishedCount})',
          ),
        ),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) return item;
    return null;
  }
}

class _ActiveTaskHero extends StatelessWidget {
  const _ActiveTaskHero({
    required this.controller,
    required this.board,
    required this.task,
  });

  final KitchenController controller;
  final KitchenBoard board;
  final KitchenTask task;

  @override
  Widget build(BuildContext context) {
    final s = _s(context);
    final reading = readTimer(task, DateTime.now().millisecondsSinceEpoch);
    final pausedTimer =
        task.status == TaskStatus.ready && task.pausedRemainingMs != null;
    final isRunning = task.status == TaskStatus.running;
    final totalMs = math.max((task.durationSeconds ?? 0) * 1000, 1);
    final progress = isRunning && task.deadlineEpochMs != null
        ? (1 - reading.remainingMs / totalMs).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final timerText = isRunning && task.deadlineEpochMs != null
        ? (reading.expired ? '00:00' : _duration(reading.remainingMs))
        : s.t('now');

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF7FBFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _WorkbenchColors.line),
        boxShadow: const [
          BoxShadow(
            color: _WorkbenchColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                (reading.expired ? s.t('attention') : s.t('now')).toUpperCase(),
                style: const TextStyle(
                  color: _WorkbenchColors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: s.t('more'),
                onSelected: (value) => _moreAction(context, value, s),
                itemBuilder: (context) => [
                  if (isRunning && task.deadlineEpochMs != null)
                    for (final minutes in const [1, 5, 10])
                      PopupMenuItem(
                        value: 'add_$minutes',
                        child: Text('+$minutes ${s.t('minutes')}'),
                      ),
                  if (board.tasks.indexOf(task) > 0)
                    PopupMenuItem(value: 'top', child: Text(s.t('moveTop'))),
                  PopupMenuItem(value: 'skip', child: Text(s.t('skip'))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _WorkbenchColors.orangeSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _taskProcessIcon(task),
                  color: _WorkbenchColors.orange,
                  size: 31,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  task.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: _WorkbenchColors.charcoal,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              timerText,
              style: TextStyle(
                color: reading.expired
                    ? _WorkbenchColors.orangeDeep
                    : _WorkbenchColors.charcoal,
                fontSize: task.deadlineEpochMs == null ? 50 : 76,
                height: 0.95,
                fontWeight: FontWeight.w900,
                letterSpacing: -3.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: task.deadlineEpochMs == null ? 0 : progress,
              backgroundColor: _WorkbenchColors.line,
              color: _WorkbenchColors.orange,
            ),
          ),
          if (task.note?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            Text(
              task.note!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _WorkbenchColors.muted,
                  ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              foregroundColor: Colors.white,
              backgroundColor: _WorkbenchColors.orange,
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            onPressed: board.status == BoardStatus.paused && !isRunning
                ? null
                : () => isRunning
                    ? _complete(context, s)
                    : _runKitchenAction(
                        context,
                        () => pausedTimer
                            ? controller.resumeTaskTimer(board, task, s)
                            : controller.startTask(board, task, s),
                      ),
            icon: Icon(
              isRunning ? Icons.check_circle_rounded : Icons.play_arrow_rounded,
            ),
            label: Text(
              isRunning
                  ? s.t('done')
                  : pausedTimer
                      ? s.t('resume')
                      : s.t('start'),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (isRunning && task.deadlineEpochMs != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _runKitchenAction(
                      context,
                      () => controller.pauseTaskTimer(board, task),
                    ),
                    icon: const Icon(Icons.pause_rounded),
                    label: Text(s.t('pause')),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAdjust(context, s),
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(s.t('adjust')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _complete(BuildContext context, KitchenStrings s) async {
    final saved = await _runKitchenAction(
      context,
      () => controller.markDone(board, task),
    );
    if (!saved || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.t('done')),
        action: SnackBarAction(
          label: s.t('undo'),
          onPressed: () => _runKitchenAction(
            context,
            () => controller.restore(board, task),
          ),
        ),
      ),
    );
  }

  Future<void> _showAdjust(BuildContext context, KitchenStrings s) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (task.status == TaskStatus.running &&
                task.deadlineEpochMs != null)
              for (final minutes in const [1, 5, 10])
                ListTile(
                  leading: const Icon(Icons.add_alarm_rounded),
                  title: Text('+$minutes ${s.t('minutes')}'),
                  onTap: () => Navigator.pop(context, 'add_$minutes'),
                ),
            if (board.tasks.indexOf(task) > 0)
              ListTile(
                leading: const Icon(Icons.vertical_align_top_rounded),
                title: Text(s.t('moveTop')),
                onTap: () => Navigator.pop(context, 'top'),
              ),
            ListTile(
              leading: const Icon(Icons.skip_next_rounded),
              title: Text(s.t('skip')),
              onTap: () => Navigator.pop(context, 'skip'),
            ),
          ],
        ),
      ),
    );
    if (choice != null && context.mounted) {
      await _moreAction(context, choice, s);
    }
  }

  Future<void> _moreAction(
    BuildContext context,
    String value,
    KitchenStrings s,
  ) async {
    if (value.startsWith('add_')) {
      final minutes = int.tryParse(value.substring(4));
      if (minutes != null) {
        await _runKitchenAction(
          context,
          () => controller.addTime(
            board,
            task,
            Duration(minutes: minutes),
            s,
          ),
        );
      }
      return;
    }
    if (value == 'top') {
      await _runKitchenAction(
        context,
        () => controller.moveTaskToTop(board, task),
      );
      return;
    }
    if (value == 'skip') {
      if (task.status == TaskStatus.running && task.deadlineEpochMs != null) {
        final ok = await _confirm(
          context,
          s.t('skipTimerWarning'),
          s,
          confirmLabel: s.t('skip'),
        );
        if (!ok || !context.mounted) return;
      }
      await _runKitchenAction(
        context,
        () => controller.markSkipped(board, task),
      );
    }
  }
}

class _TaskLanes extends StatelessWidget {
  const _TaskLanes({
    required this.controller,
    required this.board,
    this.focusTaskId,
  });

  final KitchenController controller;
  final KitchenBoard board;
  final String? focusTaskId;

  @override
  Widget build(BuildContext context) {
    final s = _s(context);
    final nowTasks = board.tasks
        .where((task) =>
            task.status == TaskStatus.running && task.id != focusTaskId)
        .toList();
    final nextTasks = board.tasks
        .where((task) => task.status == TaskStatus.ready && task.id != focusTaskId)
        .toList();
    final waitingTasks = board.tasks
        .where((task) =>
            task.status == TaskStatus.waiting ||
            task.status == TaskStatus.blocked)
        .toList();
    final doneTasks = board.tasks.where((task) => task.isTerminal).toList();
    final sections = <Widget>[
      if (nowTasks.isNotEmpty)
        _CommandLaneSection(
          label: s.t('now'),
          color: _WorkbenchColors.orange,
          tasks: nowTasks,
          controller: controller,
          board: board,
        ),
      _CommandLaneSection(
        label: s.t('next'),
        color: _WorkbenchColors.blue,
        tasks: nextTasks,
        controller: controller,
        board: board,
      ),
      _CommandLaneSection(
        label: s.t('waiting'),
        color: _WorkbenchColors.orangeDeep,
        tasks: waitingTasks,
        controller: controller,
        board: board,
      ),
      _CommandLaneSection(
        label: s.t('done'),
        color: _WorkbenchColors.olive,
        tasks: doneTasks,
        controller: controller,
        board: board,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          sections[i],
        ],
      ],
    );
  }
}

class _CommandLaneSection extends StatelessWidget {
  const _CommandLaneSection({
    required this.label,
    required this.color,
    required this.tasks,
    required this.controller,
    required this.board,
  });

  final String label;
  final Color color;
  final List<KitchenTask> tasks;
  final KitchenController controller;
  final KitchenBoard board;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${tasks.length}',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Container(
          decoration: BoxDecoration(
            color: _WorkbenchColors.paper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _WorkbenchColors.line),
            boxShadow: const [
              BoxShadow(
                color: _WorkbenchColors.shadow,
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: tasks.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Icon(
                    label == _s(context).t('done')
                        ? Icons.check_circle_outline_rounded
                        : Icons.horizontal_rule_rounded,
                    color: _WorkbenchColors.muted,
                  ),
                )
              : Column(
                  children: [
                    for (final task in tasks)
                      TaskActionCard(
                        controller: controller,
                        board: board,
                        task: task,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _AllClearPanel extends StatelessWidget {
  const _AllClearPanel({required this.board});

  final KitchenBoard board;

  @override
  Widget build(BuildContext context) {
    final s = _s(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _WorkbenchColors.olive,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: _WorkbenchColors.paper,
            size: 52,
          ),
          const SizedBox(height: 12),
          Text(
            s.t('done'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _WorkbenchColors.paper,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${board.doneCount} ${s.t('tasks')}',
            style: const TextStyle(color: _WorkbenchColors.oliveSoft),
          ),
        ],
      ),
    );
  }
}

class TaskActionCard extends StatelessWidget {
  const TaskActionCard({
    required this.controller,
    required this.board,
    required this.task,
    super.key,
  });
  final KitchenController controller;
  final KitchenBoard board;
  final KitchenTask task;

  @override
  Widget build(BuildContext context) {
    final s = _s(context);
    final reading = readTimer(task, DateTime.now().millisecondsSinceEpoch);
    final pausedTimer = task.status == TaskStatus.ready && task.pausedRemainingMs != null;
    final dependencies = task.dependencyIds
        .map(board.taskById)
        .whereType<KitchenTask>()
        .map((item) => item.name)
        .join(', ');
    if (_usesCommandRail(context)) {
      return _buildCommandTask(
        context,
        s,
        reading,
        pausedTimer,
        dependencies,
      );
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (reading.expired) Chip(label: Text(s.t('attention'))),
                if (task.status == TaskStatus.done)
                  const Icon(Icons.check_circle_outline),
                if (task.status == TaskStatus.skipped)
                  const Icon(Icons.skip_next_outlined),
              ],
            ),
            if (task.status == TaskStatus.blocked && dependencies.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('${s.t('dependency')}: $dependencies'),
            ],
            if (task.resourceRequirements.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${s.t('resource')}: '
                '${task.resourceRequirements.map((item) => board.resourceById(item.resourceId)?.name ?? item.resourceId).join(', ')}',
              ),
            ],
            if (task.status == TaskStatus.running && task.deadlineEpochMs != null) ...[
              const SizedBox(height: 8),
              Text(
                reading.expired ? s.t('attention') : _duration(reading.remainingMs),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!task.isTerminal && task.status != TaskStatus.running)
                  FilledButton.icon(
                    onPressed: board.status == BoardStatus.paused ||
                            task.status == TaskStatus.blocked
                        ? null
                        : () => _runKitchenAction(
                              context,
                              () => pausedTimer
                                  ? controller.resumeTaskTimer(board, task, s)
                                  : controller.startTask(board, task, s),
                            ),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(pausedTimer ? s.t('resume') : s.t('start')),
                  ),
                if (task.status == TaskStatus.running) ...[
                  FilledButton.icon(
                    onPressed: () => _complete(context, s),
                    icon: const Icon(Icons.check),
                    label: Text(s.t('done')),
                  ),
                  if (task.deadlineEpochMs != null)
                    OutlinedButton.icon(
                      onPressed: () => _runKitchenAction(
                        context,
                        () => controller.pauseTaskTimer(board, task),
                      ),
                      icon: const Icon(Icons.pause),
                      label: Text(s.t('pause')),
                    ),
                  if (task.deadlineEpochMs != null)
                    for (final minutes in const [1, 5, 10])
                      OutlinedButton(
                        onPressed: () => _runKitchenAction(
                          context,
                          () => controller.addTime(
                            board,
                            task,
                            Duration(minutes: minutes),
                            s,
                          ),
                        ),
                        child: Text('+$minutes ${s.t('minutes')}'),
                      ),
                ],
                if (!task.isTerminal && board.tasks.indexOf(task) > 0)
                  TextButton.icon(
                    onPressed: () => _runKitchenAction(
                      context,
                      () => controller.moveTaskToTop(board, task),
                    ),
                    icon: const Icon(Icons.vertical_align_top_rounded),
                    label: Text(s.t('moveTop')),
                  ),
                if (!task.isTerminal)
                  TextButton(
                    onPressed: () => _skip(context, s),
                    child: Text(s.t('skip')),
                  ),
                if (task.isTerminal)
                  TextButton(
                    onPressed: () => _runKitchenAction(
                      context,
                      () => controller.restore(board, task),
                    ),
                    child: Text(s.t('restore')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandTask(
    BuildContext context,
    KitchenStrings s,
    TimerReading reading,
    bool pausedTimer,
    String dependencies,
  ) {
    final isRunning = task.status == TaskStatus.running;
    final statusColor = task.isTerminal
        ? _WorkbenchColors.olive
        : task.status == TaskStatus.blocked
            ? _WorkbenchColors.muted
            : isRunning
                ? _WorkbenchColors.orange
                : _WorkbenchColors.blue;
    final detail = <String>[
      if (isRunning && task.deadlineEpochMs != null)
        reading.expired ? s.t('attention') : _duration(reading.remainingMs),
      if (!isRunning && task.hasTimer)
        '${((task.pausedRemainingMs ?? (task.durationSeconds! * 1000)) / 60000).ceil()} ${s.t('minutes')}',
      if (task.status == TaskStatus.blocked && dependencies.isNotEmpty)
        '${s.t('dependency')}: $dependencies',
    ].join(' · ');

    final totalMs = task.durationSeconds == null
        ? 0
        : task.durationSeconds! * 1000;
    final progress = totalMs <= 0
        ? 0.0
        : (1 - reading.remainingMs / totalMs).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 2, 10),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _WorkbenchColors.line),
        ),
      ),
      child: Row(
        children: [
          if (isRunning && task.deadlineEpochMs != null)
            SizedBox(
              width: 44,
              height: 44,
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
                  Center(
                    child: Icon(
                      _taskProcessIcon(task),
                      size: 21,
                      color: _WorkbenchColors.orange,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _taskProcessIcon(task),
                color: statusColor,
                size: 23,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: task.isTerminal
                            ? _WorkbenchColors.muted
                            : _WorkbenchColors.charcoal,
                        decoration: task.isTerminal
                            ? TextDecoration.lineThrough
                            : null,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: reading.expired
                              ? _WorkbenchColors.orange
                              : _WorkbenchColors.muted,
                          fontWeight: reading.expired
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (!task.isTerminal)
            IconButton(
              tooltip: isRunning
                  ? s.t('done')
                  : pausedTimer
                      ? s.t('resume')
                      : s.t('start'),
              onPressed: board.status == BoardStatus.paused ||
                      task.status == TaskStatus.blocked
                  ? (isRunning ? () => _complete(context, s) : null)
                  : () => isRunning
                      ? _complete(context, s)
                      : _runKitchenAction(
                          context,
                          () => pausedTimer
                              ? controller.resumeTaskTimer(board, task, s)
                              : controller.startTask(board, task, s),
                        ),
              icon: Icon(
                isRunning
                    ? Icons.check_circle_rounded
                    : Icons.play_circle_outline_rounded,
                color: isRunning
                    ? _WorkbenchColors.orange
                    : _WorkbenchColors.blue,
              ),
            )
          else
            IconButton(
              tooltip: s.t('restore'),
              onPressed: () => _runKitchenAction(
                context,
                () => controller.restore(board, task),
              ),
              icon: const Icon(
                Icons.replay_rounded,
                color: _WorkbenchColors.muted,
              ),
            ),
          if (!task.isTerminal)
            PopupMenuButton<String>(
              tooltip: s.t('more'),
              onSelected: (value) async {
                if (value == 'top') {
                  await _runKitchenAction(
                    context,
                    () => controller.moveTaskToTop(board, task),
                  );
                } else if (value == 'skip') {
                  await _skip(context, s);
                } else if (value == 'pause') {
                  await _runKitchenAction(
                    context,
                    () => controller.pauseTaskTimer(board, task),
                  );
                }
              },
              itemBuilder: (context) => [
                if (isRunning && task.deadlineEpochMs != null)
                  PopupMenuItem(value: 'pause', child: Text(s.t('pause'))),
                if (board.tasks.indexOf(task) > 0)
                  PopupMenuItem(value: 'top', child: Text(s.t('moveTop'))),
                PopupMenuItem(value: 'skip', child: Text(s.t('skip'))),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _complete(BuildContext context, KitchenStrings s) async {
    final saved = await _runKitchenAction(
      context,
      () => controller.markDone(board, task),
    );
    if (!saved || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.t('done')),
        action: SnackBarAction(
          label: s.t('undo'),
          onPressed: () => _runKitchenAction(
            context,
            () => controller.restore(board, task),
          ),
        ),
      ),
    );
  }

  Future<void> _skip(BuildContext context, KitchenStrings s) async {
    if (task.status == TaskStatus.running && task.deadlineEpochMs != null) {
      final ok = await _confirm(
        context,
        s.t('skipTimerWarning'),
        s,
        confirmLabel: s.t('skip'),
      );
      if (!ok) return;
    }
    final saved = await _runKitchenAction(
      context,
      () => controller.markSkipped(board, task),
    );
    if (!saved || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.t('skip')),
        action: SnackBarAction(
          label: s.t('undo'),
          onPressed: () => _runKitchenAction(
            context,
            () => controller.restore(board, task),
          ),
        ),
      ),
    );
  }
}

String _duration(int ms) {
  final seconds = (ms / 1000).ceil();
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${rest.toString().padLeft(2, '0')}';
}

class LiveStationRow extends StatelessWidget {
  const LiveStationRow({
    required this.controller,
    required this.board,
    required this.item,
    super.key,
  });
  final KitchenController controller;
  final KitchenBoard board;
  final StationItem item;

  @override
  Widget build(BuildContext context) {
    final s = _s(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 180,
              child: Text(
                item.name,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            SizedBox(
              width: 110,
              child: _TextMetric(
                label: s.t('need'),
                value: '${_num(item.need)} ${item.unit}'.trim(),
              ),
            ),
            SizedBox(
              width: 140,
              child: _NumberField(
                label: s.t('prepared'),
                value: item.prepared,
                onValue: (value) => _runKitchenAction(
                  context,
                  () => controller.updateStationItem(
                    board,
                    item,
                    prepared: value,
                  ),
                ),
              ),
            ),
            FilterChip(
              selected: item.verified,
              label: Text(s.t('verified')),
              onSelected: (value) => _runKitchenAction(
                context,
                () => controller.updateStationItem(
                  board,
                  item,
                  verified: value,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextMetric extends StatelessWidget {
  const _TextMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.controller, super.key});
  final KitchenController controller;

  @override
  Widget build(BuildContext context) {
    final s = _s(context);
    final monetization = controller.monetization;
    final product = monetization.product;
    return PageFrame(
      title: s.t('settings'),
      child: Column(
        children: [
          if (product != null || monetization.removeAds) ...[
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: Text(s.t('removeAds')),
              subtitle: product == null ? null : Text(product.price),
              trailing:
                  monetization.removeAds ? const Icon(Icons.check_circle) : null,
              onTap: monetization.removeAds ? null : monetization.buyRemoveAds,
            ),
            ListTile(
              leading: const Icon(Icons.restore_rounded),
              title: Text(s.t('restorePurchases')),
              onTap: monetization.restorePurchases,
            ),
          ],
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: Text(s.t('timerAlerts')),
            value: controller.snapshot.timerAlertsEnabled,
            onChanged: (value) => _runKitchenAction(
              context,
              () => controller.setTimerAlerts(value, s),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.light_mode_outlined),
            title: Text(s.t('keepAwake')),
            value: controller.snapshot.keepScreenAwake,
            onChanged: (value) => _runKitchenAction(
              context,
              () => controller.setKeepScreenAwake(value),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: Text(s.t('language')),
            subtitle: Text(
              controller.snapshot.languageOverride == null
                  ? s.t('systemDefault')
                  : KitchenStrings.languageLabels[
                          controller.snapshot.languageOverride] ??
                      s.t('systemDefault'),
            ),
            onTap: () => _languageDialog(context, controller, s),
          ),
          ListTile(
            leading: const Icon(Icons.public_outlined),
            title: Text(s.t('region')),
            subtitle: Text(
              controller.snapshot.regionOverride ?? s.t('automatic'),
            ),
            onTap: () => _regionDialog(context, controller, s),
          ),
          ListTile(
            leading: const Icon(Icons.straighten_outlined),
            title: Text(s.t('unitsTemp')),
            subtitle: Text(
              '${controller.snapshot.unitSystem == 'imperial' ? s.t('imperial') : controller.snapshot.unitSystem == 'metric' ? s.t('metric') : s.t('automatic')} · '
              '${controller.snapshot.temperatureUnit == 'f' ? '°F' : controller.snapshot.temperatureUnit == 'c' ? '°C' : s.t('automatic')}',
            ),
            onTap: () => _unitsDialog(context, controller, s),
          ),
          if (monetization.privacyOptionsRequired)
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(s.t('privacyOptions')),
              onTap: monetization.showPrivacyOptions,
            ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(s.t('dataPrivacy')),
            subtitle: Text(s.t('offline')),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(s.t('helpAbout')),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: s.t('appName'),
              applicationVersion: '2.0.0',
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: Text(s.t('deleteData')),
            onTap: () async {
              final ok = await _confirm(
                context,
                s.t('deleteData'),
                s,
                confirmLabel: s.t('delete'),
              );
              if (ok) {
                await _runKitchenAction(context, controller.clearLocalData);
              }
            },
          ),
        ],
      ),
    );
  }
}

Future<void> _languageDialog(
  BuildContext context,
  KitchenController controller,
  KitchenStrings s,
) async {
  final current = controller.snapshot.languageOverride ?? 'system';
  final choice = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(s.t('language')),
      children: [
        for (final entry in KitchenStrings.languageLabels.entries)
          RadioListTile<String>(
            value: entry.key,
            groupValue: current,
            title: Text(
              entry.key == 'system' ? s.t('systemDefault') : entry.value,
            ),
            onChanged: (value) => Navigator.pop(context, value),
          ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return;
  await _runKitchenAction(
    context,
    () => controller.setLanguage(
      choice == 'system' ? null : choice,
      WidgetsBinding.instance.platformDispatcher.locale,
    ),
  );
}

Future<void> _regionDialog(
  BuildContext context,
  KitchenController controller,
  KitchenStrings s,
) async {
  final current = controller.snapshot.regionOverride ?? '';
  final regions = <String>[
    '', 'CA', 'US', 'GB', 'AU', 'NZ', 'NG', 'ZA', 'IE', 'FR', 'DE', 'IT',
    'ES', 'PT', 'BR', 'MX', 'JP', 'KR', 'CN', 'TW', 'HK', 'SG', 'IN',
  ];
  final choice = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(s.t('region')),
      children: [
        for (final code in regions)
          RadioListTile<String>(
            value: code,
            groupValue: current,
            title: Text(code.isEmpty ? s.t('automatic') : code),
            onChanged: (value) => Navigator.pop(context, value),
          ),
      ],
    ),
  );
  if (choice != null && context.mounted) {
    await _runKitchenAction(
      context,
      () => controller.setRegion(choice.isEmpty ? null : choice),
    );
  }
}

Future<void> _unitsDialog(
  BuildContext context,
  KitchenController controller,
  KitchenStrings s,
) async {
  var unit = controller.snapshot.unitSystem;
  var temperature = controller.snapshot.temperatureUnit;
  final save = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(s.t('unitsTemp')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'auto', label: Text(s.t('automatic'))),
                ButtonSegment(value: 'metric', label: Text(s.t('metric'))),
                ButtonSegment(value: 'imperial', label: Text(s.t('imperial'))),
              ],
              selected: {unit},
              onSelectionChanged: (values) =>
                  setState(() => unit = values.first),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'auto', label: Text(s.t('automatic'))),
                const ButtonSegment(value: 'c', label: Text('°C')),
                const ButtonSegment(value: 'f', label: Text('°F')),
              ],
              selected: {temperature},
              onSelectionChanged: (values) =>
                  setState(() => temperature = values.first),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.t('done')),
          ),
        ],
      ),
    ),
  );
  if (save == true && context.mounted) {
    await _runKitchenAction(
      context,
      () => controller.setUnits(
        unitSystem: unit,
        temperatureUnit: temperature,
      ),
    );
  }
}
