import 'package:get/get.dart';

import 'package:receitagora/application/modules/module.dart';
import 'package:receitagora/modules/favorites/favorites_module.dart';
import 'package:receitagora/modules/login/login_module.dart';
import 'package:receitagora/modules/recipe_finder/recipe_finder_module.dart';
import 'package:receitagora/modules/splash/splash_module.dart';
import 'package:receitagora/modules/user_profile/user_profile_module.dart';

import 'app_routes.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final List<Module> _modules = <Module>[
    SplashModule(),
    LoginModule(),
    RecipeFinderModule(),
    FavoritesModule(),
    UserProfileModule(),
  ];

  static final List<GetPage<dynamic>> routes =
      _modules.expand((Module module) => module.routers).toList(growable: false);
}
