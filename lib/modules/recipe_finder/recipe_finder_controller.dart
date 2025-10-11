import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/core/errors/app_exception.dart';
import 'package:receitagora/models/user_model.dart';
import 'package:receitagora/modules/recipe_finder/domain/entities/recipe_entity.dart';
import 'package:receitagora/modules/recipe_finder/domain/usecases/generate_recipes_usecase.dart';
import 'package:receitagora/services/session/session_service.dart';
import 'recipe_results_page.dart';

class RecipeFinderController extends GetxController {
  RecipeFinderController({
    required this.generateRecipesUseCase,
    required this.sessionService,
  });

  final GenerateRecipesUseCase generateRecipesUseCase;
  final SessionService sessionService;

  final ingredients = <String>[].obs;
  final recipes = <RecipeEntity>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final isGuest = false.obs;
  final guestSearchesRemaining = SessionService.guestDailyLimit.obs;
  final currentUser = Rxn<UserModel>();

  final TextEditingController ingredientTextController = TextEditingController();
  final FocusNode ingredientFocusNode = FocusNode();

  StreamSubscription<UserMode?>? _modeSubscription;
  StreamSubscription<int>? _guestQuotaSubscription;
  StreamSubscription<UserModel?>? _userSubscription;

  @override
  void onInit() {
    super.onInit();
    _syncSessionState();
    _modeSubscription = sessionService.modeStream.listen((_) => _syncSessionState());
    _guestQuotaSubscription =
        sessionService.guestSearchCountStream.listen((_) => _syncGuestQuota());
    _userSubscription = sessionService.userStream.listen((user) {
      currentUser.value = user;
    });
  }

  void addIngredient(String ingredient) {
    final sanitized = ingredient.trim();
    if (sanitized.isEmpty) {
      return;
    }
    if (!ingredients.contains(sanitized)) {
      ingredients.add(sanitized);
    }
    ingredientTextController.clear();
    ingredientFocusNode.requestFocus();
  }

  void removeIngredient(String ingredient) {
    ingredients.remove(ingredient);
  }

  Future<void> fetchRecipes() async {
    if (ingredients.isEmpty) {
      const message = 'Adicione ao menos um ingrediente.';
      errorMessage.value = message;
      recipes.clear();
      Get.snackbar(
        'Nada para buscar',
        message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (sessionService.isGuest && !sessionService.canPerformGuestSearch()) {
      const message =
          'Você atingiu o limite diário de buscas no modo visitante. O login social estará disponível em breve para liberar buscas ilimitadas.';
      errorMessage.value = message;
      recipes.clear();
      Get.snackbar(
        'Limite diário atingido',
        message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final results = await generateRecipesUseCase(ingredients);
      final adjustedResults = sessionService.isGuest
          ? results.take(SessionService.guestRecipeLimit).toList()
          : results;
      recipes.assignAll(adjustedResults);
      if (sessionService.isGuest) {
        await sessionService.registerGuestSearch();
        _syncGuestQuota();
      }

      String? helperMessage;
      if (adjustedResults.isEmpty) {
        helperMessage = 'Não encontramos receitas com esses ingredientes.';
        errorMessage.value = helperMessage;
      }

      Get.toNamed(
        AppRoutes.recipeResults,
        arguments: RecipeResultsArgs(
          recipes: adjustedResults,
          ingredients: List<String>.from(ingredients),
          message: helperMessage,
        ),
      );
    } catch (error) {
      String message;
      if (error is AppException) {
        message = error.message;
      } else {
        message =
            'Não foi possível gerar receitas agora. Tente novamente.';
      }
      errorMessage.value = message;
      Get.snackbar(
        'Não foi possível gerar receitas',
        message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    ingredientTextController.dispose();
    ingredientFocusNode.dispose();
    _modeSubscription?.cancel();
    _guestQuotaSubscription?.cancel();
    _userSubscription?.cancel();
    super.onClose();
  }

  void _syncSessionState() {
    isGuest.value = sessionService.isGuest;
    currentUser.value = sessionService.user;
    _syncGuestQuota();
  }

  void _syncGuestQuota() {
    guestSearchesRemaining.value = sessionService.guestSearchesRemaining;
  }
}
