import 'dart:async';

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
            colorSchemeSeed: const Color(0xFF496554),
            scaffoldBackgroundColor: const Color(0xFFF8FAF7),
            cardTheme: const CardThemeData(margin: EdgeInsets.zero),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
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
