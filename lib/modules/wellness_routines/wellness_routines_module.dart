import 'package:get/get.dart';

import 'package:receitagora/application/modules/module.dart';
import 'package:receitagora/application/routes/app_routes.dart';

import 'wellness_routines_bindings.dart';
import 'wellness_routines_page.dart';

class WellnessRoutinesModule implements Module {
  @override
  List<GetPage<dynamic>> get routers => [
        GetPage(
          name: AppRoutes.wellnessRoutines,
          page: () => const WellnessRoutinesPage(),
          binding: WellnessRoutinesBindings(),
        ),
      ];
}
