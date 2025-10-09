import 'package:get/get.dart';

import '../../modules/auth/presentation/bindings/login_binding.dart';
import '../../modules/auth/presentation/pages/login_page.dart';
import '../../modules/recipe_finder/presentation/bindings/recipe_finder_binding.dart';
import '../../modules/recipe_finder/presentation/pages/recipe_finder_page.dart';
import '../../modules/recipe_finder/presentation/pages/recipe_results_page.dart';
import '../../modules/recipe_finder/presentation/pages/recipe_detail_page.dart';
import '../../modules/favorites/presentation/bindings/favorites_binding.dart';
import '../../modules/favorites/presentation/pages/favorites_page.dart';
import '../../modules/user_profile/presentation/bindings/user_profile_binding.dart';
import '../../modules/user_profile/presentation/pages/user_profile_page.dart';
import '../../modules/splash/presentation/bindings/splash_binding.dart';
import '../../modules/splash/presentation/pages/splash_page.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.splash,
      page: SplashPage.new,
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: LoginPage.new,
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.recipeFinder,
      page: RecipeFinderPage.new,
      binding: RecipeFinderBinding(),
    ),
    GetPage(
      name: AppRoutes.recipeResults,
      page: RecipeResultsPage.new,
    ),
    GetPage(
      name: AppRoutes.recipeDetail,
      page: RecipeDetailPage.new,
    ),
    GetPage(
      name: AppRoutes.userProfile,
      page: UserProfilePage.new,
      binding: UserProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.favorites,
      page: FavoritesPage.new,
      binding: FavoritesBinding(),
    ),
  ];
}
