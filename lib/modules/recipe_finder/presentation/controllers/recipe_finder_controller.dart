import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/session_service.dart';
import '../../domain/entities/recipe_entity.dart';
import '../../domain/usecases/generate_recipes_usecase.dart';

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

  final TextEditingController ingredientTextController = TextEditingController();
  final FocusNode ingredientFocusNode = FocusNode();

  StreamSubscription<UserMode?>? _modeSubscription;
  StreamSubscription<int>? _guestQuotaSubscription;

  @override
  void onInit() {
    super.onInit();
    _syncSessionState();
    _modeSubscription = sessionService.modeStream.listen((_) => _syncSessionState());
    _guestQuotaSubscription =
        sessionService.guestSearchCountStream.listen((_) => _syncGuestQuota());
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
      errorMessage.value = 'Adicione ao menos um ingrediente.';
      recipes.clear();
      return;
    }

    if (sessionService.isGuest && !sessionService.canPerformGuestSearch()) {
      errorMessage.value =
          'Você atingiu o limite diário de buscas no modo visitante. Faça login com o Google para continuar explorando receitas sem limites.';
      recipes.clear();
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
      if (results.isEmpty) {
        errorMessage.value = 'Não encontramos receitas com esses ingredientes.';
      }
      if (sessionService.isGuest) {
        await sessionService.registerGuestSearch();
        _syncGuestQuota();
      }
    } catch (error) {
      if (error is AppException) {
        errorMessage.value = error.message;
      } else {
        errorMessage.value = 'Não foi possível gerar receitas agora. Tente novamente.';
      }
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
    super.onClose();
  }

  void _syncSessionState() {
    isGuest.value = sessionService.isGuest;
    _syncGuestQuota();
  }

  void _syncGuestQuota() {
    guestSearchesRemaining.value = sessionService.guestSearchesRemaining;
  }
}
