import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../modules/favorites/domain/entities/favorited_recipe_entity.dart';
import '../../modules/recipe_finder/domain/entities/recipe_entity.dart';
import 'session_service.dart';

class FavoritesFailure implements Exception {
  FavoritesFailure(this.message);

  final String message;
}

class RecipeFavoritesService extends GetxService {
  RecipeFavoritesService({
    required this.firestore,
    required this.sessionService,
  });

  final FirebaseFirestore firestore;
  final SessionService sessionService;

  final RxSet<String> _favoriteIds = <String>{}.obs;
  final RxList<FavoritedRecipeEntity> _favorites = <FavoritedRecipeEntity>[].obs;

  StreamSubscription<SessionUser?>? _userSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _favoritesSubscription;

  RxSet<String> get favoriteIds => _favoriteIds;
  RxList<FavoritedRecipeEntity> get favorites => _favorites;
  Stream<Set<String>> get favoriteIdsStream => _favoriteIds.stream;
  Stream<List<FavoritedRecipeEntity>> get favoritesStream => _favorites.stream;

  @override
  void onInit() {
    super.onInit();
    _userSubscription = sessionService.userStream.listen(_handleUserChanged);
    _handleUserChanged(sessionService.user);
  }

  @override
  void onClose() {
    _userSubscription?.cancel();
    _favoritesSubscription?.cancel();
    super.onClose();
  }

  bool isFavoriteSync(RecipeEntity recipe) {
    final id = _buildRecipeId(recipe);
    return _favoriteIds.value.contains(id);
  }

  Future<void> addFavorite(RecipeEntity recipe) async {
    await sessionService.ensureInitialized();
    final user = sessionService.user;
    if (user == null) {
      throw FavoritesFailure('Faça login para salvar receitas nos favoritos.');
    }

    final document = _userFavoritesCollection(user.id).doc(_buildRecipeId(recipe));

    try {
      await document.set({
        'name': recipe.name,
        'description': recipe.description,
        'ingredients': recipe.ingredients,
        'steps': recipe.steps,
        'difficulty': recipe.difficulty,
        'duration': recipe.duration,
        'favoritedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      final message = error.message?.trim();
      throw FavoritesFailure(
        message == null || message.isEmpty
            ? 'Não foi possível adicionar esta receita aos favoritos agora.'
            : message,
      );
    }
  }

  Future<void> removeFavoriteForRecipe(RecipeEntity recipe) async {
    await removeFavoriteById(_buildRecipeId(recipe));
  }

  Future<void> removeFavoriteById(String id) async {
    await sessionService.ensureInitialized();
    final user = sessionService.user;
    if (user == null) {
      throw FavoritesFailure('Faça login para gerenciar seus favoritos.');
    }

    final document = _userFavoritesCollection(user.id).doc(id);

    try {
      await document.delete();
    } on FirebaseException catch (error) {
      if (error.code == 'not-found') {
        return;
      }
      final message = error.message?.trim();
      throw FavoritesFailure(
        message == null || message.isEmpty
            ? 'Não foi possível remover esta receita dos favoritos.'
            : message,
      );
    }
  }

  Future<void> toggleFavorite(RecipeEntity recipe) async {
    if (isFavoriteSync(recipe)) {
      await removeFavoriteForRecipe(recipe);
    } else {
      await addFavorite(recipe);
    }
  }

  void _handleUserChanged(SessionUser? user) {
    _favoritesSubscription?.cancel();
    _favorites.clear();
    _favoriteIds.clear();

    if (user == null) {
      return;
    }

    final collection = _userFavoritesCollection(user.id)
        .orderBy('favoritedAt', descending: true);
    _favoritesSubscription = collection.snapshots().listen(
      (snapshot) {
        final mapped = snapshot.docs.map(_mapDocument).toList();
        _favorites.assignAll(mapped);
        _favoriteIds
          ..clear()
          ..addAll(mapped.map((item) => item.id));
      },
    );
  }

  FavoritedRecipeEntity _mapDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final recipe = RecipeEntity(
      name: _readString(data['name'], fallback: 'Receita sem nome'),
      description:
          _readString(data['description'], fallback: 'Descrição indisponível.'),
      ingredients: _readList(data['ingredients']),
      steps: _readList(data['steps']),
      difficulty:
          _readString(data['difficulty'], fallback: 'Dificuldade não informada'),
      duration: _readString(data['duration'], fallback: 'Tempo não informado'),
    );

    DateTime? favoritedAt;
    final timestamp = data['favoritedAt'];
    if (timestamp is Timestamp) {
      favoritedAt = timestamp.toDate();
    }

    return FavoritedRecipeEntity(
      id: doc.id,
      recipe: recipe,
      favoritedAt: favoritedAt,
    );
  }

  CollectionReference<Map<String, dynamic>> _userFavoritesCollection(
    String userId,
  ) {
    return firestore.collection('users').doc(userId).collection('favorites');
  }

  String _buildRecipeId(RecipeEntity recipe) {
    final canonical = <String, dynamic>{
      'name': recipe.name.trim(),
      'description': recipe.description.trim(),
      'ingredients': recipe.ingredients.map((item) => item.trim()).toList(),
      'steps': recipe.steps.map((item) => item.trim()).toList(),
      'difficulty': recipe.difficulty.trim(),
      'duration': recipe.duration.trim(),
    };
    final encoded = jsonEncode(canonical);
    final base64 = base64UrlEncode(utf8.encode(encoded));
    return base64.replaceAll('=', '');
  }

  String _readString(dynamic value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  List<String> _readList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const <String>[];
  }
}
