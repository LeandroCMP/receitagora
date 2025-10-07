import 'package:get/get.dart';

import '../../modules/recipe_finder/presentation/bindings/recipe_finder_binding.dart';
import '../../modules/recipe_finder/presentation/pages/recipe_finder_page.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = AppRoutes.recipeFinder;

  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.recipeFinder,
      page: RecipeFinderPage.new,
      binding: RecipeFinderBinding(),
    ),
  ];
}
