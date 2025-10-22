import 'package:get/get.dart';

import 'package:receitagora/application/modules/module.dart';
import 'package:receitagora/application/routes/app_routes.dart';

import 'favorites_notebook_detail_controller.dart';
import 'favorites_notebook_detail_page.dart';
import 'favorites_notebooks_bindings.dart';
import 'favorites_notebooks_page.dart';

class FavoritesNotebooksModule implements Module {
  @override
  List<GetPage<dynamic>> get routers => [
        GetPage(
          name: AppRoutes.favoritesNotebooks,
          page: () => const FavoritesNotebooksPage(),
          binding: FavoritesNotebooksBindings(),
        ),
        GetPage(
          name: AppRoutes.favoritesNotebookDetail,
          page: () {
            final args = Get.arguments;
            if (args is! FavoritesNotebookDetailArgs) {
              throw ArgumentError(
                'Use FavoritesNotebookDetailArgs para abrir o caderno.',
              );
            }
            return const FavoritesNotebookDetailPage();
          },
          binding: FavoritesNotebookDetailBindings(),
        ),
      ];
}
