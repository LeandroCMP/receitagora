import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/application/utils/app_loading.dart';
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
  final guestRecipesRemaining = SessionService.defaultGuestMonthlyLimit.obs;
  final guestMonthlyLimit = SessionService.defaultGuestMonthlyLimit.obs;
  final guestRecipeLimit = SessionService.defaultGuestRecipeLimit.obs;
  final authenticatedMonthlyLimit =
      SessionService.defaultAuthenticatedMonthlyLimit.obs;
  final shareMonthlyLimit = SessionService.defaultShareMonthlyLimit.obs;
  final isPremiumPlan = false.obs;
  final currentUser = Rxn<UserModel>();

  final TextEditingController ingredientTextController = TextEditingController();
  final FocusNode ingredientFocusNode = FocusNode();

  StreamSubscription<UserMode?>? _modeSubscription;
  StreamSubscription<int>? _guestQuotaSubscription;
  StreamSubscription<UserModel?>? _userSubscription;
  StreamSubscription<int>? _guestMonthlyLimitSubscription;
  StreamSubscription<int>? _guestRecipeLimitSubscription;
  StreamSubscription<int>? _authenticatedMonthlyLimitSubscription;
  StreamSubscription<int>? _shareMonthlyLimitSubscription;
  StreamSubscription? _planSubscription;

  @override
  void onInit() {
    super.onInit();
    _syncSessionState();
    _modeSubscription = sessionService.modeStream.listen((_) => _syncSessionState());
    _guestQuotaSubscription =
        sessionService.guestRecipeCountStream.listen((_) => _syncGuestQuota());
    _userSubscription = sessionService.userStream.listen((user) {
      currentUser.value = user;
    });
    guestMonthlyLimit.value = sessionService.guestMonthlyLimit;
    guestRecipeLimit.value = sessionService.guestRecipeLimit;
    authenticatedMonthlyLimit.value = sessionService.authenticatedMonthlyLimit;
    shareMonthlyLimit.value = sessionService.shareMonthlyLimit;
    isPremiumPlan.value = sessionService.isPremium;
    _guestMonthlyLimitSubscription =
        sessionService.guestMonthlyLimitStream.listen((value) {
      guestMonthlyLimit.value = value;
      _syncGuestQuota();
    });
    _guestRecipeLimitSubscription =
        sessionService.guestRecipeLimitStream.listen((value) {
      guestRecipeLimit.value = value;
    });
    _authenticatedMonthlyLimitSubscription =
        sessionService.authenticatedMonthlyLimitStream.listen((value) {
      authenticatedMonthlyLimit.value = value;
    });
    _shareMonthlyLimitSubscription =
        sessionService.shareMonthlyLimitStream.listen((value) {
      shareMonthlyLimit.value = value;
    });
    _planSubscription = sessionService.planStream.listen((_) {
      isPremiumPlan.value = sessionService.isPremium;
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

    if (sessionService.isGuest &&
        !sessionService.canGenerateGuestRecipes()) {
      final limit = sessionService.guestMonthlyLimit;
      final upgradeLimit = sessionService.authenticatedMonthlyLimit;
      final message =
          'Você atingiu o limite mensal de $limit receitas no modo visitante. Faça login para liberar $upgradeLimit receitas por mês e histórico ampliado.';
      errorMessage.value = message;
      recipes.clear();
      AppSnackbar.info(
        title: 'Limite mensal atingido',
        message: message,
        duration: const Duration(seconds: 5),
      );
      return;
    } else if (sessionService.isAuthenticated &&
        !sessionService.canGenerateAuthenticatedRecipes()) {
      final limit = sessionService.authenticatedMonthlyLimit;
      final message =
          'Você atingiu o limite mensal de $limit receitas do plano gratuito. Assine o ReceitaAgora Premium para desbloquear receitas ilimitadas e históricos ampliados.';
      errorMessage.value = message;
      recipes.clear();
      AppSnackbar.info(
        title: 'Limite mensal atingido',
        message: message,
        duration: const Duration(seconds: 5),
      );
      Get.toNamed(AppRoutes.paywall);
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    await AppLoading.showBlocking();

    try {
      final results = await generateRecipesUseCase(
        ingredients: sanitizedIngredients,
        user: sessionService.user,
      );
      final List<RecipeEntity> adjustedResults;
      if (sessionService.isGuest) {
        final available = sessionService.guestRecipesRemaining;
        final cap = available < sessionService.guestRecipeLimit
            ? available
            : sessionService.guestRecipeLimit;
        adjustedResults =
            cap > 0 ? results.take(cap).toList() : <RecipeEntity>[];
      } else {
        final available = sessionService.authenticatedRecipesRemaining;
        adjustedResults = available <= 0
            ? <RecipeEntity>[]
            : (available < results.length
                ? results.take(available).toList()
                : results);
      }

      recipes.assignAll(adjustedResults);
      final generatedCount = adjustedResults.length;
      if (generatedCount > 0) {
        if (sessionService.isGuest) {
          await sessionService.registerGuestRecipes(generatedCount);
          _syncGuestQuota();
        } else if (sessionService.isAuthenticated) {
          await sessionService.registerAuthenticatedRecipes(generatedCount);
        }
      }

      if (adjustedResults.isNotEmpty) {
        await recipeHistoryService.cacheResult(
          cacheKey: _buildCacheKey(sanitizedIngredients),
          ingredients: sanitizedIngredients,
          recipes: adjustedResults,
        );
      }

      AppLoading.hide();
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
      AppLoading.hide();
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
      AppLoading.hide();
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
    _guestMonthlyLimitSubscription?.cancel();
    _guestRecipeLimitSubscription?.cancel();
    _authenticatedMonthlyLimitSubscription?.cancel();
    _shareMonthlyLimitSubscription?.cancel();
    _planSubscription?.cancel();
    super.onClose();
  }

  void _syncSessionState() {
    isGuest.value = sessionService.isGuest;
    currentUser.value = sessionService.user;
    isPremiumPlan.value = sessionService.isPremium;
    _syncGuestQuota();
  }

  void _syncGuestQuota() {
    guestRecipesRemaining.value = sessionService.guestRecipesRemaining;
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
