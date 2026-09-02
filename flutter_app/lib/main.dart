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
        const forceIOSSkin = bool.fromEnvironment('FORCE_IOS_SKIN');
        final useIOSWorkbench = forceIOSSkin ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS;
        final colors = ColorScheme.fromSeed(
          seedColor: const Color(0xFF315D4B),
          brightness: Brightness.light,
          surface: useIOSWorkbench
              ? const Color(0xFFF7F3E8)
              : const Color(0xFFF8FAF7),
        ).copyWith(
          primary: const Color(0xFF315D4B),
          onPrimary: const Color(0xFFFFFBF2),
          secondary: const Color(0xFFE6843D),
          onSecondary: const Color(0xFF231F1A),
          surface: useIOSWorkbench
              ? const Color(0xFFF7F3E8)
              : const Color(0xFFF8FAF7),
          onSurface: const Color(0xFF1F2B26),
          outline: const Color(0xFFB8C1B8),
          outlineVariant: const Color(0xFFDCE2D8),
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
          theme: !useIOSWorkbench
              ? ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.light,
                  colorSchemeSeed: const Color(0xFF496554),
                  scaffoldBackgroundColor: const Color(0xFFF8FAF7),
                  cardTheme: const CardThemeData(margin: EdgeInsets.zero),
                  inputDecorationTheme: const InputDecorationTheme(
                    border: OutlineInputBorder(),
                  ),
                )
              : ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            platform: useIOSWorkbench ? TargetPlatform.iOS : defaultTargetPlatform,
            colorScheme: colors,
            scaffoldBackgroundColor: colors.surface,
            appBarTheme: AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              backgroundColor: colors.surface,
              foregroundColor: colors.onSurface,
            ),
            cardTheme: CardThemeData(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: useIOSWorkbench
                  ? const Color(0xFFFFFCF5)
                  : colors.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(useIOSWorkbench ? 18 : 12),
                side: BorderSide(
                  color: useIOSWorkbench
                      ? const Color(0xFFE1E5DD)
                      : colors.outlineVariant,
                ),
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              height: useIOSWorkbench ? 68 : 80,
              elevation: 0,
              backgroundColor: useIOSWorkbench
                  ? const Color(0xFFFFFCF5)
                  : colors.surface,
              indicatorColor: useIOSWorkbench
                  ? const Color(0xFFDDE9E1)
                  : colors.secondaryContainer,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                return TextStyle(
                  fontSize: 11,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: states.contains(WidgetState.selected)
                      ? colors.primary
                      : const Color(0xFF65706A),
                );
              }),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                minimumSize: const Size(44, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: useIOSWorkbench,
              fillColor: useIOSWorkbench ? const Color(0xFFFFFCF5) : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
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
