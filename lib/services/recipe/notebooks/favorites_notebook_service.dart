import 'dart:async';

import 'package:receitagora/modules/favorites/favorited_recipe_entity.dart';

class FavoritesNotebookComment {
  const FavoritesNotebookComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String message;
  final DateTime createdAt;
}

class FavoritesNotebookMember {
  const FavoritesNotebookMember({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class FavoritesNotebook {
  const FavoritesNotebook({
    required this.id,
    required this.title,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    required this.isCollaborative,
    required this.shareCode,
    required this.favoriteIds,
    required this.members,
    required this.comments,
    required this.isOwner,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String ownerId;
  final String ownerName;
  final bool isCollaborative;
  final String? shareCode;
  final List<String> favoriteIds;
  final List<FavoritesNotebookMember> members;
  final List<FavoritesNotebookComment> comments;
  final bool isOwner;
  final DateTime updatedAt;
}

abstract class FavoritesNotebookService {
  List<FavoritesNotebook> get notebooks;
  Stream<List<FavoritesNotebook>> get notebooksStream;

  Future<FavoritesNotebook> createNotebook({
    required String title,
    String? description,
    bool collaborative,
  });

  Future<void> updateNotebook({
    required String notebookId,
    String? title,
    String? description,
    bool? collaborative,
  });

  Future<void> deleteNotebook(String notebookId);

  Future<void> addFavorite({
    required String notebookId,
    required FavoritedRecipeEntity favorite,
  });

  Future<void> removeFavorite({
    required String notebookId,
    required String favoriteId,
  });

  Future<void> addComment({
    required String notebookId,
    required String message,
  });

  Future<String?> ensureShareCode(String notebookId);
  Future<void> joinByShareCode(String shareCode);
  Future<String> exportNotebook(
    String notebookId, {
    Map<String, FavoritedRecipeEntity>? favoritesById,
  });
}
