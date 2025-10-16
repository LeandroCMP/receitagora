import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import 'package:receitagora/modules/favorites/favorited_recipe_entity.dart';
import 'package:receitagora/modules/recipe_finder/domain/entities/recipe_entity.dart';

import 'recipe_favorites_service.dart';

class RecipeFavoritesServiceImpl extends GetxService
    implements RecipeFavoritesService {
  RecipeFavoritesServiceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  })  : _firestore = firestore,
        _firebaseAuth = firebaseAuth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  final RxSet<String> _favoriteIds = <String>{}.obs;
  final RxList<FavoritedRecipeEntity> _favorites =
      <FavoritedRecipeEntity>[].obs;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _favoritesSubscription;

  @override
  Stream<Set<String>> get favoriteIdsStream => _favoriteIds.stream;

  @override
  Stream<List<FavoritedRecipeEntity>> get favoritesStream =>
      _favorites.stream;

  @override
  Set<String> get favoriteIds => UnmodifiableSetView(_favoriteIds);

  @override
  List<FavoritedRecipeEntity> get favorites =>
      UnmodifiableListView(_favorites);

  @override
  void onInit() {
    super.onInit();
    _authSubscription =
        _firebaseAuth.userChanges().listen(_handleUserChanged);
    _handleUserChanged(_firebaseAuth.currentUser);
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _favoritesSubscription?.cancel();
    super.onClose();
  }

  @override
  String favoriteIdFor(RecipeEntity recipe) => _buildRecipeId(recipe);

  @override
  bool isFavoriteSync(RecipeEntity recipe) {
    final id = favoriteIdFor(recipe);
    return _favoriteIds.contains(id);
  }

  @override
  Future<void> addFavorite(RecipeEntity recipe) async {
    final user = _requireAuthenticatedUser();

    final document =
        _userFavoritesCollection(user.uid).doc(favoriteIdFor(recipe));

    try {
      await document.set(
        {
          'name': recipe.name,
          'description': recipe.description,
          'ingredients': recipe.ingredients,
          'steps': recipe.steps,
          'difficulty': recipe.difficulty,
          'duration': recipe.duration,
          'favoritedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (error) {
      final message = error.message?.trim();
      throw FavoritesFailure(
        message == null || message.isEmpty
            ? 'Não foi possível adicionar esta receita aos favoritos agora.'
            : message,
      );
    }
  }

  @override
  Future<void> removeFavoriteForRecipe(RecipeEntity recipe) async {
    await removeFavoriteById(favoriteIdFor(recipe));
  }

  @override
  Future<void> removeFavoriteById(String id) async {
    final user = _requireAuthenticatedUser();

    final document = _userFavoritesCollection(user.uid).doc(id);

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

  @override
  Future<void> toggleFavorite(RecipeEntity recipe) async {
    final favoriteId = favoriteIdFor(recipe);
    if (_favoriteIds.contains(favoriteId)) {
      await removeFavoriteById(favoriteId);
    } else {
      await addFavorite(recipe);
    }
  }

  User _requireAuthenticatedUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FavoritesFailure(
        'Faça login para salvar e gerenciar seus favoritos.',
      );
    }
    return user;
  }

  void _handleUserChanged(User? user) {
    _favoritesSubscription?.cancel();
    _favorites.clear();
    _favoriteIds.clear();

    if (user == null) {
      return;
    }

    final collection = _userFavoritesCollection(user.uid)
        .orderBy('favoritedAt', descending: true);
    _favoritesSubscription = collection.snapshots().listen(
      (snapshot) {
        final mapped = snapshot.docs.map(_mapDocument).toList();
        _favorites.assignAll(mapped);
        _favoriteIds
          ..clear()
          ..addAll(mapped.map((item) => item.id));
      },
      onError: (Object error, StackTrace stackTrace) {
        Get.log(
          'Erro ao escutar favoritos do usuário: $error\n$stackTrace',
          isError: true,
        );
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
    return _firestore.collection('users').doc(userId).collection('favorites');
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
