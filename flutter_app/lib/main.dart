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
          seedColor: const Color(0xFF247BD1),
          brightness: Brightness.light,
          surface: const Color(0xFFFFFFFF),
        ).copyWith(
          primary: const Color(0xFF247BD1),
          onPrimary: const Color(0xFFFFFFFF),
          secondary: const Color(0xFF278E67),
          onSecondary: const Color(0xFFFFFFFF),
          tertiary: const Color(0xFFAA7114),
          surface: const Color(0xFFFFFFFF),
          onSurface: const Color(0xFF163451),
          outline: const Color(0xFF9AB3C9),
          outlineVariant: const Color(0xFFD7E6F3),
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
            scaffoldBackgroundColor: const Color(0xFFEEF6FF),
            splashFactory: InkSparkle.splashFactory,
            appBarTheme: AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              backgroundColor: const Color(0xFFFFFFFF),
              foregroundColor: colors.onSurface,
              surfaceTintColor: Colors.transparent,
            ),
            cardTheme: CardThemeData(
              margin: EdgeInsets.zero,
              elevation: 0,
              shadowColor: const Color(0x122F5E8B),
              color: const Color(0xFFFFFFFF),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFFD7E6F3)),
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              height: 68,
              elevation: 0,
              backgroundColor: const Color(0xFFFFFFFF),
              indicatorColor: const Color(0xFFE7F3FF),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                return TextStyle(
                  fontSize: 11,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: states.contains(WidgetState.selected)
                      ? colors.primary
                      : const Color(0xFF526D89),
                );
              }),
            ),
            navigationRailTheme: const NavigationRailThemeData(
              backgroundColor: Color(0xFFFFFFFF),
              indicatorColor: Color(0xFFE7F3FF),
              selectedIconTheme: IconThemeData(color: Color(0xFF247BD1)),
              selectedLabelTextStyle: TextStyle(
                color: Color(0xFF247BD1),
                fontWeight: FontWeight.w700,
              ),
            ),
            listTileTheme: const ListTileThemeData(
              iconColor: Color(0xFF247BD1),
              textColor: Color(0xFF163451),
              minVerticalPadding: 12,
              contentPadding: EdgeInsets.symmetric(horizontal: 14),
            ),
            dividerTheme: const DividerThemeData(
              color: Color(0xFFD7E6F3),
              thickness: 1,
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                minimumSize: const Size(44, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFFFFFFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
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
