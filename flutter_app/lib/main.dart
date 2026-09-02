import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kitchen_prep_board/application/kitchen_controller.dart';
import 'package:kitchen_prep_board/features/kitchen_shell.dart';
import 'package:kitchen_prep_board/l10n/kitchen_strings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KitchenBootstrap());
}

class KitchenBootstrap extends StatefulWidget {
  const KitchenBootstrap({super.key});

  @override
  State<KitchenBootstrap> createState() => _KitchenBootstrapState();
}

class _KitchenBootstrapState extends State<KitchenBootstrap> {
  late final KitchenController controller;

  @override
  void initState() {
    super.initState();
    controller = KitchenController();
    unawaited(controller.initialize(WidgetsBinding.instance.platformDispatcher.locale));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, controller.monetization]),
      builder: (context, _) {
        final colors = ColorScheme.fromSeed(
          seedColor: const Color(0xFFD85B00),
          brightness: Brightness.light,
          surface: const Color(0xFFFFFEFA),
        ).copyWith(
          primary: const Color(0xFFD85B00),
          onPrimary: const Color(0xFFFFFFFF),
          secondary: const Color(0xFF456F85),
          onSecondary: const Color(0xFFFFFFFF),
          tertiary: const Color(0xFF687A4E),
          surface: const Color(0xFFFFFEFA),
          onSurface: const Color(0xFF20262B),
          outline: const Color(0xFFAAA59D),
          outlineVariant: const Color(0xFFD8D3CA),
        );
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => KitchenStrings(Localizations.localeOf(context)).t('appName'),
          locale: controller.localeOverride,
          supportedLocales: KitchenStrings.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (device, supported) {
            final chosen = controller.localeOverride;
            if (chosen != null) return chosen;
            if (device == null) return const Locale('en');
            for (final locale in supported) {
              if (locale.languageCode == device.languageCode) {
                if (device.languageCode != 'zh') return locale;
                final traditional = device.scriptCode == 'Hant' ||
                    const {'TW', 'HK', 'MO'}.contains(device.countryCode);
                if (traditional && locale.scriptCode == 'Hant') return locale;
                if (!traditional && locale.scriptCode == 'Hans') return locale;
              }
            }
            return const Locale('en');
          },
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            platform: defaultTargetPlatform,
            colorScheme: colors,
            scaffoldBackgroundColor: const Color(0xFFF7F3EA),
            splashFactory: InkSparkle.splashFactory,
            appBarTheme: AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              backgroundColor: const Color(0xFFFFFEFA),
              foregroundColor: colors.onSurface,
              surfaceTintColor: Colors.transparent,
            ),
            cardTheme: CardThemeData(
              margin: EdgeInsets.zero,
              elevation: 0,
              shadowColor: const Color(0x241F2529),
              color: const Color(0xFFFFFEFA),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFD8D3CA)),
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              height: 68,
              elevation: 0,
              backgroundColor: const Color(0xFFFFFEFA),
              indicatorColor: const Color(0xFFFFE9D6),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                return TextStyle(
                  fontSize: 11,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: states.contains(WidgetState.selected)
                      ? colors.primary
                      : const Color(0xFF636A6E),
                );
              }),
            ),
            navigationRailTheme: const NavigationRailThemeData(
              backgroundColor: Color(0xFFFFFEFA),
              indicatorColor: Color(0xFFFFE9D6),
              selectedIconTheme: IconThemeData(color: Color(0xFFD85B00)),
              selectedLabelTextStyle: TextStyle(
                color: Color(0xFFD85B00),
                fontWeight: FontWeight.w700,
              ),
            ),
            listTileTheme: const ListTileThemeData(
              iconColor: Color(0xFF456F85),
              textColor: Color(0xFF20262B),
              minVerticalPadding: 12,
              contentPadding: EdgeInsets.symmetric(horizontal: 14),
            ),
            dividerTheme: const DividerThemeData(
              color: Color(0xFFD8D3CA),
              thickness: 1,
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                minimumSize: const Size(44, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFFFFEFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
                TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.linux: ZoomPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: ZoomPageTransitionsBuilder(),
              },
            ),
          ),
          themeMode: ThemeMode.light,
          home: controller.ready
              ? KitchenShell(controller: controller)
              : const Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      },
    );
  }
}
