import 'dart:async';

import 'package:receitagora/models/nutrition/diet_plan.dart';

import 'package:receitagora/services/location/location_service.dart';

class RestaurantFocus {
  const RestaurantFocus({
    required this.id,
    required this.label,
    required this.tags,
    this.description,
    this.emoji,
  });

  final String id;
  final String label;
  final Set<String> tags;
  final String? description;
  final String? emoji;
}

class RestaurantSuggestion {
  const RestaurantSuggestion({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.primaryCuisine,
    required this.priceRange,
    required this.rating,
    required this.specialties,
    required this.dietHighlights,
    required this.services,
    this.distanceKm,
  });

  final String id;
  final String name;
  final String city;
  final String address;
  final String primaryCuisine;
  final String priceRange;
  final double rating;
  final List<String> specialties;
  final List<String> dietHighlights;
  final List<String> services;
  final double? distanceKm;

  RestaurantSuggestion copyWith({double? distanceKm}) {
    return RestaurantSuggestion(
      id: id,
      name: name,
      city: city,
      address: address,
      primaryCuisine: primaryCuisine,
      priceRange: priceRange,
      rating: rating,
      specialties: specialties,
      dietHighlights: dietHighlights,
      services: services,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}

class RestaurantSearchResult {
  const RestaurantSearchResult({
    required this.restaurants,
    required this.resolvedLocationLabel,
    this.appliedFocus,
    this.referenceCoordinates,
  });

  final List<RestaurantSuggestion> restaurants;
  final String resolvedLocationLabel;
  final RestaurantFocus? appliedFocus;
  final LocationCoordinates? referenceCoordinates;
}

abstract class RestaurantDiscoveryService {
  List<RestaurantFocus> baseFocuses();

  List<RestaurantFocus> focusSuggestionsForPlan(NutritionPlan? plan);

  Future<RestaurantSearchResult> searchNearby({
    required double latitude,
    required double longitude,
    RestaurantFocus? focus,
    int limit = 12,
  });

  Future<RestaurantSearchResult> searchByCity({
    required String city,
    RestaurantFocus? focus,
    int limit = 12,
  });
}
