import 'dart:convert';

import 'package:meta/meta.dart';

@immutable
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  UserModel copyWith({
    String? name,
    String? email,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory UserModel.fromJson(String source) {
    return UserModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }

  @override
  int get hashCode => Object.hash(id, name, email, avatarUrl);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.avatarUrl == avatarUrl;
  }

  @override
  String toString() => 'UserModel(id: $id, name: $name, email: $email)';
}
