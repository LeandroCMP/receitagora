import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receitagora/modules/recipe_finder/domain/entities/recipe_entity.dart';
import 'package:receitagora/services/recipe/recipe_history_service.dart';

import 'shopping_list_service.dart';

class ShoppingListServiceImpl extends GetxService implements ShoppingListService {
  ShoppingListServiceImpl({required SharedPreferences preferences})
      : _preferences = preferences {
    _hydrate();
  }

  final SharedPreferences _preferences;

  static const String _storageKey = 'shopping.lists.index';

  final RxList<ShoppingList> _lists = <ShoppingList>[].obs;

  @override
  List<ShoppingList> get lists => List<ShoppingList>.unmodifiable(_lists);

  @override
  Stream<List<ShoppingList>> get listsStream => _lists.stream;

  @override
  ShoppingList? getById(String id) =>
      _lists.firstWhereOrNull((list) => list.id == id);

  @override
  Stream<ShoppingList?> watchList(String id) {
    return _lists.stream.map((lists) =>
        lists.firstWhereOrNull((element) => element.id == id));
  }

  @override
  Future<ShoppingList> createFromHistory({
    required RecipeHistoryResult historyResult,
    String? title,
    bool allowDuplicates = false,
  }) async {
    final normalizedTitle =
        (title ?? _buildTitle(historyResult.ingredients)).trim();
    final now = DateTime.now();

    final sections = <ShoppingListSection>[];
    final Set<String>? normalizedCache = allowDuplicates ? null : <String>{};

    for (final recipe in historyResult.recipes) {
      final section = _buildSectionFromRecipe(
        recipe,
        allowDuplicates: allowDuplicates,
        globalSeen: normalizedCache,
      );
      if (section.items.isEmpty && !allowDuplicates) {
        continue;
      }
      sections.add(section);
    }

    if (sections.isEmpty) {
      final fallbackItems = <ShoppingListItem>[];
      final fallbackSeen = normalizedCache;
      for (final ingredient in historyResult.ingredients) {
        final normalized = ingredient.trim();
        if (normalized.isEmpty) {
          continue;
        }
        final normalizedKey = normalized.toLowerCase();
        if (!allowDuplicates && fallbackSeen != null) {
          if (fallbackSeen.contains(normalizedKey)) {
            continue;
          }
          fallbackSeen.add(normalizedKey);
        }
        fallbackItems.add(
          ShoppingListItem(
            id: _generateId(prefix: 'item'),
            label: normalized,
            recipeName: 'Ingredientes salvos',
          ),
        );
      }
      final fallbackSection = ShoppingListSection(
        id: _generateId(prefix: 'section'),
        title: 'Lista rápida',
        items: List<ShoppingListItem>.unmodifiable(fallbackItems),
      );
      sections.add(fallbackSection);
    }

    final list = ShoppingList(
      id: _generateId(prefix: 'list'),
      title: normalizedTitle.isEmpty ? 'Lista de compras' : normalizedTitle,
      createdAt: now,
      updatedAt: now,
      sourceCacheKey: historyResult.cacheKey,
      sections: List<ShoppingListSection>.unmodifiable(sections),
    );

    await _upsert(list);
    return list;
  }

  @override
  Future<void> renameList({required String listId, required String title}) async {
    final list = getById(listId);
    if (list == null) {
      return;
    }
    final normalized = title.trim();
    final updated = list.copyWith(
      title: normalized.isEmpty ? list.title : normalized,
      updatedAt: DateTime.now(),
    );
    await _upsert(updated);
  }

  @override
  Future<void> updateNote({
    required String listId,
    required String? note,
  }) async {
    final list = getById(listId);
    if (list == null) {
      return;
    }
    final normalized = note?.trim();
    final updated = list.copyWith(
      note: normalized == null || normalized.isEmpty ? null : normalized,
      updatedAt: DateTime.now(),
    );
    await _upsert(updated);
  }

  @override
  Future<void> toggleItem({
    required String listId,
    required String sectionId,
    required String itemId,
  }) async {
    final list = getById(listId);
    if (list == null) {
      return;
    }

    final sections = list.sections.map((section) {
      if (section.id != sectionId) {
        return section;
      }
      final items = section.items.map((item) {
        if (item.id != itemId) {
          return item;
        }
        return item.copyWith(completed: !item.completed);
      }).toList();
      return section.copyWith(items: List<ShoppingListItem>.unmodifiable(items));
    }).toList();

    await _upsert(
      list.copyWith(
        sections: List<ShoppingListSection>.unmodifiable(sections),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> toggleSection({
    required String listId,
    required String sectionId,
    required bool markCompleted,
  }) async {
    final list = getById(listId);
    if (list == null) {
      return;
    }

    final sections = list.sections.map((section) {
      if (section.id != sectionId) {
        return section;
      }
      final items = section.items
          .map((item) => item.copyWith(completed: markCompleted))
          .toList();
      return section.copyWith(items: List<ShoppingListItem>.unmodifiable(items));
    }).toList();

    await _upsert(
      list.copyWith(
        sections: List<ShoppingListSection>.unmodifiable(sections),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> toggleAll({
    required String listId,
    required bool markCompleted,
  }) async {
    final list = getById(listId);
    if (list == null) {
      return;
    }

    final sections = list.sections
        .map(
          (section) => section.copyWith(
            items: List<ShoppingListItem>.unmodifiable(
              section.items
                  .map((item) => item.copyWith(completed: markCompleted))
                  .toList(),
            ),
          ),
        )
        .toList();

    await _upsert(
      list.copyWith(
        sections: List<ShoppingListSection>.unmodifiable(sections),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> removeList(String listId) async {
    final updated = List<ShoppingList>.from(_lists)
      ..removeWhere((element) => element.id == listId);
    _lists.assignAll(updated);
    await _persist();
  }

  @override
  Future<ShoppingListSharePayload?> sharePayloadFor(String listId) async {
    final list = getById(listId);
    if (list == null) {
      return null;
    }
    return ShoppingListSharePayload(
      title: list.title,
      sections: list.sections,
      note: list.note,
    );
  }

  Future<void> _upsert(ShoppingList list) async {
    final updated = List<ShoppingList>.from(_lists)
      ..removeWhere((element) => element.id == list.id)
      ..insert(0, list);
    updated.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _lists.assignAll(updated);
    await _persist();
  }

  Future<void> _persist() async {
    final payload = _lists.map((list) => list.toMap()).toList();
    await _preferences.setString(_storageKey, jsonEncode(payload));
  }

  void _hydrate() {
    final raw = _preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _lists.clear();
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Iterable) {
        _lists.clear();
        return;
      }

      final lists = decoded
          .map((dynamic item) =>
              ShoppingList.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
      lists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _lists.assignAll(lists);
    } catch (error, stackTrace) {
      Get.log(
        'Falha ao carregar listas de compras: $error\n$stackTrace',
        isError: true,
      );
      _lists.clear();
    }
  }

  ShoppingListSection _buildSectionFromRecipe(
    RecipeEntity recipe, {
    required bool allowDuplicates,
    Set<String>? globalSeen,
  }) {
    final items = <ShoppingListItem>[];
    final Set<String>? localSeen = allowDuplicates ? null : <String>{};

    for (final ingredient in recipe.ingredients) {
      final normalized = ingredient.trim();
      if (normalized.isEmpty) {
        continue;
      }
      final normalizedKey = normalized.toLowerCase();
      if (!allowDuplicates) {
        if (localSeen != null && localSeen.contains(normalizedKey)) {
          continue;
        }
        if (globalSeen != null && globalSeen.contains(normalizedKey)) {
          continue;
        }
      }
      localSeen?.add(normalizedKey);
      globalSeen?.add(normalizedKey);
      items.add(
        ShoppingListItem(
          id: _generateId(prefix: 'item'),
          label: normalized,
          recipeName: recipe.name,
        ),
      );
    }

    return ShoppingListSection(
      id: _generateId(prefix: 'section'),
      title: recipe.name.isEmpty ? 'Receita sem nome' : recipe.name,
      items: List<ShoppingListItem>.unmodifiable(items),
    );
  }

  String _buildTitle(List<String> ingredients) {
    final filtered = ingredients
        .map((ingredient) => ingredient.trim())
        .where((ingredient) => ingredient.isNotEmpty)
        .toList();
    if (filtered.isEmpty) {
      return 'Lista de compras';
    }
    if (filtered.length <= 3) {
      return 'Compras: ${filtered.join(', ')}';
    }
    final base = filtered.take(3).join(', ');
    return 'Compras: $base +${filtered.length - 3}';
  }

  String _generateId({required String prefix}) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = timestamp.hashCode.abs() % 100000;
    return '$prefix-$timestamp-$random';
  }
}
