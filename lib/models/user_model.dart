import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    String? avatarUrl,
    String? bio,
    List<String>? dietaryPreferences,
    List<String>? favoriteCuisines,
    List<String>? cookingGoals,
    List<String>? allergies,
  })  : avatarUrl = avatarUrl,
        bio = _normalizeOptionalString(bio),
        dietaryPreferences =
            _normalizeList(dietaryPreferences ?? const <String>[]),
        favoriteCuisines =
            _normalizeList(favoriteCuisines ?? const <String>[]),
        cookingGoals = _normalizeList(cookingGoals ?? const <String>[]),
        allergies = _normalizeList(allergies ?? const <String>[]);

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final List<String> dietaryPreferences;
  final List<String> favoriteCuisines;
  final List<String> cookingGoals;
  final List<String> allergies;

  bool get hasBio => bio != null && bio!.trim().isNotEmpty;

  bool get hasPreferences =>
      dietaryPreferences.isNotEmpty ||
      favoriteCuisines.isNotEmpty ||
      cookingGoals.isNotEmpty ||
      allergies.isNotEmpty;

  UserModel copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    String? bio,
    List<String>? dietaryPreferences,
    List<String>? favoriteCuisines,
    List<String>? cookingGoals,
    List<String>? allergies,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      favoriteCuisines: favoriteCuisines ?? this.favoriteCuisines,
      cookingGoals: cookingGoals ?? this.cookingGoals,
      allergies: allergies ?? this.allergies,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'dietaryPreferences': dietaryPreferences,
      'favoriteCuisines': favoriteCuisines,
      'cookingGoals': cookingGoals,
      'allergies': allergies,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      bio: _readString(map['bio']),
      dietaryPreferences: _readStringList(map['dietaryPreferences']),
      favoriteCuisines: _readStringList(map['favoriteCuisines']),
      cookingGoals: _readStringList(map['cookingGoals']),
      allergies: _readStringList(map['allergies']),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory UserModel.fromJson(String source) {
    return UserModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        name,
        email,
        avatarUrl,
        bio,
        Object.hashAll(dietaryPreferences),
        Object.hashAll(favoriteCuisines),
        Object.hashAll(cookingGoals),
        Object.hashAll(allergies),
      ]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.avatarUrl == avatarUrl &&
        other.bio == bio &&
        _listEquals(other.dietaryPreferences, dietaryPreferences) &&
        _listEquals(other.favoriteCuisines, favoriteCuisines) &&
        _listEquals(other.cookingGoals, cookingGoals) &&
        _listEquals(other.allergies, allergies);
  }

  @override
  String toString() =>
      'UserModel(id: $id, name: $name, email: $email, preferences: ${dietaryPreferences.length} dietas)';

  static String? _normalizeOptionalString(String? value) {
    if (value == null) {
      return null;
    }
    final sanitized = value.trim();
    if (sanitized.isEmpty) {
      return null;
    }
    return sanitized;
  }

  static List<String> _normalizeList(List<String> values) {
    if (values.isEmpty) {
      return const <String>[];
    }
    final normalized = values
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map(_capitalize)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return List<String>.unmodifiable(normalized);
  }

  static String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    final lower = value.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  static String? _readString(dynamic value) {
    if (value is String) {
      final sanitized = value.trim();
      if (sanitized.isNotEmpty) {
        return sanitized;
      }
    }
    return null;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is Iterable) {
      final list = value
          .map((dynamic item) => item?.toString())
          .whereType<String>()
          .toList();
      return _normalizeList(list);
    }
    return const <String>[];
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
