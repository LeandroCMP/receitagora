import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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
  })  : _httpClient = httpClient ?? http.Client(),
        _httpTimeout = httpTimeout;

  final http.Client _httpClient;
  final Duration _httpTimeout;
  final int searchRadiusMeters;

  static const String _overpassEndpoint = 'https://overpass-api.de/api/interpreter';
  static const String _nominatimSearchEndpoint = 'https://nominatim.openstreetmap.org/search';
  static const String _nominatimReverseEndpoint = 'https://nominatim.openstreetmap.org/reverse';

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

    if (profile.prefersBrazilianCuisine) {
      ids.add('comfort_br');
    }

    if (profile.prefersSeasonalProduce) {
      ids.add('vegetarian');
    }

    if (profile.goal == DietGoal.gainMass && profile.exercisesRegularly) {
      ids.add('high_protein');
    }

    return _focusCatalog.where((focus) => ids.contains(focus.id)).toList(growable: false);
  }

  @override
  Future<RestaurantSearchResult> searchNearby({
    required double latitude,
    required double longitude,
    RestaurantFocus? focus,
    int limit = 12,
  }) async {
    final reference = LocationCoordinates(latitude: latitude, longitude: longitude);
    final rawResults = await _fetchRestaurantsByCoordinates(
      latitude: latitude,
      longitude: longitude,
      limitHint: limit,
    );

    final resolvedLabel =
        await _reverseGeocodeLabel(latitude: latitude, longitude: longitude) ?? 'Sua região';

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
    int limit = 12,
  }) async {
    final geocode = await _geocodeCity(city);
    if (geocode == null) {
      throw Exception('Cidade não encontrada');
    }

    final rawResults = await _fetchRestaurantsByCoordinates(
      latitude: geocode.coordinates.latitude,
      longitude: geocode.coordinates.longitude,
      limitHint: limit,
      radiusOverride: geocode.suggestedRadiusMeters,
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

  Future<List<_RawRestaurant>> _fetchRestaurantsByCoordinates({
    required double latitude,
    required double longitude,
    required int limitHint,
    int? radiusOverride,
  }) async {
    final radius = radiusOverride != null && radiusOverride > 0
        ? radiusOverride
        : searchRadiusMeters;
    final sampleSize = math.max(limitHint * 4, 40);

    final query = '''
[out:json][timeout:25];
(
  node["amenity"="restaurant"](around:$radius,$latitude,$longitude);
  way["amenity"="restaurant"](around:$radius,$latitude,$longitude);
  relation["amenity"="restaurant"](around:$radius,$latitude,$longitude);
);
out center tags $sampleSize;
''';

    final response = await _httpClient
        .post(
          Uri.parse(_overpassEndpoint),
          headers: _defaultHeaders,
          body: {'data': query},
        )
        .timeout(_httpTimeout);

    if (response.statusCode != 200) {
      throw Exception('Falha ao consultar restaurantes (status ${response.statusCode}).');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = payload['elements'] as List<dynamic>? ?? const [];

    return elements
        .map((element) => _RawRestaurant.fromJson(element as Map<String, dynamic>?))
        .whereType<_RawRestaurant>()
        .toList(growable: false);
  }

  Future<String?> _reverseGeocodeLabel({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_nominatimReverseEndpoint).replace(queryParameters: {
      'format': 'jsonv2',
      'lat': '$latitude',
      'lon': '$longitude',
      'addressdetails': '1',
      'accept-language': 'pt-BR',
    });

    final response = await _httpClient
        .get(uri, headers: _defaultHeaders)
        .timeout(_httpTimeout);

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final address = data['address'] as Map<String, dynamic>?;
    return _composeGeocodeLabel(address, data['display_name'] as String?);
  }

  Future<_GeocodeResult?> _geocodeCity(String city) async {
    final uri = Uri.parse(_nominatimSearchEndpoint).replace(queryParameters: {
      'q': city,
      'format': 'jsonv2',
      'limit': '1',
      'addressdetails': '1',
      'accept-language': 'pt-BR',
    });

    final response = await _httpClient
        .get(uri, headers: _defaultHeaders)
        .timeout(_httpTimeout);

    if (response.statusCode != 200) {
      throw Exception('Falha ao consultar localização da cidade.');
    }

    final results = jsonDecode(response.body);
    if (results is! List || results.isEmpty) {
      return null;
    }

    final data = results.first as Map<String, dynamic>;
    final lat = double.tryParse(data['lat'] as String? ?? '');
    final lon = double.tryParse(data['lon'] as String? ?? '');
    if (lat == null || lon == null) {
      return null;
    }

    final address = data['address'] as Map<String, dynamic>?;
    final label = _composeGeocodeLabel(address, data['display_name'] as String?) ??
        _titleCase(city.trim());

    final radius = _radiusFromBoundingBox(
      data['boundingbox'] as List<dynamic>?,
      lat,
      lon,
    );

    return _GeocodeResult(
      coordinates: LocationCoordinates(latitude: lat, longitude: lon),
      label: label,
      suggestedRadiusMeters: radius,
    );
  }

  String? _composeGeocodeLabel(Map<String, dynamic>? address, String? displayName) {
    final city = address?['city'] ??
        address?['town'] ??
        address?['municipality'] ??
        address?['village'] ??
        address?['suburb'];
    final state = address?['state'] ?? address?['region'];
    if (city is String && state is String) {
      return '$city, $state';
    }
    if (city is String) {
      return city;
    }
    if (state is String) {
      return state;
    }
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        return '${parts[0]}, ${parts[1]}';
      }
      if (parts.isNotEmpty) {
        return parts.first;
      }
    }
    return null;
  }

  int? _radiusFromBoundingBox(List<dynamic>? boundingBox, double lat, double lon) {
    if (boundingBox == null || boundingBox.length != 4) {
      return null;
    }

    final south = double.tryParse(boundingBox[0].toString());
    final north = double.tryParse(boundingBox[1].toString());
    final west = double.tryParse(boundingBox[2].toString());
    final east = double.tryParse(boundingBox[3].toString());

    if (south == null || north == null || west == null || east == null) {
      return null;
    }

    final latSpan = (north - south).abs();
    final lonSpan = (east - west).abs();

    final latRadius = latSpan * 111000 / 2;
    final lonRadius = lonSpan * 111000 * math.cos(lat * math.pi / 180) / 2;
    final averageRadius = math.max(latRadius, lonRadius);

    if (averageRadius.isNaN || averageRadius <= 0) {
      return null;
    }

    final clamped = averageRadius.clamp(2000, 12000).toInt();
    return clamped;
  }

  List<RestaurantSuggestion> _buildSuggestions(
    List<_RawRestaurant> entries, {
    required RestaurantFocus? focus,
    required int limit,
    required LocationCoordinates? reference,
    required String fallbackCityLabel,
  }) {
    if (limit <= 0) {
      return const [];
    }

    final focusMatches = <_SuggestionCandidate>[];
    final generalMatches = <_SuggestionCandidate>[];

    for (final entry in entries) {
      final candidate = _buildCandidate(
        entry,
        reference: reference,
        fallbackCityLabel: fallbackCityLabel,
      );
      if (candidate == null) {
        continue;
      }

      if (_matchesFocus(focus, candidate)) {
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
    _RawRestaurant restaurant, {
    required LocationCoordinates? reference,
    required String fallbackCityLabel,
  }) {
    final tags = restaurant.tags;
    final name = _stringTag(tags, 'name');
    if (name == null || name.isEmpty) {
      return null;
    }

    final cuisines = _extractCuisines(tags);
    final cuisineKeywords = <String>{};
    for (final cuisine in cuisines) {
      cuisineKeywords.addAll(cuisine.normalizedKeywords);
    }

    final cityLabel = _resolveCityLabel(tags) ?? fallbackCityLabel;
    final address = _composeAddress(tags);
    final priceRange = _resolvePriceRange(tags);
    final rating = _parseRating(tags);
    final dietHighlights = _buildDietHighlights(tags);
    final services = _buildServices(tags);
    final specialties = _buildSpecialties(tags, cuisines);

    double? distanceKm;
    if (reference != null) {
      distanceKm = _distanceKm(
        reference.latitude,
        reference.longitude,
        restaurant.latitude,
        restaurant.longitude,
      );
    }

    final suggestion = RestaurantSuggestion(
      id: restaurant.id,
      name: name,
      city: cityLabel,
      address: address,
      primaryCuisine: cuisines.isNotEmpty
          ? cuisines.first.displayName
          : 'Culinária variada',
      priceRange: priceRange,
      rating: rating,
      specialties: specialties,
      dietHighlights: dietHighlights,
      services: services,
      distanceKm: distanceKm,
    );

    final featureTags = <String>{
      ...cuisineKeywords,
      ..._normalizeKeywords(_stringTag(tags, 'amenity')),
      ..._normalizeKeywords(_stringTag(tags, 'cuisine:primary')),
      ..._normalizeKeywords(name),
    };

    if (_boolTag(tags, 'diet:vegan')) {
      featureTags.addAll(_normalizeKeywords('vegano'));
    }
    if (_boolTag(tags, 'diet:vegetarian')) {
      featureTags.addAll(_normalizeKeywords('vegetariano'));
    }
    if (_boolTag(tags, 'diet:gluten_free')) {
      featureTags.addAll(_normalizeKeywords('sem gluten'));
    }
    if (_boolTag(tags, 'diet:lactose_free')) {
      featureTags.addAll(_normalizeKeywords('sem lactose'));
    }

    final normalizedAddress = _normalize([
      _stringTag(tags, 'addr:street'),
      _stringTag(tags, 'addr:housenumber'),
      _stringTag(tags, 'addr:suburb'),
      _stringTag(tags, 'addr:district'),
    ].whereType<String>().join(' '));

    return _SuggestionCandidate(
      raw: restaurant,
      suggestion: suggestion,
      normalizedName: _normalize(name),
      normalizedAddress: normalizedAddress,
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
      },
    );

    return candidate.featureTags.any(focusKeywords.contains);
  }

  List<_CuisineInfo> _extractCuisines(Map<String, dynamic> tags) {
    final rawValues = <String>[];
    final cuisine = tags['cuisine'];
    if (cuisine is String) {
      rawValues.addAll(cuisine.split(RegExp(r'[;,]')));
    } else if (cuisine is Iterable) {
      rawValues.addAll(cuisine.map((value) => value.toString()));
    }

    tags.forEach((key, value) {
      if (key.startsWith('cuisine:') && value is String) {
        rawValues.add(value);
      }
    });

    final results = <_CuisineInfo>[];
    final seen = <String>{};
    for (final raw in rawValues) {
      final normalized = _normalize(raw);
      if (normalized.isEmpty) {
        continue;
      }
      final condensed = normalized.replaceAll(' ', '');
      if (!seen.add(condensed)) {
        continue;
      }
      final keywords = _normalizeKeywords(raw);
      if (keywords.isEmpty) {
        continue;
      }
      final display =
          _cuisineLabels[normalized] ?? _cuisineLabels[condensed] ?? _beautifyLabel(raw);
      results.add(_CuisineInfo(normalizedKeywords: keywords, displayName: display));
    }

    return results;
  }

  String? _resolveCityLabel(Map<String, dynamic> tags) {
    final city = _stringTag(tags, 'addr:city') ??
        _stringTag(tags, 'addr:town') ??
        _stringTag(tags, 'addr:municipality') ??
        _stringTag(tags, 'addr:village') ??
        _stringTag(tags, 'addr:suburb');
    final state = _stringTag(tags, 'addr:state') ?? _stringTag(tags, 'addr:region');

    if (city != null && state != null) {
      return '$city, $state';
    }
    return city ?? state;
  }

  String _composeAddress(Map<String, dynamic> tags) {
    final street = _stringTag(tags, 'addr:street');
    final number = _stringTag(tags, 'addr:housenumber');
    final suburb = _stringTag(tags, 'addr:suburb') ?? _stringTag(tags, 'addr:neighbourhood');
    final district = _stringTag(tags, 'addr:district') ?? _stringTag(tags, 'addr:quarter');

    final segments = <String>[];
    if (street != null && street.isNotEmpty) {
      segments.add(number != null && number.isNotEmpty ? '$street, $number' : street);
    }
    if (suburb != null && suburb.isNotEmpty) {
      segments.add(suburb);
    }
    if (district != null && district.isNotEmpty && district != suburb) {
      segments.add(district);
    }

    if (segments.isNotEmpty) {
      return segments.join(' • ');
    }

    final fullAddress = _stringTag(tags, 'addr:full');
    if (fullAddress != null && fullAddress.isNotEmpty) {
      return fullAddress;
    }

    return 'Endereço não informado';
  }

  String _resolvePriceRange(Map<String, dynamic> tags) {
    final price = _stringTag(tags, 'price:range') ??
        _stringTag(tags, 'price') ??
        _stringTag(tags, 'charge');
    if (price != null && price.isNotEmpty) {
      return price;
    }
    final fee = _stringTag(tags, 'fee');
    if (fee != null && fee.isNotEmpty) {
      return fee;
    }
    return 'Faixa de preço não informada';
  }

  double _parseRating(Map<String, dynamic> tags) {
    final ratingValue = _stringTag(tags, 'rating') ??
        _stringTag(tags, 'rating:google') ??
        _stringTag(tags, 'rating:food');
    final starsValue = _stringTag(tags, 'stars');

    double? rating = ratingValue != null ? double.tryParse(ratingValue.replaceAll(',', '.')) : null;
    rating ??= starsValue != null ? double.tryParse(starsValue.replaceAll(',', '.')) : null;

    if (rating == null) {
      final michelin = _stringTag(tags, 'michelin');
      if (michelin != null) {
        rating = 5;
      }
    }

    if (rating == null) {
      return 0;
    }

    if (rating.isNaN) {
      return 0;
    }

    if (rating > 5) {
      rating = 5;
    }
    if (rating < 0) {
      rating = 0;
    }

    return double.parse(rating.toStringAsFixed(1));
  }

  List<String> _buildDietHighlights(Map<String, dynamic> tags) {
    final highlights = <String>[];
    if (_boolTag(tags, 'diet:vegan')) {
      highlights.add('Opções veganas disponíveis');
    }
    if (_boolTag(tags, 'diet:vegetarian')) {
      highlights.add('Pratos vegetarianos destacados');
    }
    if (_boolTag(tags, 'diet:gluten_free')) {
      highlights.add('Preparos sem glúten sob demanda');
    }
    if (_boolTag(tags, 'diet:lactose_free')) {
      highlights.add('Versões sem lactose disponíveis');
    }
    if (_boolTag(tags, 'organic')) {
      highlights.add('Ingredientes orgânicos e frescos');
    }
    if (_boolTag(tags, 'kosher')) {
      highlights.add('Certificação kosher disponível');
    }
    if (_boolTag(tags, 'halal')) {
      highlights.add('Preparos compatíveis com dieta halal');
    }
    return highlights;
  }

  List<String> _buildServices(Map<String, dynamic> tags) {
    final services = <String>[];
    if (_boolTag(tags, 'delivery') || _boolTag(tags, 'delivery:covid19')) {
      services.add('Entrega disponível');
    }
    if (_boolTag(tags, 'takeaway')) {
      services.add('Retirada para viagem');
    }
    if (_boolTag(tags, 'drive_through')) {
      services.add('Drive-thru');
    }
    if (_boolTag(tags, 'wheelchair')) {
      services.add('Acesso para cadeirantes');
    }
    if (_boolTag(tags, 'outdoor_seating')) {
      services.add('Mesas ao ar livre');
    }
    if (_boolTag(tags, 'internet_access')) {
      services.add('Wi-Fi disponível');
    }
    if (_boolTag(tags, 'reservation')) {
      services.add('Aceita reservas');
    }

    final phone = _stringTag(tags, 'phone') ?? _stringTag(tags, 'contact:phone');
    if (phone != null && phone.isNotEmpty) {
      services.add('Contato: $phone');
    }
    final website = _stringTag(tags, 'website') ?? _stringTag(tags, 'contact:website');
    if (website != null && website.isNotEmpty) {
      services.add('Site: $website');
    }

    return services.take(6).toList(growable: false);
  }

  List<String> _buildSpecialties(Map<String, dynamic> tags, List<_CuisineInfo> cuisines) {
    final specialties = <String>[];
    final cuisineLabels = cuisines.map((cuisine) => cuisine.displayName).where((label) => label.isNotEmpty).toList();
    if (cuisineLabels.isNotEmpty) {
      specialties.add('Culinária destaque: ${_joinWithAnd(cuisineLabels.take(3).toList())}');
    }

    final speciality = _stringTag(tags, 'speciality') ?? _stringTag(tags, 'specialty');
    if (speciality != null && speciality.isNotEmpty) {
      specialties.add(_beautifySentence('Especialidade da casa: $speciality'));
    }

    final description = _stringTag(tags, 'description') ?? _stringTag(tags, 'note');
    if (description != null && description.isNotEmpty) {
      specialties.add(_beautifySentence(description));
    }

    final openingHours = _stringTag(tags, 'opening_hours');
    if (openingHours != null && openingHours.isNotEmpty) {
      specialties.add('Horário: $openingHours');
    }

    return specialties.take(4).toList(growable: false);
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) * math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = earthRadius * c;
    return double.parse(distance.toStringAsFixed(2));
  }

  double _degToRad(double degree) => degree * (math.pi / 180);

  bool _boolTag(Map<String, dynamic> tags, String key) {
    final value = tags[key];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'yes' ||
          normalized == 'true' ||
          normalized == 'sim' ||
          normalized == '1';
    }
    return false;
  }

  String? _stringTag(Map<String, dynamic> tags, String key) {
    final value = tags[key];
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value.trim();
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    return null;
  }

  String _beautifyLabel(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[_-]'), ' ').trim();
    if (cleaned.isEmpty) {
      return 'Culinária variada';
    }
    final words = cleaned.split(RegExp(r'\s+')).map((word) {
      final lower = word.toLowerCase();
      if (lower.isEmpty) {
        return '';
      }
      if (lower.length == 1) {
        return lower.toUpperCase();
      }
      return lower[0].toUpperCase() + lower.substring(1);
    }).where((word) => word.isNotEmpty);
    return words.join(' ');
  }

  String _beautifySentence(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    final normalized = trimmed[0].toUpperCase() + trimmed.substring(1);
    return normalized;
  }

  String _joinWithAnd(List<String> values) {
    if (values.isEmpty) {
      return '';
    }
    if (values.length == 1) {
      return values.first;
    }
    if (values.length == 2) {
      return '${values[0]} e ${values[1]}';
    }
    final first = values.sublist(0, values.length - 1).join(', ');
    return '$first e ${values.last}';
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

  static const Map<String, String> _cuisineLabels = {
    'brazilian': 'Culinária brasileira',
    'regional': 'Sabores regionais',
    'northeastern': 'Comida nordestina',
    'italian': 'Culinária italiana',
    'pizza': 'Pizzas artesanais',
    'pasta': 'Massas frescas',
    'risotto': 'Risotos especiais',
    'steak': 'Carnes grelhadas',
    'steakhouse': 'Carnes e parrilla',
    'bbq': 'Churrasco e BBQ',
    'barbecue': 'Churrasco e parrilla',
    'grill': 'Grelhados',
    'japanese': 'Culinária japonesa',
    'sushi': 'Sushi e sashimi',
    'seafood': 'Frutos do mar',
    'fish': 'Peixes frescos',
    'vegetarian': 'Culinária vegetariana',
    'vegan': 'Cozinha vegana',
    'plantbased': 'Plant-based criativo',
    'healthy': 'Comida saudável',
    'salad': 'Saladas e bowls',
    'poke': 'Pokes e bowls havaianos',
    'burger': 'Hambúrgueres artesanais',
    'sandwich': 'Sanduíches especiais',
    'mexican': 'Culinária mexicana',
    'arab': 'Sabores árabes',
    'arabic': 'Sabores árabes',
    'chinese': 'Culinária chinesa',
    'thai': 'Culinária tailandesa',
    'indian': 'Culinária indiana',
    'french': 'Culinária francesa',
    'spanish': 'Culinária espanhola',
    'mediterranean': 'Culinária mediterrânea',
    'peruvian': 'Culinária peruana',
    'korean': 'Culinária coreana',
    'german': 'Culinária alemã',
    'greek': 'Culinária grega',
    'tapas': 'Tapas e petiscos',
    'rodizio': 'Rodízio variado',
    'parrilla': 'Parrilla argentina',
    'churrasco': 'Churrasco brasileiro',
  };
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

class _CuisineInfo {
  const _CuisineInfo({
    required this.normalizedKeywords,
    required this.displayName,
  });

  final Set<String> normalizedKeywords;
  final String displayName;
}

class _RawRestaurant {
  const _RawRestaurant({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.tags,
  });

  final String id;
  final double latitude;
  final double longitude;
  final Map<String, dynamic> tags;

  static _RawRestaurant? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    double? latitude = (json['lat'] as num?)?.toDouble();
    double? longitude = (json['lon'] as num?)?.toDouble();

    if (latitude == null || longitude == null) {
      final center = json['center'] as Map<String, dynamic>?;
      latitude = (center?['lat'] as num?)?.toDouble();
      longitude = (center?['lon'] as num?)?.toDouble();
    }

    if (latitude == null || longitude == null) {
      return null;
    }

    final id = json['id']?.toString();
    if (id == null) {
      return null;
    }

    final rawTags = json['tags'];
    final tags = <String, dynamic>{};
    if (rawTags is Map) {
      rawTags.forEach((key, value) {
        if (key == null) {
          return;
        }
        tags[key.toString()] = value;
      });
    }

    return _RawRestaurant(
      id: id,
      latitude: latitude,
      longitude: longitude,
      tags: tags,
    );
  }
}

class _SuggestionCandidate {
  const _SuggestionCandidate({
    required this.raw,
    required this.suggestion,
    required this.normalizedName,
    required this.normalizedAddress,
    required this.featureTags,
  });

  final _RawRestaurant raw;
  final RestaurantSuggestion suggestion;
  final String normalizedName;
  final String normalizedAddress;
  final Set<String> featureTags;

  String get key {
    final latKey = raw.latitude.toStringAsFixed(3);
    final lonKey = raw.longitude.toStringAsFixed(3);
    return '$normalizedName|$normalizedAddress|$latKey|$lonKey';
  }

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

    return suggestion.name.compareTo(other.suggestion.name);
  }
}
