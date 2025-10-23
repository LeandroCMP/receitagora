import 'package:get/get.dart';

import 'package:receitagora/application/modules/module.dart';
import 'package:receitagora/application/routes/app_routes.dart';

import 'recipe_history_bindings.dart';
import 'recipe_history_page.dart';

class RecipeHistoryModule implements Module {
  @override
  List<GetPage<dynamic>> get routers => [
        GetPage(
          name: AppRoutes.recipeHistory,
          page: () => const RecipeHistoryPage(),
          binding: RecipeHistoryBindings(),
        ),
      ];
}
