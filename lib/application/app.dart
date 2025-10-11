import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:receitagora/application/bindings/application_bindings.dart';
import 'package:receitagora/application/routes/app_pages.dart';
import 'package:receitagora/application/ui/receitagora_app_ui_config.dart';

class ReceitagoraApp extends StatelessWidget {
  const ReceitagoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ReceitagoraAppUiConfig.buildTheme(
      GoogleFonts.poppinsTextTheme(),
    );
    return GetMaterialApp(
      title: 'Receita Agora',
      debugShowCheckedModeBanner: false,
      theme: theme,
      initialBinding: ApplicationBindings(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.cupertino,
      translations: _AppTranslations(),
      locale: const Locale('pt', 'BR'),
      fallbackLocale: const Locale('pt', 'BR'),
    );
  }
}

class _AppTranslations extends Translations {
  _AppTranslations();

  @override
  Map<String, Map<String, String>> get keys => {
        'pt_BR': {
          'app_title': 'Receita Agora',
          'empty_ingredient_hint': 'Adicione ingredientes para começar',
          'generate_recipes': 'Encontrar receitas',
          'try_again': 'Tentar novamente',
        },
      };
}
