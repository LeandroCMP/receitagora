import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/models/subscription_plan.dart';
import 'package:receitagora/models/user_model.dart';
import 'package:receitagora/services/auth/auth_service.dart';
import 'package:receitagora/services/billing/billing_exception.dart';
import 'package:receitagora/services/billing/billing_service.dart';
import 'package:receitagora/services/session/session_service.dart';

class UserProfileController extends GetxController {
  UserProfileController({
    required this.sessionService,
    required this.authService,
    required this.billingService,
  });

  final SessionService sessionService;
  final AuthService authService;
  final BillingService billingService;

  late final TextEditingController nameController;
  late final TextEditingController bioController;
  final formKey = GlobalKey<FormState>();

  final isSaving = false.obs;
  final isSigningOut = false.obs;
  final RxBool isOnboarding = false.obs;
  final RxBool isPremiumUser = false.obs;
  final RxBool isBillingBusy = false.obs;

  final RxList<String> dietaryPreferences = <String>[].obs;
  final RxList<String> favoriteCuisines = <String>[].obs;
  final RxList<String> cookingGoals = <String>[].obs;
  final RxList<String> allergies = <String>[].obs;
  final Rxn<SubscriptionPlan> subscriptionPlan = Rxn<SubscriptionPlan>();

  UserModel? get user => sessionService.user;
  String get premiumPriceDisplay {
    final plan = subscriptionPlan.value;
    if (plan?.formattedAmount != null && plan?.intervalLabel != null) {
      return '${plan!.formattedAmount} / ${plan.intervalLabel}';
    }
    return 'R\$ 20,00 / mês';
  }

  static const List<String> dietarySuggestions = <String>[
    'Vegetariano',
    'Vegano',
    'Low carb',
    'Sem glúten',
    'Sem lactose',
  ];

  static const List<String> cuisineSuggestions = <String>[
    'Brasileira',
    'Italiana',
    'Japonesa',
    'Mediterrânea',
    'Mexicana',
  ];

  static const List<String> goalSuggestions = <String>[
    'Reeducação alimentar',
    'Ganhar massa',
    'Perder peso',
    'Economizar tempo',
    'Aprender técnicas novas',
  ];

  static const List<String> allergySuggestions = <String>[
    'Amendoim',
    'Lactose',
    'Glúten',
    'Frutos do mar',
    'Ovos',
  ];

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['onboarding'] == true) {
      isOnboarding.value = true;
    }
    final initialName = sessionService.user?.name ?? '';
    nameController = TextEditingController(text: initialName);
    bioController = TextEditingController(text: sessionService.user?.bio ?? '');
    dietaryPreferences.assignAll(sessionService.user?.dietaryPreferences ?? const <String>[]);
    favoriteCuisines.assignAll(sessionService.user?.favoriteCuisines ?? const <String>[]);
    cookingGoals.assignAll(sessionService.user?.cookingGoals ?? const <String>[]);
    allergies.assignAll(sessionService.user?.allergies ?? const <String>[]);
    subscriptionPlan.value = sessionService.plan;
    isPremiumUser.value = sessionService.hasPremiumAccess;
    _planSubscription = sessionService.planStream.listen((plan) {
      subscriptionPlan.value = plan;
      isPremiumUser.value = sessionService.hasPremiumAccess;
    });
  }

  late final StreamSubscription<SubscriptionPlan?> _planSubscription;

  @override
  void onClose() {
    nameController.dispose();
    bioController.dispose();
    _planSubscription.cancel();
    super.onClose();
  }

  Future<void> saveProfile() async {
    if (isSaving.value) {
      return;
    }

    final formState = formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final newName = nameController.text.trim();
    if (newName.isEmpty) {
      return;
    }

    final bio = bioController.text.trim();

    isSaving.value = true;

    try {
      final updatedUser = await authService.saveProfile(
        displayName: newName,
        bio: bio.isEmpty ? null : bio,
        dietaryPreferences: dietaryPreferences.toList(),
        favoriteCuisines: favoriteCuisines.toList(),
        cookingGoals: cookingGoals.toList(),
        allergies: allergies.toList(),
      );
      _handleProfileSaved(updatedUser);
    } on AuthFailure catch (error) {
      final message = error.message.isEmpty
          ? 'Não foi possível atualizar seu perfil agora. Tente novamente.'
          : error.message;
      AppSnackbar.error(
        title: 'Algo deu errado',
        message: message,
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Algo deu errado',
        message:
            'Ocorreu um erro inesperado ao atualizar seu perfil. Tente novamente.',
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> refreshPlan() async {
    await sessionService.refreshSubscriptionPlan();
  }

  Future<void> openPremiumPlans() async {
    if (isPremiumUser.value) {
      return;
    }
    await Get.toNamed(AppRoutes.premiumPlans);
  }

  Future<void> openIngredientLab() async {
    if (!isPremiumUser.value) {
      await openPremiumPlans();
      return;
    }
    await Get.toNamed(AppRoutes.ingredientLab);
  }

  Future<void> openNutritionPlan() async {
    if (!isPremiumUser.value) {
      await openPremiumPlans();
      return;
    }
    await Get.toNamed(AppRoutes.nutritionPlan);
  }

  Future<void> viewSubscriptionDetails() async {
    final plan = subscriptionPlan.value;
    if (plan == null || plan.subscriptionId == null) {
      AppSnackbar.warning(
        title: 'Plano não encontrado',
        message:
            'Não encontramos uma assinatura ativa para sua conta. Tente atualizar as informações.',
      );
      return;
    }

    if (isBillingBusy.value) {
      return;
    }

    isBillingBusy.value = true;
    try {
      final session = await billingService.createPortalSession();
      final opened = await launchUrl(
        session.url,
        mode: LaunchMode.inAppBrowserView,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );

      if (!opened) {
        AppSnackbar.error(
          title: 'Não foi possível abrir o portal',
          message:
              'Tivemos um problema ao abrir a página de gerenciamento da assinatura. Tente novamente em instantes.',
        );
      }
    } on BillingException catch (error) {
      AppSnackbar.error(
        title: 'Não foi possível abrir o portal',
        message: error.message,
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Erro inesperado',
        message:
            'Não foi possível abrir o portal de assinaturas agora. Tente novamente mais tarde.',
      );
    } finally {
      isBillingBusy.value = false;
    }
  }

  Future<void> requestSubscriptionCancellation() async {
    final plan = subscriptionPlan.value;
    final subscriptionId = plan?.subscriptionId;
    if (subscriptionId == null) {
      AppSnackbar.warning(
        title: 'Assinatura não localizada',
        message:
            'Não encontramos uma assinatura ativa para cancelar. Atualize as informações e tente novamente.',
      );
      return;
    }

    if (isBillingBusy.value) {
      return;
    }

    isBillingBusy.value = true;
    try {
      await billingService.cancelSubscription(subscriptionId);
      AppSnackbar.success(
        title: 'Cancelamento solicitado',
        message:
            'Sua assinatura permanecerá ativa até o fim do ciclo atual e não será renovada automaticamente.',
      );
    } on BillingException catch (error) {
      AppSnackbar.error(
        title: 'Não foi possível cancelar',
        message: error.message,
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Erro inesperado',
        message:
            'Não foi possível cancelar a assinatura agora. Tente novamente mais tarde.',
      );
    } finally {
      isBillingBusy.value = false;
      await refreshPlan();
    }
  }

  Future<void> completeOnboardingWithoutChanges() async {
    if (!isOnboarding.value || isSaving.value) {
      return;
    }

    final currentUser = sessionService.user;
    if (currentUser == null) {
      return;
    }

    isSaving.value = true;

    try {
      final updatedUser = await authService.saveProfile(
        displayName: currentUser.name,
        bio: currentUser.bio,
        dietaryPreferences: currentUser.dietaryPreferences,
        favoriteCuisines: currentUser.favoriteCuisines,
        cookingGoals: currentUser.cookingGoals,
        allergies: currentUser.allergies,
      );
      _handleProfileSaved(updatedUser, showFeedback: false);
      AppSnackbar.success(
        title: 'Perfil revisado',
        message: 'Você pode atualizar estas informações a qualquer momento.',
      );
    } on AuthFailure catch (error) {
      final message = error.message.isEmpty
          ? 'Não conseguimos confirmar suas informações agora. Tente novamente.'
          : error.message;
      AppSnackbar.error(
        title: 'Algo deu errado',
        message: message,
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Algo deu errado',
        message: 'Não conseguimos concluir esta etapa agora. Tente novamente em instantes.',
      );
    } finally {
      isSaving.value = false;
    }
  }

  void togglePreference(ProfilePreferenceCategory category, String value) {
    final target = _listForCategory(category);
    final sanitized = value.trim();
    if (sanitized.isEmpty) {
      return;
    }
    if (target.contains(sanitized)) {
      target.remove(sanitized);
    } else {
      target.add(sanitized);
      target.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }
  }

  Future<void> addCustomPreference(ProfilePreferenceCategory category) async {
    final controller = TextEditingController();
    final confirmed = await Get.dialog<String?>(
      AlertDialog(
        title: const Text('Adicionar item personalizado'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Novo item',
            hintText: 'Informe como quer salvar este item',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: controller.text.trim()),
            child: const Text('Adicionar'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (confirmed == null || confirmed.isEmpty) {
      return;
    }

    final target = _listForCategory(category);
    if (!target.contains(confirmed)) {
      target.add(confirmed);
      target.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }
  }

  RxList<String> _listForCategory(ProfilePreferenceCategory category) {
    switch (category) {
      case ProfilePreferenceCategory.dietary:
        return dietaryPreferences;
      case ProfilePreferenceCategory.cuisine:
        return favoriteCuisines;
      case ProfilePreferenceCategory.goal:
        return cookingGoals;
      case ProfilePreferenceCategory.allergy:
        return allergies;
    }
  }

  RxList<String> preferencesFor(ProfilePreferenceCategory category) {
    return _listForCategory(category);
  }

  Future<void> signOut() async {
    if (isSigningOut.value) {
      return;
    }

    isSigningOut.value = true;

    try {
      await authService.signOut();
      await Get.offAllNamed(AppRoutes.login);
    } on AuthFailure catch (error) {
      final message = error.message.isEmpty
          ? 'Não foi possível encerrar a sessão agora. Tente novamente.'
          : error.message;
      AppSnackbar.error(
        title: 'Algo deu errado',
        message: message,
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Algo deu errado',
        message: 'Não conseguimos encerrar sua sessão. Tente novamente em instantes.',
      );
    } finally {
      isSigningOut.value = false;
    }
  }

  void _handleProfileSaved(
    UserModel updatedUser, {
    bool showFeedback = true,
  }) {
    nameController.text = updatedUser.name;
    dietaryPreferences.assignAll(updatedUser.dietaryPreferences);
    favoriteCuisines.assignAll(updatedUser.favoriteCuisines);
    cookingGoals.assignAll(updatedUser.cookingGoals);
    allergies.assignAll(updatedUser.allergies);
    bioController.text = updatedUser.bio ?? '';

    if (showFeedback) {
      AppSnackbar.success(
        title: 'Perfil atualizado',
        message: 'Suas preferências foram sincronizadas com sucesso.',
      );
    }

    if (isOnboarding.value && updatedUser.profileCompleted) {
      isOnboarding.value = false;
      Get.offAllNamed(AppRoutes.recipeFinder);
    }
  }
}

enum ProfilePreferenceCategory { dietary, cuisine, goal, allergy }
