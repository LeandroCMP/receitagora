import 'package:get/get.dart';

import 'package:receitagora/application/modules/module.dart';
import 'package:receitagora/application/routes/app_routes.dart';

import 'nutrition_plan_bindings.dart';
import 'nutrition_plan_page.dart';

class NutritionPlanModule implements Module {
  @override
  List<GetPage<dynamic>> get routers => [
        GetPage(
          name: AppRoutes.nutritionPlan,
          page: () => const NutritionPlanPage(),
          binding: NutritionPlanBindings(),
        ),
      ];
}
