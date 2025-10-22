import 'package:get/get.dart';

import 'package:receitagora/application/modules/module.dart';
import 'package:receitagora/modules/favorites/favorites_module.dart';
import 'package:receitagora/modules/favorites_notebooks/favorites_notebooks_module.dart';
import 'package:receitagora/modules/login/login_module.dart';
import 'package:receitagora/modules/recipe_finder/recipe_finder_module.dart';
import 'package:receitagora/modules/recipe_history/recipe_history_module.dart';
import 'package:receitagora/modules/shopping_list/shopping_list_module.dart';
import 'package:receitagora/modules/wellness_routines/wellness_routines_module.dart';
import 'package:receitagora/modules/splash/splash_module.dart';
import 'package:receitagora/modules/user_profile/user_profile_module.dart';
import 'package:receitagora/modules/billing/premium_plans_module.dart';
import 'package:receitagora/modules/ingredient_lab/ingredient_lab_module.dart';
import 'package:receitagora/modules/nutrition_plan/nutrition_plan_module.dart';

import 'app_routes.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final List<Module> _modules = <Module>[
    SplashModule(),
    LoginModule(),
    RecipeFinderModule(),
    RecipeHistoryModule(),
    FavoritesModule(),
    FavoritesNotebooksModule(),
    ShoppingListModule(),
    WellnessRoutinesModule(),
    UserProfileModule(),
    PremiumPlansModule(),
    IngredientLabModule(),
    NutritionPlanModule(),
  ];

  static final List<GetPage<dynamic>> routes =
      _modules.expand((Module module) => module.routers).toList(growable: false);
}
