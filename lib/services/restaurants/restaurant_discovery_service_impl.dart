import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:receitagora/models/nutrition/diet_plan.dart';
import 'package:receitagora/models/nutrition/diet_profile.dart';
import 'package:receitagora/services/location/location_service.dart';

import 'restaurant_discovery_service.dart';

class RestaurantDiscoveryServiceImpl implements RestaurantDiscoveryService {
  RestaurantDiscoveryServiceImpl({
    http.Client? httpClient,
    Duration httpTimeout = const Duration(seconds: 20),
    this.searchRadiusMeters = 4000,
    String? googlePlacesApiKey,
  })  : _httpClient = httpClient ?? http.Client(),
        _httpTimeout = httpTimeout,
        _apiKey =
            (googlePlacesApiKey ?? dotenv.maybeGet('GOOGLE_PLACES_API_KEY') ?? '')
                .trim();

  final http.Client _httpClient;
  final Duration _httpTimeout;
  final int searchRadiusMeters;
  final String _apiKey;

  static const String _placesBaseUrl =
      'https://maps.googleapis.com/maps/api/place';
  static const String _geocodeEndpoint =
      'https://maps.googleapis.com/maps/api/geocode/json';

  static const Map<String, String> _defaultHeaders = {
    'Accept': 'application/json',
    'User-Agent': 'ReceitagoraApp/1.0 (+https://receitagora.app)',
  };

  static const List<RestaurantFocus> _focusCatalog = [
    RestaurantFocus(
      id: 'balanced',
      label: 'Equilíbrio saudável',
      emoji: '🥗',
      description:
          'Bowls, saladas e grelhados leves para manter o cardápio em dia sem abrir mão do sabor.',
      tags: {
        'balanced',
        'leve',
        'salada',
        'salad',
        'integral',
        'natural',
        'lowcarb',
        'saudavel',
        'healthy',
        'healthfood',
        'fit',
        'poke',
        'lightmeal',
      },
    ),
    RestaurantFocus(
      id: 'high_protein',
      label: 'Proteínas em destaque',
      emoji: '🥩',
      description: 'Churrascarias, parrillas e casas de grelhados ricas em proteína.',
      tags: {
        'proteina',
        'proteinas',
        'carne',
        'carnes',
        'churrasco',
        'grelhado',
        'parrilla',
        'rodizio',
        'steak',
        'steakhouse',
        'bbq',
        'barbecue',
        'grill',
        'meat',
        'churrascaria',
      },
    ),
    RestaurantFocus(
      id: 'comfort_br',
      label: 'Caseiro brasileiro',
      emoji: '🍛',
      description: 'PF equilibrado, pratos regionais e comida afetiva bem servida.',
      tags: {
        'caseiro',
        'caseira',
        'brasileira',
        'regional',
        'comfort',
        'brazilian',
        'pf',
        'prato',
        'pratofeito',
        'comidacaseira',
        'popular',
      },
    ),
    RestaurantFocus(
      id: 'italian',
      label: 'Massas e risotos',
      emoji: '🍝',
      description: 'Cantinas e fornerias com massas artesanais e risotos cremosos.',
      tags: {
        'massas',
        'massa',
        'italiano',
        'italiana',
        'risoto',
        'risotto',
        'pizza',
        'pasta',
        'cantina',
        'pizzeria',
      },
    ),
    RestaurantFocus(
      id: 'seafood',
      label: 'Peixes e frutos do mar',
      emoji: '🐟',
      description: 'Grelhados leves, moquecas e pratos do mar cheios de frescor.',
      tags: {
        'peixe',
        'peixes',
        'frutosdomar',
        'seafood',
        'fish',
        'mar',
        'sushi',
        'marisco',
        'mariscos',
      },
    ),
    RestaurantFocus(
      id: 'vegetarian',
      label: 'Vegetariano & vegano',
      emoji: '🥦',
      description: 'Cozinha plant-based criativa com ingredientes orgânicos e integrais.',
      tags: {
        'vegetariano',
        'vegetarian',
        'vegano',
        'vegan',
        'plantbased',
        'plant_based',
        'natural',
        'integral',
        'organic',
        'wholefood',
      },
    ),
    RestaurantFocus(
      id: 'light',
      label: 'Refeições leves',
      emoji: '🥙',
      description: 'Bowls frescos, wraps funcionais e lanches rápidos sem pesar.',
      tags: {
        'leve',
        'light',
        'lowcarb',
        'wrap',
        'wraps',
        'bowl',
        'salada',
        'salad',
        'poke',
        'healthy',
        'fit',
        'sandwich',
      },
    ),
  ];

  static const Map<String, List<String>> _focusQueryOverrides = {
    'balanced': ['saladas', 'bowls', 'refeições saudáveis'],
    'high_protein': ['churrascaria', 'carnes', 'grelhados'],
    'comfort_br': ['comida caseira', 'pf', 'prato feito'],
    'italian': ['massas', 'cantina italiana'],
    'seafood': ['frutos do mar', 'peixes'],
    'vegetarian': ['vegetariano', 'vegano'],
    'light': ['refeições leves', 'saladas'],
  };

  static const Map<String, Set<String>> _focusTokenHints = {
    'vegetarian': <String>{
      'vegetariano',
      'vegetarianos',
      'vegetariana',
      'vegetarianas',
      'vegetarian',
      'vegano',
      'vegana',
      'veganos',
      'veganas',
      'vegan',
      'plantbased',
      'plantforward',
      'semcarne',
      'semcarnevermelha',
      'semcarnevermelhas',
      'semcarnevermelho',
      'semcarnevermelhos',
      'tofu',
      'graodebico',
      'lentilha',
      'lentilhas',
      'leguminosa',
      'leguminosas',
    },
    'seafood': <String>{
      'seafood',
      'frutosdomar',
      'peixe',
      'peixes',
      'peixebranco',
      'peixegrelhado',
      'peixeespada',
      'salmao',
      'tilapia',
      'atum',
      'sardinha',
      'sardinhas',
      'bacalhau',
      'robalo',
      'dourado',
      'anchova',
      'camarao',
      'camaroes',
      'camaraozinho',
      'camaraozinhos',
      'lula',
      'polvo',
      'ostra',
      'ostras',
      'vieira',
      'vieiras',
      'marisco',
      'mariscos',
      'moqueca',
      'ceviche',
      'sushi',
    },
  };

  final Map<String, Set<String>> _focusKeywordCache = {};

  @override
  List<RestaurantFocus> baseFocuses() => _focusCatalog;

  @override
  List<RestaurantFocus> focusSuggestionsForPlan(NutritionPlan? plan) {
    if (plan == null) {
      return const <RestaurantFocus>[];
    }

    final profile = plan.profile;
    final ids = <String>{};

    switch (profile.goal) {
      case DietGoal.gainMass:
        ids.addAll({'high_protein', 'balanced'});
        break;
      case DietGoal.loseWeight:
        ids.addAll({'balanced', 'light', 'seafood'});
        break;
      case DietGoal.maintain:
        ids.addAll({'balanced', 'comfort_br', 'seafood'});
        break;
      case DietGoal.reeducate:
        ids.addAll({'balanced', 'light', 'vegetarian'});
        break;
    }

    ids.addAll(_inferFocusIdsFromPlan(plan));

    return _focusCatalog.where((focus) => ids.contains(focus.id)).toList(growable: false);
  }

  Set<String> _inferFocusIdsFromPlan(NutritionPlan plan) {
    final tokens = _collectPlanTokens(plan);
    final inferred = <String>{};

    bool intersects(Set<String> hints) {
      for (final token in tokens) {
        if (hints.contains(token)) {
          return true;
        }
      }
      return false;
    }

    for (final entry in _focusTokenHints.entries) {
      if (intersects(entry.value)) {
        inferred.add(entry.key);
      }
    }

    return inferred;
  }

  Set<String> _collectPlanTokens(NutritionPlan plan) {
    final tokens = <String>{};

    void collect(String? text) {
      if (text == null) {
        return;
      }
      final trimmed = text.trim();
      if (trimmed.isEmpty) {
        return;
      }
      tokens.addAll(_normalizeKeywords(trimmed));
    }

    void collectAll(Iterable<String>? values) {
      if (values == null) {
        return;
      }
      for (final value in values) {
        collect(value);
      }
    }

    final dietPlan = plan.plan;

    collect(plan.profile.additionalNotes);
    collect(dietPlan.strategy);
    collect(dietPlan.hydrationGoal);
    collect(dietPlan.mindfulBreakMessage);
    collect(dietPlan.sleepRoutine.message);
    collect(dietPlan.sleepRoutine.windDownSummary);
    collectAll(dietPlan.sleepRoutine.windDownTips);
    collect(dietPlan.wellnessDigest.summary);
    collect(dietPlan.wellnessDigest.callToAction);
    collectAll(dietPlan.wellnessDigest.highlights);
    collect(dietPlan.sunlightRoutine.message);
    collectAll(dietPlan.sunlightRoutine.benefits);
    collectAll(dietPlan.sunlightRoutine.cautions);
    collectAll(dietPlan.followUpTips);
    collectAll(dietPlan.highlights);
    collectAll(dietPlan.movementRoutine.tips);
    collectAll(dietPlan.hydrationPlan.reminders.map((slot) => slot.label));

    for (final day in dietPlan.days) {
      collect(day.focus);
      collect(day.label);
      for (final meal in day.meals) {
        collect(meal.name);
        collect(meal.description);
        collect(meal.macroFocus);
        collect(meal.prepNotes);
        collectAll(meal.ingredients);
        collectAll(meal.steps);
      }
    }

    for (final item in dietPlan.shoppingList) {
      collect(item.category);
      collect(item.item);
      collect(item.notes);
      collect(item.substitutionNote);
      collectAll(item.alternatives);
    }

    return tokens;
  }

  @override
  Future<RestaurantSearchResult> searchNearby({
    required double latitude,
    required double longitude,
    RestaurantFocus? focus,
    int limit = 20,
  }) async {
    _ensureApiKey();

    final reference = LocationCoordinates(latitude: latitude, longitude: longitude);
    final resolvedLabel =
        await _reverseGeocodeLabel(latitude: latitude, longitude: longitude) ??
            'Sua localização';

    final rawResults = await _fetchNearbyPlaces(
      latitude: latitude,
      longitude: longitude,
      focus: focus,
      limitHint: limit,
    );

    final suggestions = _buildSuggestions(
      rawResults,
      focus: focus,
      limit: limit,
      reference: reference,
      fallbackCityLabel: resolvedLabel,
    );

    return RestaurantSearchResult(
      restaurants: suggestions,
      resolvedLocationLabel: resolvedLabel,
      appliedFocus: focus,
      referenceCoordinates: reference,
    );
  }

  @override
  Future<RestaurantSearchResult> searchByCity({
    required String city,
    RestaurantFocus? focus,
    int limit = 20,
  }) async {
    _ensureApiKey();

    final geocode = await _geocodeCity(city);
    if (geocode == null) {
      throw Exception('Cidade não encontrada');
    }

    final rawResults = await _fetchCityPlaces(
      geocode: geocode,
      focus: focus,
      limitHint: limit,
    );

    final suggestions = _buildSuggestions(
      rawResults,
      focus: focus,
      limit: limit,
      reference: geocode.coordinates,
      fallbackCityLabel: geocode.label,
    );

    return RestaurantSearchResult(
      restaurants: suggestions,
      resolvedLocationLabel: geocode.label,
      appliedFocus: focus,
      referenceCoordinates: geocode.coordinates,
    );
  }

  void _ensureApiKey() {
    if (_apiKey.isEmpty) {
      throw Exception(
        'A chave da API do Google Places não foi configurada. Defina GOOGLE_PLACES_API_KEY no .env.',
      );
    }
  }

  Future<List<_GooglePlace>> _fetchNearbyPlaces({
    required double latitude,
    required double longitude,
    required int limitHint,
    RestaurantFocus? focus,
  }) async {
    final params = {
      'key': _apiKey,
      'location': '$latitude,$longitude',
      'radius': searchRadiusMeters.toString(),
      'type': 'restaurant',
      'language': 'pt-BR',
    };

    final keyword = _keywordForFocus(focus);
    if (keyword != null) {
      params['keyword'] = keyword;
    }

    final results = await _fetchPlaces(
      endpoint: 'nearbysearch',
      baseParams: params,
      limitHint: limitHint,
    );

    return results;
  }

  Future<List<_GooglePlace>> _fetchCityPlaces({
    required _GeocodeResult geocode,
    required int limitHint,
    RestaurantFocus? focus,
  }) async {
    final params = {
      'key': _apiKey,
      'query': _composeCityQuery(geocode.label, focus),
      'language': 'pt-BR',
      'type': 'restaurant',
      'location':
          '${geocode.coordinates.latitude},${geocode.coordinates.longitude}',
      'radius': (geocode.suggestedRadiusMeters ?? searchRadiusMeters).toString(),
    };

    final results = await _fetchPlaces(
      endpoint: 'textsearch',
      baseParams: params,
      limitHint: limitHint,
    );

    return results;
  }

  Future<List<_GooglePlace>> _fetchPlaces({
    required String endpoint,
    required Map<String, String> baseParams,
    required int limitHint,
  }) async {
    final aggregated = <_GooglePlace>[];
    String? nextPageToken;
    var page = 0;

    do {
      final params = Map<String, String>.from(baseParams);
      if (nextPageToken != null) {
        params['pagetoken'] = nextPageToken;
      }

      final response = await _performPlacesRequest(endpoint, params);
      aggregated.addAll(response.results);
      nextPageToken = response.nextPageToken;
      page += 1;

      if (nextPageToken != null && aggregated.length < limitHint) {
        await Future<void>.delayed(const Duration(seconds: 2));
      } else {
        break;
      }
    } while (aggregated.length < limitHint && nextPageToken != null && page < 3);

    return aggregated;
  }

  Future<_PlacesResponse> _performPlacesRequest(
    String endpoint,
    Map<String, String> params,
  ) async {
    final uri = Uri.parse('$_placesBaseUrl/$endpoint/json')
        .replace(queryParameters: params);
    final response =
        await _httpClient.get(uri, headers: _defaultHeaders).timeout(_httpTimeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao consultar restaurantes (status ${response.statusCode}).',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final status = payload['status'] as String? ?? 'UNKNOWN';

    if (status == 'ZERO_RESULTS') {
      return const _PlacesResponse(results: <_GooglePlace>[]);
    }

    if (status != 'OK') {
      final message = payload['error_message'] as String?;
      throw Exception(
        'Google Places retornou "$status"${message != null ? ': $message' : ''}.',
      );
    }

    final results = (payload['results'] as List<dynamic>? ?? const [])
        .map((item) => _GooglePlace.fromJson(item as Map<String, dynamic>?))
        .whereType<_GooglePlace>()
        .toList(growable: false);

    return _PlacesResponse(
      results: results,
      nextPageToken: payload['next_page_token'] as String?,
    );
  }

  Future<String?> _reverseGeocodeLabel({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_geocodeEndpoint).replace(queryParameters: {
      'latlng': '$latitude,$longitude',
      'language': 'pt-BR',
      'key': _apiKey,
      'result_type': 'locality|administrative_area_level_3|administrative_area_level_2',
    });

    final response =
        await _httpClient.get(uri, headers: _defaultHeaders).timeout(_httpTimeout);
    if (response.statusCode != 200) {
      return null;
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final status = payload['status'] as String? ?? 'UNKNOWN';
    if (status != 'OK') {
      return null;
    }

    final results = payload['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) {
      return null;
    }

    final first = results.first as Map<String, dynamic>;
    final components = first['address_components'] as List<dynamic>?;
    final label = _composeLabelFromComponents(components);
    return label ?? (first['formatted_address'] as String?);
  }

  Future<_GeocodeResult?> _geocodeCity(String city) async {
    final uri = Uri.parse(_geocodeEndpoint).replace(queryParameters: {
      'address': city,
      'language': 'pt-BR',
      'key': _apiKey,
    });

    final response =
        await _httpClient.get(uri, headers: _defaultHeaders).timeout(_httpTimeout);
    if (response.statusCode != 200) {
      return null;
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final status = payload['status'] as String? ?? 'UNKNOWN';
    if (status != 'OK' || payload['results'] == null) {
      return null;
    }

    final results = payload['results'] as List<dynamic>;
    if (results.isEmpty) {
      return null;
    }

    final first = results.first as Map<String, dynamic>;
    final geometry = first['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final lat = (location?['lat'] as num?)?.toDouble();
    final lng = (location?['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) {
      return null;
    }

    final label = _composeLabelFromComponents(
          (first['address_components'] as List<dynamic>?),
        ) ??
        (first['formatted_address'] as String?) ??
        city.trim();

    final viewport = geometry?['viewport'] as Map<String, dynamic>?;
    final suggestedRadius = _radiusFromViewport(viewport, lat, lng);

    return _GeocodeResult(
      coordinates: LocationCoordinates(latitude: lat, longitude: lng),
      label: label,
      suggestedRadiusMeters: suggestedRadius,
    );
  }

  String _composeCityQuery(String label, RestaurantFocus? focus) {
    final parts = <String>['restaurantes'];
    final keyword = _keywordForFocus(focus);
    if (keyword != null) {
      parts.add(keyword);
    }
    parts.add('em $label');
    return parts.join(' ');
  }

  String? _keywordForFocus(RestaurantFocus? focus) {
    if (focus == null) {
      return null;
    }

    final seen = <String>{};
    final parts = <String>[];

    final override = _focusQueryOverrides[focus.id];
    if (override != null) {
      for (final item in override) {
        final normalized = item.trim();
        if (normalized.isEmpty) {
          continue;
        }
        if (seen.add(normalized.toLowerCase())) {
          parts.add(normalized);
        }
      }
    }

    final focusLabel = focus.label.trim();
    if (focusLabel.isNotEmpty && seen.add(focusLabel.toLowerCase())) {
      parts.add(focusLabel);
    }

    final tagList = focus.tags.toList()..sort();
    for (final tag in tagList) {
      final normalized = tag.replaceAll('_', ' ').trim();
      if (normalized.isEmpty) {
        continue;
      }
      if (seen.add(normalized.toLowerCase())) {
        parts.add(normalized);
      }
      if (parts.length >= 4) {
        break;
      }
    }

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(' ');
  }

  List<RestaurantSuggestion> _buildSuggestions(
    List<_GooglePlace> places, {
    required RestaurantFocus? focus,
    required int limit,
    required LocationCoordinates? reference,
    required String fallbackCityLabel,
  }) {
    if (limit <= 0 || places.isEmpty) {
      return const [];
    }

    final focusMatches = <_SuggestionCandidate>[];
    final generalMatches = <_SuggestionCandidate>[];

    for (final place in places) {
      final candidate = _buildCandidate(
        place,
        reference: reference,
        fallbackCityLabel: fallbackCityLabel,
      );
      if (candidate == null) {
        continue;
      }

      if (focus == null || _matchesFocus(focus, candidate)) {
        focusMatches.add(candidate);
      } else {
        generalMatches.add(candidate);
      }
    }

    focusMatches.sort((a, b) => a.compareTo(b));
    generalMatches.sort((a, b) => a.compareTo(b));

    final ordered = <_SuggestionCandidate>[...focusMatches, ...generalMatches];
    final unique = <String, _SuggestionCandidate>{};
    for (final candidate in ordered) {
      unique.putIfAbsent(candidate.key, () => candidate);
    }

    return unique.values
        .take(limit)
        .map((candidate) => candidate.suggestion)
        .toList(growable: false);
  }

  _SuggestionCandidate? _buildCandidate(
    _GooglePlace place, {
    required LocationCoordinates? reference,
    required String fallbackCityLabel,
  }) {
    final name = place.name.trim();
    if (name.isEmpty) {
      return null;
    }

    final city = place.city ?? fallbackCityLabel;
    final address = place.vicinity ??
        place.formattedAddress ??
        'Endereço não informado';
    final cuisine = _derivePrimaryCuisine(place.types);
    final priceRange = _describePriceRange(place.priceLevel);
    final rating = place.rating ?? 0;
    final specialties = _collectSpecialtyLabels(place, cuisine);
    final dietHighlights = _collectDietHighlights(place);
    final services = _collectServiceLabels(place);
    final distanceKm = reference != null
        ? _distanceInKm(
            reference.latitude,
            reference.longitude,
            place.latitude,
            place.longitude,
          )
        : null;

    final suggestion = RestaurantSuggestion(
      id: place.placeId,
      name: name,
      city: city,
      address: address,
      primaryCuisine: cuisine,
      priceRange: priceRange,
      rating: rating,
      specialties: specialties,
      dietHighlights: dietHighlights,
      services: services,
      distanceKm: distanceKm,
    );

    final featureTags = <String>{
      ..._normalizeKeywords(name),
      ..._normalizeKeywords(cuisine),
      for (final specialty in specialties) ..._normalizeKeywords(specialty),
      for (final diet in dietHighlights) ..._normalizeKeywords(diet),
      for (final service in services) ..._normalizeKeywords(service),
      for (final type in place.types) ..._normalizeKeywords(type),
      ...place.keywordBoost,
    };

    return _SuggestionCandidate(
      place: place,
      suggestion: suggestion,
      featureTags: featureTags,
    );
  }

  bool _matchesFocus(RestaurantFocus? focus, _SuggestionCandidate candidate) {
    if (focus == null) {
      return true;
    }

    final focusKeywords = _focusKeywordCache.putIfAbsent(
      focus.id,
      () => {
        ..._normalizeKeywords(focus.id),
        for (final tag in focus.tags) ..._normalizeKeywords(tag),
        ..._normalizeKeywords(focus.label),
      },
    );

    return candidate.featureTags.any(focusKeywords.contains);
  }

  double? _distanceInKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = earthRadiusKm * c;
    if (distance.isNaN || distance.isInfinite) {
      return null;
    }
    return (distance * 100).roundToDouble() / 100;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  String _derivePrimaryCuisine(List<String> types) {
    for (final key in _primaryCuisinePriority) {
      if (types.contains(key)) {
        return _typeLabels[key] ?? _beautifyLabel(key);
      }
    }

    for (final type in types) {
      if (_genericTypes.contains(type)) {
        continue;
      }
      final label = _typeLabels[type];
      if (label != null) {
        return label;
      }
    }

    return 'Culinária variada';
  }

  List<String> _collectSpecialtyLabels(_GooglePlace place, String primaryCuisine) {
    final labels = <String>[];
    final seen = <String>{};

    void addLabel(String? value) {
      if (value == null) {
        return;
      }
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return;
      }
      if (seen.add(trimmed)) {
        labels.add(trimmed);
      }
    }

    addLabel(primaryCuisine);

    for (final type in place.types) {
      if (_genericTypes.contains(type)) {
        continue;
      }
      addLabel(_typeLabels[type]);
    }

    final normalizedName = _normalize(place.name);
    if (normalizedName.contains('rodizio')) {
      addLabel('Rodízio variado');
    }
    if (normalizedName.contains('parrilla')) {
      addLabel('Parrilla argentina');
    }
    if (normalizedName.contains('churrasco')) {
      addLabel('Churrasco');
    }
    if (normalizedName.contains('hamburg')) {
      addLabel('Hambúrgueres artesanais');
    }
    if (normalizedName.contains('poke')) {
      addLabel('Pokes e bowls');
    }
    if (normalizedName.contains('massas')) {
      addLabel('Massas artesanais');
    }

    return labels.take(4).toList(growable: false);
  }

  List<String> _collectDietHighlights(_GooglePlace place) {
    final highlights = <String>{};

    for (final type in place.types) {
      final label = _dietTypeLabels[type];
      if (label != null) {
        highlights.add(label);
      }
    }

    final normalizedName = _normalize(place.name);
    if (normalizedName.contains('vegano')) {
      highlights.add('Opções veganas');
    }
    if (normalizedName.contains('vegetar')) {
      highlights.add('Opções vegetarianas');
    }
    if (normalizedName.contains('fit') || normalizedName.contains('saudavel')) {
      highlights.add('Refeições leves e saudáveis');
    }
    if (normalizedName.contains('gluten')) {
      highlights.add('Alternativas sem glúten');
    }

    return highlights.take(3).toList(growable: false);
  }

  List<String> _collectServiceLabels(_GooglePlace place) {
    final services = <String>{};

    if (place.openNow == true) {
      services.add('Aberto agora');
    }

    if (place.businessStatus == 'CLOSED_TEMPORARILY') {
      services.add('Temporariamente fechado');
    }

    if (place.types.contains('meal_delivery')) {
      services.add('Entrega');
    }
    if (place.types.contains('meal_takeaway')) {
      services.add('Retirada no local');
    }
    if (place.types.contains('drive_thru')) {
      services.add('Drive-thru');
    }
    if (place.types.contains('curbside_pickup')) {
      services.add('Retirada na calçada');
    }

    services.add('Consumo no local');

    return services.take(4).toList(growable: false);
  }

  String _describePriceRange(int? priceLevel) {
    if (priceLevel == null) {
      return 'Faixa de preço não informada';
    }
    return _priceLevelLabels[priceLevel] ?? 'Faixa de preço não informada';
  }

  String? _composeLabelFromComponents(List<dynamic>? components) {
    if (components == null) {
      return null;
    }

    String? city;
    String? state;

    for (final item in components) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final types = (item['types'] as List<dynamic>? ?? const []).cast<String>();
      final longName = item['long_name'] as String?;
      final shortName = item['short_name'] as String?;

      if (city == null &&
          (types.contains('locality') ||
              types.contains('administrative_area_level_3') ||
              types.contains('administrative_area_level_2'))) {
        city = longName;
      }

      if (state == null && types.contains('administrative_area_level_1')) {
        state = shortName ?? longName;
      }
    }

    if (city != null && state != null) {
      return '$city, $state';
    }
    return city ?? state;
  }

  int? _radiusFromViewport(Map<String, dynamic>? viewport, double lat, double lon) {
    if (viewport == null) {
      return null;
    }

    final northeast = viewport['northeast'] as Map<String, dynamic>?;
    final southwest = viewport['southwest'] as Map<String, dynamic>?;
    if (northeast == null || southwest == null) {
      return null;
    }

    final northLat = (northeast['lat'] as num?)?.toDouble();
    final southLat = (southwest['lat'] as num?)?.toDouble();
    final eastLon = (northeast['lng'] as num?)?.toDouble();
    final westLon = (southwest['lng'] as num?)?.toDouble();

    if (northLat == null || southLat == null || eastLon == null || westLon == null) {
      return null;
    }

    final latSpan = (northLat - southLat).abs();
    final lonSpan = (eastLon - westLon).abs();
    final latRadius = latSpan * 111000 / 2;
    final lonRadius = lonSpan * 111000 * math.cos(lat * math.pi / 180) / 2;
    final radius = math.max(latRadius, lonRadius);
    if (radius.isNaN || radius <= 0) {
      return null;
    }

    return radius.clamp(2000, 15000).toInt();
  }

  static String? _extractCityFromAddress(String? formatted, String? plusCode) {
    final candidates = <String?>[
      formatted,
      if (plusCode != null)
        plusCode.contains(' ')
            ? plusCode.substring(plusCode.indexOf(' ') + 1)
            : plusCode,
    ];

    for (final candidate in candidates) {
      if (candidate == null) {
        continue;
      }
      final parts = candidate
          .split(',')
          .map((segment) => segment.trim())
          .where((segment) => segment.isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        final city = parts[parts.length - 2];
        final state = parts.last;
        return '$city, $state';
      }
    }

    return null;
  }

  String _beautifyLabel(String raw) {
    final normalized = raw.replaceAll('_', ' ');
    return _titleCase(normalized);
  }

  String _titleCase(String input) {
    final normalized = _normalize(input);
    if (normalized.isEmpty) {
      return input.trim();
    }
    final words = normalized.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) {
      return input.trim();
    }
    return words.map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _normalize(String? input) {
    if (input == null) {
      return '';
    }
    final lower = input.toLowerCase();
    final buffer = StringBuffer();
    for (final code in lower.runes) {
      final char = String.fromCharCode(code);
      buffer.write(_normalizationMap[char] ?? char);
    }
    final normalized = buffer.toString();
    return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  Set<String> _normalizeKeywords(String? input) {
    final normalized = _normalize(input);
    if (normalized.isEmpty) {
      return const <String>{};
    }
    final tokens = normalized.split(' ').where((token) => token.isNotEmpty).toSet();
    if (tokens.length > 1) {
      tokens.add(normalized.replaceAll(' ', ''));
    } else {
      tokens.add(normalized);
    }
    return tokens;
  }

  static const Map<String, String> _normalizationMap = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };

  static const List<String> _primaryCuisinePriority = [
    'steak_house',
    'barbecue_restaurant',
    'pizza_restaurant',
    'italian_restaurant',
    'seafood_restaurant',
    'japanese_restaurant',
    'sushi_restaurant',
    'thai_restaurant',
    'indian_restaurant',
    'brazilian_restaurant',
    'vegan_restaurant',
    'vegetarian_restaurant',
    'healthy_food_restaurant',
    'hamburger_restaurant',
    'peruvian_restaurant',
    'mexican_restaurant',
    'spanish_restaurant',
    'french_restaurant',
    'mediterranean_restaurant',
  ];

  static const Map<String, String> _typeLabels = {
    'restaurant': 'Restaurante',
    'food': 'Alimentação variada',
    'point_of_interest': 'Ponto gastronômico',
    'establishment': 'Estabelecimento',
    'steak_house': 'Churrascaria e grelhados',
    'barbecue_restaurant': 'BBQ e defumados',
    'pizza_restaurant': 'Pizzaria',
    'italian_restaurant': 'Cozinha italiana',
    'seafood_restaurant': 'Frutos do mar',
    'japanese_restaurant': 'Culinária japonesa',
    'sushi_restaurant': 'Sushi e sashimi',
    'thai_restaurant': 'Culinária tailandesa',
    'indian_restaurant': 'Culinária indiana',
    'brazilian_restaurant': 'Culinária brasileira',
    'hamburger_restaurant': 'Hambúrgueres artesanais',
    'vegan_restaurant': 'Cozinha vegana',
    'vegetarian_restaurant': 'Culinária vegetariana',
    'healthy_food_restaurant': 'Comida leve e saudável',
    'peruvian_restaurant': 'Culinária peruana',
    'mexican_restaurant': 'Culinária mexicana',
    'french_restaurant': 'Culinária francesa',
    'spanish_restaurant': 'Culinária espanhola',
    'mediterranean_restaurant': 'Culinária mediterrânea',
    'greek_restaurant': 'Culinária grega',
    'korean_restaurant': 'Culinária coreana',
    'chinese_restaurant': 'Culinária chinesa',
    'fast_food_restaurant': 'Fast-food',
    'coffee_shop': 'Cafeteria',
    'bakery': 'Padaria e confeitaria',
    'ice_cream_shop': 'Sorveteria',
    'gastropub': 'Gastropub',
    'pub': 'Pub e drinks',
    'bar': 'Bar e petiscos',
  };

  static const Map<String, String> _dietTypeLabels = {
    'vegan_restaurant': 'Opções veganas',
    'vegetarian_restaurant': 'Opções vegetarianas',
    'healthy_food_restaurant': 'Comida leve e saudável',
    'gluten_free_restaurant': 'Opções sem glúten',
    'halal_restaurant': 'Opções halal',
    'kosher_restaurant': 'Opções kosher',
  };

  static const Map<int, String> _priceLevelLabels = {
    0: 'Muito acessível',
    1: 'Econômico',
    2: 'Moderado',
    3: 'Mais sofisticado',
    4: 'Alta gastronomia',
  };

  static const Set<String> _genericTypes = {
    'restaurant',
    'food',
    'point_of_interest',
    'establishment',
  };

  static const Map<String, Set<String>> _typeKeywordBoost = {
    'steak_house': {'carne', 'carnes', 'churrasco', 'parrilla'},
    'barbecue_restaurant': {'bbq', 'defumados', 'churrasco'},
    'pizza_restaurant': {'pizza', 'pizzaria', 'massas'},
    'italian_restaurant': {'italiano', 'massas', 'risoto'},
    'seafood_restaurant': {'peixe', 'frutos', 'mar'},
    'japanese_restaurant': {'sushi', 'japonesa'},
    'sushi_restaurant': {'sushi', 'temaki'},
    'thai_restaurant': {'thai', 'asiatica'},
    'indian_restaurant': {'indiana', 'especiarias'},
    'brazilian_restaurant': {'brasileira', 'caseira', 'pf'},
    'hamburger_restaurant': {'hamburguer', 'burger'},
    'vegan_restaurant': {'vegano', 'plantbased'},
    'vegetarian_restaurant': {'vegetariano', 'sem carne'},
    'healthy_food_restaurant': {'saudavel', 'leve', 'fit'},
    'peruvian_restaurant': {'peruana', 'ceviche'},
    'mexican_restaurant': {'mexicana', 'tacos'},
    'french_restaurant': {'francesa', 'bistrô'},
    'spanish_restaurant': {'espanhola', 'tapas'},
    'mediterranean_restaurant': {'mediterranea'},
    'greek_restaurant': {'grega'},
    'korean_restaurant': {'coreana'},
    'chinese_restaurant': {'chinesa'},
  };
}

class _PlacesResponse {
  const _PlacesResponse({
    required this.results,
    this.nextPageToken,
  });

  final List<_GooglePlace> results;
  final String? nextPageToken;
}

class _GeocodeResult {
  const _GeocodeResult({
    required this.coordinates,
    required this.label,
    this.suggestedRadiusMeters,
  });

  final LocationCoordinates coordinates;
  final String label;
  final int? suggestedRadiusMeters;
}

class _GooglePlace {
  const _GooglePlace({
    required this.placeId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.types,
    this.vicinity,
    this.formattedAddress,
    this.rating,
    this.userRatingsTotal,
    this.priceLevel,
    this.openNow,
    this.businessStatus,
    this.plusCode,
  });

  final String placeId;
  final String name;
  final double latitude;
  final double longitude;
  final List<String> types;
  final String? vicinity;
  final String? formattedAddress;
  final double? rating;
  final int? userRatingsTotal;
  final int? priceLevel;
  final bool? openNow;
  final String? businessStatus;
  final String? plusCode;

  String? get city =>
      RestaurantDiscoveryServiceImpl._extractCityFromAddress(formattedAddress, plusCode);

  Set<String> get keywordBoost {
    final tokens = <String>{};
    for (final type in types) {
      final boost = RestaurantDiscoveryServiceImpl._typeKeywordBoost[type];
      if (boost != null) {
        tokens.addAll(boost);
      }
    }
    return tokens;
  }

  static _GooglePlace? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final placeId = json['place_id'] as String?;
    final name = json['name'] as String?;
    if (placeId == null || name == null || name.trim().isEmpty) {
      return null;
    }

    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final lat = (location?['lat'] as num?)?.toDouble();
    final lng = (location?['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) {
      return null;
    }

    final types = (json['types'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    final openingHours = json['opening_hours'] as Map<String, dynamic>?;
    final plusCode = json['plus_code'] as Map<String, dynamic>?;

    return _GooglePlace(
      placeId: placeId,
      name: name,
      latitude: lat,
      longitude: lng,
      types: types,
      vicinity: json['vicinity'] as String?,
      formattedAddress: json['formatted_address'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: (json['user_ratings_total'] as num?)?.toInt(),
      priceLevel: (json['price_level'] as num?)?.toInt(),
      openNow: openingHours != null ? openingHours['open_now'] as bool? : null,
      businessStatus: json['business_status'] as String?,
      plusCode: plusCode != null ? plusCode['compound_code'] as String? : null,
    );
  }
}

class _SuggestionCandidate {
  const _SuggestionCandidate({
    required this.place,
    required this.suggestion,
    required this.featureTags,
  });

  final _GooglePlace place;
  final RestaurantSuggestion suggestion;
  final Set<String> featureTags;

  String get key => place.placeId;

  int compareTo(_SuggestionCandidate other) {
    final aDistance = suggestion.distanceKm;
    final bDistance = other.suggestion.distanceKm;
    if (aDistance != null && bDistance != null) {
      final diff = aDistance.compareTo(bDistance);
      if (diff != 0) {
        return diff;
      }
    } else if (aDistance != null) {
      return -1;
    } else if (bDistance != null) {
      return 1;
    }

    final ratingDiff = other.suggestion.rating.compareTo(suggestion.rating);
    if (ratingDiff != 0) {
      return ratingDiff;
    }

    final reviewCountDiff =
        (other.place.userRatingsTotal ?? 0).compareTo(place.userRatingsTotal ?? 0);
    if (reviewCountDiff != 0) {
      return reviewCountDiff;
    }

    return suggestion.name.compareTo(other.suggestion.name);
  }
}
