import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/services/location/location_service.dart';
import 'package:receitagora/services/nutrition/nutrition_plan_service.dart';
import 'package:receitagora/services/restaurants/restaurant_discovery_service.dart';

enum RestaurantSearchMode { currentLocation, manualCity }

class RestaurantDiscoveryController extends GetxController {
  RestaurantDiscoveryController({
    required this.discoveryService,
    required this.locationService,
    required this.nutritionPlanService,
  });

  final RestaurantDiscoveryService discoveryService;
  final LocationService locationService;
  final NutritionPlanService nutritionPlanService;

  final Rx<RestaurantSearchMode> searchMode = RestaurantSearchMode.currentLocation.obs;
  final Rxn<RestaurantFocus> selectedFocus = Rxn<RestaurantFocus>();
  final RxList<RestaurantFocus> baseFocuses = <RestaurantFocus>[].obs;
  final RxList<RestaurantFocus> planFocuses = <RestaurantFocus>[].obs;
  final RxList<RestaurantSuggestion> results = <RestaurantSuggestion>[].obs;
  final RxBool isLoading = false.obs;
  final Rxn<String> resolvedArea = Rxn<String>();
  final Rxn<String> feedbackMessage = Rxn<String>();
  final Rxn<LocationCoordinates> lastCoordinates = Rxn<LocationCoordinates>();
  final Rxn<String> manualCityError = Rxn<String>();

  final TextEditingController cityController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    baseFocuses.assignAll(discoveryService.baseFocuses());
    _loadPlanFocuses();
  }

  @override
  void onClose() {
    cityController.dispose();
    super.onClose();
  }

  void setSearchMode(RestaurantSearchMode mode) {
    if (searchMode.value == mode) {
      return;
    }
    searchMode.value = mode;
    if (mode == RestaurantSearchMode.currentLocation) {
      manualCityError.value = null;
    }
  }

  void toggleFocus(RestaurantFocus focus) {
    if (selectedFocus.value?.id == focus.id) {
      selectedFocus.value = null;
    } else {
      selectedFocus.value = focus;
    }
  }

  void clearFocus() {
    selectedFocus.value = null;
  }

  Future<void> refreshPlanFocuses() async {
    await _loadPlanFocuses();
  }

  Future<void> executeSearch({bool forceRefreshLocation = false}) async {
    if (isLoading.value) {
      return;
    }

    manualCityError.value = null;
    feedbackMessage.value = null;

    final focus = selectedFocus.value;

    if (searchMode.value == RestaurantSearchMode.manualCity) {
      final city = cityController.text.trim();
      if (city.isEmpty) {
        manualCityError.value = 'Informe a cidade para iniciar a busca.';
        return;
      }
      await _searchByCity(city: city, focus: focus, limit: 12);
      return;
    }

    await _searchByLocation(focus: focus, forceRefresh: forceRefreshLocation);
  }

  Future<void> _searchByLocation({
    RestaurantFocus? focus,
    bool forceRefresh = false,
  }) async {
    isLoading.value = true;
    try {
      final status = await locationService.ensurePermission();
      switch (status) {
        case LocationPermissionStatus.servicesDisabled:
          AppSnackbar.warning(
            title: 'Localização desativada',
            message: 'Ative o GPS do dispositivo ou busque por uma cidade manualmente.',
          );
          feedbackMessage.value =
              'Não foi possível acessar sua localização. Informe uma cidade ou tente novamente.';
          isLoading.value = false;
          return;
        case LocationPermissionStatus.denied:
          AppSnackbar.warning(
            title: 'Permissão necessária',
            message: 'Autorize o acesso à localização para encontrar restaurantes próximos.',
          );
          feedbackMessage.value =
              'O acesso à localização foi negado. Autorize o uso ou informe uma cidade.';
          isLoading.value = false;
          return;
        case LocationPermissionStatus.permanentlyDenied:
          AppSnackbar.error(
            title: 'Ative a permissão',
            message:
                'Abra as configurações do app e permita o acesso à localização para usar o mapa de restaurantes.',
          );
          feedbackMessage.value =
              'Sem permissão de localização. Ajuste nas configurações ou utilize a busca por cidade.';
          isLoading.value = false;
          return;
        case LocationPermissionStatus.granted:
          break;
      }

      final coordinates = await locationService.getCurrentPosition(forceFresh: forceRefresh);
      if (coordinates == null) {
        feedbackMessage.value =
            'Não conseguimos determinar sua posição. Verifique o GPS ou tente novamente mais tarde.';
        AppSnackbar.error(
          title: 'Localização indisponível',
          message: 'Não foi possível obter sua posição atual.',
        );
        return;
      }

      final result = await discoveryService.searchNearby(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        focus: focus,
      );

      lastCoordinates.value = coordinates;
      resolvedArea.value = result.resolvedLocationLabel;
      results.assignAll(result.restaurants);

      if (result.restaurants.isEmpty) {
        feedbackMessage.value =
            'Não encontramos restaurantes alinhados ao filtro escolhido nessa região no momento.';
      } else if (focus != null) {
        feedbackMessage.value =
            'Mostrando locais próximos com perfil "${focus.label}" em ${result.resolvedLocationLabel}.';
      } else {
        feedbackMessage.value = 'Resultados próximos em ${result.resolvedLocationLabel}.';
      }
    } catch (_) {
      feedbackMessage.value = 'Não foi possível buscar restaurantes agora. Tente novamente em instantes.';
      AppSnackbar.error(
        title: 'Falha ao buscar restaurantes',
        message: 'Tivemos um problema ao consultar as sugestões próximas.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _searchByCity({
    required String city,
    RestaurantFocus? focus,
    int limit = 12,
  }) async {
    isLoading.value = true;
    try {
      final result = await discoveryService.searchByCity(
        city: city,
        focus: focus,
        limit: limit,
      );
      resolvedArea.value = result.resolvedLocationLabel;
      results.assignAll(result.restaurants);
      lastCoordinates.value = result.referenceCoordinates;

      if (result.restaurants.isEmpty) {
        feedbackMessage.value =
            'Ainda não temos parceiros na região informada dentro do filtro selecionado.';
      } else if (focus != null) {
        feedbackMessage.value =
            'Sugestões em ${result.resolvedLocationLabel} com foco em "${focus.label}".';
      } else {
        feedbackMessage.value = 'Sugestões em ${result.resolvedLocationLabel}.';
      }
    } catch (_) {
      feedbackMessage.value = 'Não foi possível buscar restaurantes para a cidade informada.';
      AppSnackbar.error(
        title: 'Busca indisponível',
        message: 'Verifique sua conexão e tente novamente.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadPlanFocuses() async {
    try {
      final plan = await nutritionPlanService.fetchCurrentPlan();
      final focuses = discoveryService.focusSuggestionsForPlan(plan);
      planFocuses.assignAll(focuses);
      if (selectedFocus.value == null && focuses.isNotEmpty) {
        selectedFocus.value = focuses.first;
      }
    } catch (_) {
      planFocuses.clear();
    }
  }
}
