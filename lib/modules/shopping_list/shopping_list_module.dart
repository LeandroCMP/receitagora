import 'package:get/get.dart';

import 'package:receitagora/application/modules/module.dart';
import 'package:receitagora/application/routes/app_routes.dart';

import 'shopping_list_bindings.dart';
import 'shopping_list_detail_controller.dart';
import 'shopping_list_detail_page.dart';
import 'shopping_lists_controller.dart';
import 'shopping_lists_page.dart';

class ShoppingListModule implements Module {
  @override
  List<GetPage<dynamic>> get routers => [
        GetPage(
          name: AppRoutes.shoppingLists,
          page: () => const ShoppingListsPage(),
          binding: ShoppingListsBindings(),
        ),
        GetPage(
          name: AppRoutes.shoppingListDetail,
          page: () {
            final args = Get.arguments;
            if (args is! ShoppingListDetailArgs) {
              throw ArgumentError(
                'Use ShoppingListDetailArgs para abrir a lista de compras.',
              );
            }
            return const ShoppingListDetailPage();
          },
          binding: ShoppingListDetailBindings(),
        ),
      ];
}
