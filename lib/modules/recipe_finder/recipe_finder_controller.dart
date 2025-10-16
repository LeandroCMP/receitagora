import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/core/errors/app_exception.dart';
import 'package:receitagora/models/user_model.dart';
import 'package:receitagora/modules/recipe_finder/domain/entities/recipe_entity.dart';
import 'package:receitagora/modules/recipe_finder/domain/usecases/generate_recipes_usecase.dart';
import 'package:receitagora/services/recipe/recipe_history_service.dart';
import 'package:receitagora/services/session/session_service.dart';
import 'recipe_results_page.dart';

class RecipeFinderController extends GetxController {
  RecipeFinderController({
    required this.generateRecipesUseCase,
    required this.sessionService,
    required this.recipeHistoryService,
  });

  final GenerateRecipesUseCase generateRecipesUseCase;
  final SessionService sessionService;
  final RecipeHistoryService recipeHistoryService;

  final ingredients = <String>[].obs;
  final recipes = <RecipeEntity>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final isGuest = false.obs;
  final guestSearchesRemaining = SessionService.defaultGuestDailyLimit.obs;
  final guestDailyLimit = SessionService.defaultGuestDailyLimit.obs;
  final guestRecipeLimit = SessionService.defaultGuestRecipeLimit.obs;
  final currentUser = Rxn<UserModel>();

  final TextEditingController ingredientTextController = TextEditingController();
  final FocusNode ingredientFocusNode = FocusNode();

  StreamSubscription<UserMode?>? _modeSubscription;
  StreamSubscription<int>? _guestQuotaSubscription;
  StreamSubscription<UserModel?>? _userSubscription;
  StreamSubscription<int>? _guestDailyLimitSubscription;
  StreamSubscription<int>? _guestRecipeLimitSubscription;

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
    guestDailyLimit.value = sessionService.guestDailyLimit;
    guestRecipeLimit.value = sessionService.guestRecipeLimit;
    _guestDailyLimitSubscription =
        sessionService.guestDailyLimitStream.listen((value) {
      guestDailyLimit.value = value;
      _syncGuestQuota();
    });
    _guestRecipeLimitSubscription =
        sessionService.guestRecipeLimitStream.listen((value) {
      guestRecipeLimit.value = value;
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
    final sanitizedIngredients = ingredients
        .map((ingredient) => ingredient.trim())
        .where((ingredient) => ingredient.isNotEmpty)
        .toList();

    if (sanitizedIngredients.isEmpty) {
      const message = 'Adicione ao menos um ingrediente.';
      errorMessage.value = message;
      recipes.clear();
      AppSnackbar.warning(
        title: 'Nada para buscar',
        message: message,
      );
      return;
    }

    if (sessionService.isGuest && !sessionService.canPerformGuestSearch()) {
      const message =
          'Você atingiu o limite diário de buscas no modo visitante. O login social estará disponível em breve para liberar buscas ilimitadas.';
      errorMessage.value = message;
      recipes.clear();
      AppSnackbar.info(
        title: 'Limite diário atingido',
        message: message,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final results = await generateRecipesUseCase(
        ingredients: sanitizedIngredients,
        user: sessionService.user,
      );
      final adjustedResults = sessionService.isGuest
          ? results.take(sessionService.guestRecipeLimit).toList()
          : results;
      recipes.assignAll(adjustedResults);
      if (sessionService.isGuest) {
        await sessionService.registerGuestSearch();
        _syncGuestQuota();
      }

      if (adjustedResults.isNotEmpty) {
        await recipeHistoryService.cacheResult(
          cacheKey: _buildCacheKey(sanitizedIngredients),
          ingredients: sanitizedIngredients,
          recipes: adjustedResults,
        );
      }

      String? helperMessage;
      if (adjustedResults.isEmpty) {
        helperMessage = 'Não encontramos receitas com esses ingredientes.';
        errorMessage.value = helperMessage;
        AppSnackbar.info(
          title: 'Nenhuma combinação encontrada',
          message: helperMessage,
        );
      }

      Get.toNamed(
        AppRoutes.recipeResults,
        arguments: RecipeResultsArgs(
          recipes: adjustedResults,
          ingredients: List<String>.from(sanitizedIngredients),
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
      final fallback =
          await recipeHistoryService.fetchLastResult(_buildCacheKey(sanitizedIngredients));
      if (fallback != null) {
        final fallbackRecipes = sessionService.isGuest
            ? fallback.recipes.take(sessionService.guestRecipeLimit).toList()
            : fallback.recipes;
        recipes.assignAll(fallbackRecipes);
        final infoMessage =
            'Mostrando receitas salvas da sua última busca em ${_formatTimestamp(fallback.timestamp)}.';
        errorMessage.value = null;
        AppSnackbar.info(
          title: 'Sugestões offline',
          message: infoMessage,
        );
        Get.toNamed(
          AppRoutes.recipeResults,
          arguments: RecipeResultsArgs(
            recipes: fallbackRecipes,
            ingredients: fallback.ingredients,
            message: infoMessage,
          ),
        );
      } else {
        AppSnackbar.error(
          title: 'Não foi possível gerar receitas',
          message: message,
        );
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
    _userSubscription?.cancel();
    _guestDailyLimitSubscription?.cancel();
    _guestRecipeLimitSubscription?.cancel();
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

  String _buildCacheKey(List<String> ingredients) {
    final normalized = ingredients
        .map((ingredient) => ingredient.trim().toLowerCase())
        .where((ingredient) => ingredient.isNotEmpty)
        .toList()
      ..sort();
    final userId = sessionService.user?.id ?? 'guest';
    return '$userId::${normalized.join('|')}';
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} às $hour:$minute';
  }
}
