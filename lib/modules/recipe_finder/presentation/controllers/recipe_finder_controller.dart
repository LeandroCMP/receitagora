import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/recipe_entity.dart';
import '../../domain/usecases/generate_recipes_usecase.dart';

class RecipeFinderController extends GetxController {
  RecipeFinderController({required this.generateRecipesUseCase});

  final GenerateRecipesUseCase generateRecipesUseCase;

  final ingredients = <String>[].obs;
  final recipes = <RecipeEntity>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  final TextEditingController ingredientTextController = TextEditingController();
  final FocusNode ingredientFocusNode = FocusNode();

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

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final results = await generateRecipesUseCase(ingredients);
      recipes.assignAll(results);
      if (results.isEmpty) {
        errorMessage.value = 'Não encontramos receitas com esses ingredientes.';
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
    super.onClose();
  }
}
