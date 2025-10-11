import 'package:get/get.dart';

import 'package:receitagora/application/modules/module.dart';
import 'package:receitagora/application/routes/app_routes.dart';

import 'recipe_detail_page.dart';
import 'recipe_finder_bindings.dart';
import 'recipe_finder_page.dart';
import 'recipe_results_page.dart';

class RecipeFinderModule implements Module {
  @override
  List<GetPage<dynamic>> get routers => [
        GetPage(
          name: AppRoutes.recipeFinder,
          page: () => const RecipeFinderPage(),
          binding: RecipeFinderBindings(),
        ),
        GetPage(
          name: AppRoutes.recipeResults,
          page: () => const RecipeResultsPage(),
        ),
        GetPage(
          name: AppRoutes.recipeDetail,
          page: () => const RecipeDetailPage(),
        ),
      ];
}
