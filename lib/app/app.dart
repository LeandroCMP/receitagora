import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bindings/initial_binding.dart';
import 'routes/app_pages.dart';
import 'theme/app_theme.dart';

class ReceitagoraApp extends StatelessWidget {
  const ReceitagoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.buildTheme(GoogleFonts.poppinsTextTheme());
    return GetMaterialApp(
      title: 'Receita Agora',
      debugShowCheckedModeBanner: false,
      theme: theme,
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.cupertino,
      translations: const _AppTranslations(),
      locale: const Locale('pt', 'BR'),
      fallbackLocale: const Locale('pt', 'BR'),
    );
  }
}

class _AppTranslations extends Translations {
  const _AppTranslations();

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
