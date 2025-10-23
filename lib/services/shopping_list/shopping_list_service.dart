import 'package:collection/collection.dart';

import 'package:receitagora/services/recipe/recipe_history_service.dart';

class ShoppingListItem {
  const ShoppingListItem({
    required this.id,
    required this.label,
    required this.recipeName,
    this.quantity,
    this.completed = false,
  });

  final String id;
  final String label;
  final String recipeName;
  final String? quantity;
  final bool completed;

  String get normalizedLabel => label.trim();

  ShoppingListItem copyWith({
    String? label,
    String? recipeName,
    String? quantity,
    bool? completed,
  }) {
    return ShoppingListItem(
      id: id,
      label: label ?? this.label,
      recipeName: recipeName ?? this.recipeName,
      quantity: quantity ?? this.quantity,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'recipeName': recipeName,
      'quantity': quantity,
      'completed': completed,
    };
  }

  factory ShoppingListItem.fromMap(Map<String, dynamic> map) {
    return ShoppingListItem(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      recipeName: map['recipeName'] as String? ?? '',
      quantity: map['quantity'] as String?,
      completed: map['completed'] as bool? ?? false,
    );
  }
}

class ShoppingListSection {
  const ShoppingListSection({
    required this.id,
    required this.title,
    required this.items,
  });

  final String id;
  final String title;
  final List<ShoppingListItem> items;

  int get totalItems => items.length;
  int get completedItems => items.where((item) => item.completed).length;

  ShoppingListSection copyWith({
    String? title,
    List<ShoppingListItem>? items,
  }) {
    return ShoppingListSection(
      id: id,
      title: title ?? this.title,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  factory ShoppingListSection.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    final items = rawItems is Iterable
        ? rawItems
            .map((dynamic item) =>
                ShoppingListItem.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList()
        : <ShoppingListItem>[];

    return ShoppingListSection(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      items: List<ShoppingListItem>.unmodifiable(items),
    );
  }
}

class ShoppingList {
  const ShoppingList({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceCacheKey,
    required this.sections,
    this.note,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? sourceCacheKey;
  final List<ShoppingListSection> sections;
  final String? note;

  int get totalItems =>
      sections.fold<int>(0, (total, section) => total + section.totalItems);
  int get completedItems => sections
      .fold<int>(0, (total, section) => total + section.completedItems);

  bool get isEmpty => totalItems == 0;
  bool get isCompleted => totalItems > 0 && completedItems == totalItems;

  double get completionRate {
    if (totalItems == 0) {
      return 0;
    }
    return completedItems / totalItems;
  }

  ShoppingList copyWith({
    String? title,
    DateTime? updatedAt,
    List<ShoppingListSection>? sections,
    String? note,
  }) {
    return ShoppingList(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceCacheKey: sourceCacheKey,
      sections: sections ?? this.sections,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'sourceCacheKey': sourceCacheKey,
      'sections': sections.map((section) => section.toMap()).toList(),
      'note': note,
    };
  }

  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    final rawSections = map['sections'];
    final sections = rawSections is Iterable
        ? rawSections
            .map((dynamic item) => ShoppingListSection.fromMap(
                Map<String, dynamic>.from(item as Map)))
            .toList()
        : <ShoppingListSection>[];

    final createdAtRaw = map['createdAt'] as String?;
    final updatedAtRaw = map['updatedAt'] as String?;

    return ShoppingList(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      createdAt:
          createdAtRaw != null ? DateTime.tryParse(createdAtRaw)?.toLocal() ?? DateTime.now() : DateTime.now(),
      updatedAt:
          updatedAtRaw != null ? DateTime.tryParse(updatedAtRaw)?.toLocal() ?? DateTime.now() : DateTime.now(),
      sourceCacheKey: map['sourceCacheKey'] as String?,
      sections: List<ShoppingListSection>.unmodifiable(sections),
      note: map['note'] as String?,
    );
  }
}

class ShoppingListSharePayload {
  const ShoppingListSharePayload({
    required this.title,
    required this.sections,
    this.note,
  });

  final String title;
  final List<ShoppingListSection> sections;
  final String? note;

  String asText({bool includeNote = true}) {
    final buffer = StringBuffer()
      ..writeln('Lista de compras: $title');
    if (includeNote && note != null && note!.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Observações:')
        ..writeln(note!.trim());
    }
    for (final section in sections) {
      buffer
        ..writeln()
        ..writeln(section.title);
      for (final item in section.items) {
        final quantity = item.quantity?.trim();
        final prefix = item.completed ? '[x]' : '[ ]';
        if (quantity == null || quantity.isEmpty) {
          buffer.writeln('$prefix ${item.label.trim()}');
        } else {
          buffer.writeln('$prefix ${item.label.trim()} • $quantity');
        }
      }
    }
    return buffer.toString().trim();
  }
}

abstract class ShoppingListService {
  List<ShoppingList> get lists;
  Stream<List<ShoppingList>> get listsStream;

  ShoppingList? getById(String id);
  Stream<ShoppingList?> watchList(String id);

  Future<ShoppingList> createFromHistory({
    required RecipeHistoryResult historyResult,
    String? title,
    bool allowDuplicates,
  });

  Future<void> renameList({required String listId, required String title});
  Future<void> updateNote({required String listId, required String? note});
  Future<void> toggleItem({
    required String listId,
    required String sectionId,
    required String itemId,
  });

  Future<void> toggleSection({
    required String listId,
    required String sectionId,
    required bool markCompleted,
  });

  Future<void> toggleAll({required String listId, required bool markCompleted});
  Future<void> removeList(String listId);
  Future<ShoppingListSharePayload?> sharePayloadFor(String listId);
}
