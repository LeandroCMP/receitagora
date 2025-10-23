import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/services/shopping_list/shopping_list_service.dart';

enum ShoppingListViewMode { recipe, market }

class ShoppingListDetailArgs {
  const ShoppingListDetailArgs({required this.listId});

  final String listId;
}

class AggregatedShoppingSection {
  const AggregatedShoppingSection({
    required this.id,
    required this.title,
    required this.items,
  });

  final String id;
  final String title;
  final List<AggregatedShoppingItem> items;

  bool get isCompleted => items.isNotEmpty && items.every((item) => item.completed);
}

class AggregatedShoppingItem {
  const AggregatedShoppingItem({
    required this.id,
    required this.label,
    required this.recipeSummary,
    required this.references,
    this.quantity,
    this.completed = false,
  });

  final String id;
  final String label;
  final String recipeSummary;
  final List<_ShoppingItemReference> references;
  final String? quantity;
  final bool completed;
}

class _ShoppingItemReference {
  const _ShoppingItemReference({
    required this.sectionId,
    required this.itemId,
    required this.completed,
  });

  final String sectionId;
  final String itemId;
  final bool completed;
}

class ShoppingListDetailController extends GetxController {
  ShoppingListDetailController({
    required this.args,
    required this.shoppingListService,
  });

  final ShoppingListDetailArgs args;
  final ShoppingListService shoppingListService;

  final Rxn<ShoppingList> list = Rxn<ShoppingList>();
  final Rx<ShoppingListViewMode> viewMode = ShoppingListViewMode.recipe.obs;
  final RxBool isSharing = false.obs;

  StreamSubscription<ShoppingList?>? _subscription;

  @override
  void onInit() {
    super.onInit();
    list.value = shoppingListService.getById(args.listId);
    _subscription =
        shoppingListService.watchList(args.listId).listen(list.call);
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  void toggleViewMode(ShoppingListViewMode mode) {
    if (viewMode.value != mode) {
      viewMode.value = mode;
    }
  }

  Future<void> toggleItem({
    required String sectionId,
    required String itemId,
  }) async {
    await shoppingListService.toggleItem(
      listId: args.listId,
      sectionId: sectionId,
      itemId: itemId,
    );
  }

  Future<void> toggleSection({
    required String sectionId,
    required bool markCompleted,
  }) async {
    await shoppingListService.toggleSection(
      listId: args.listId,
      sectionId: sectionId,
      markCompleted: markCompleted,
    );
  }

  Future<void> toggleAll({required bool markCompleted}) async {
    await shoppingListService.toggleAll(
      listId: args.listId,
      markCompleted: markCompleted,
    );
  }

  Future<void> toggleAggregatedItem(AggregatedShoppingItem item) async {
    final shouldMarkCompleted = !item.completed;
    final current = list.value;
    if (current == null) {
      return;
    }

    for (final reference in item.references) {
      final section = current.sections
          .firstWhereOrNull((section) => section.id == reference.sectionId);
      final shoppingItem = section?.items
          .firstWhereOrNull((element) => element.id == reference.itemId);
      if (shoppingItem == null) {
        continue;
      }
      if (shoppingItem.completed == shouldMarkCompleted) {
        continue;
      }
      await shoppingListService.toggleItem(
        listId: current.id,
        sectionId: reference.sectionId,
        itemId: reference.itemId,
      );
    }
  }

  Future<void> toggleAggregatedSection(AggregatedShoppingSection section) async {
    final shouldMarkCompleted = !section.isCompleted;
    final current = list.value;
    if (current == null) {
      return;
    }

    final seen = <String>{};
    for (final item in section.items) {
      for (final reference in item.references) {
        final key = '${reference.sectionId}::${reference.itemId}';
        if (seen.contains(key)) {
          continue;
        }
        seen.add(key);

        final sectionData = current.sections
            .firstWhereOrNull((element) => element.id == reference.sectionId);
        final shoppingItem = sectionData?.items
            .firstWhereOrNull((element) => element.id == reference.itemId);
        if (shoppingItem == null) {
          continue;
        }
        if (shoppingItem.completed == shouldMarkCompleted) {
          continue;
        }
        await shoppingListService.toggleItem(
          listId: current.id,
          sectionId: reference.sectionId,
          itemId: reference.itemId,
        );
      }
    }
  }

  Future<void> renameList(String title) async {
    await shoppingListService.renameList(listId: args.listId, title: title);
  }

  Future<void> updateNote(String? note) async {
    await shoppingListService.updateNote(listId: args.listId, note: note);
  }

  Future<void> removeList() async {
    await shoppingListService.removeList(args.listId);
    if (Get.isOverlaysOpen) {
      Get.back<void>();
    }
    Get.back<void>();
    AppSnackbar.info(
      title: 'Lista removida',
      message: 'Os itens desta lista foram descartados.',
    );
  }

  Future<void> shareList() async {
    if (isSharing.value) {
      return;
    }
    isSharing.value = true;
    try {
      final payload = await shoppingListService.sharePayloadFor(args.listId);
      if (payload == null) {
        AppSnackbar.info(
          title: 'Nada para compartilhar',
          message: 'Adicione itens à lista antes de enviar para alguém.',
        );
        return;
      }

      final content = payload.asText();
      await Share.share(content, subject: payload.title);
    } catch (error) {
      AppSnackbar.error(
        title: 'Não foi possível compartilhar',
        message: 'Tente novamente em instantes.',
      );
    } finally {
      isSharing.value = false;
    }
  }

  List<AggregatedShoppingSection> buildMarketSections() {
    final current = list.value;
    if (current == null) {
      return const <AggregatedShoppingSection>[];
    }

    final Map<String, Map<String, AggregatedShoppingItem>> grouped = {};

    for (final section in current.sections) {
      for (final item in section.items) {
        final category = _inferMarketCategory(item.label);
        final key = item.normalizedLabel.toLowerCase();
        final bucket = grouped.putIfAbsent(category, () => {});

        final summary = _mergeRecipeSummary(
          bucket[key]?.recipeSummary,
          item.recipeName,
        );

        final references = <_ShoppingItemReference>[
          ...?bucket[key]?.references,
          _ShoppingItemReference(
            sectionId: section.id,
            itemId: item.id,
            completed: item.completed,
          ),
        ];

        final completed = references.every((ref) => ref.completed);

        bucket[key] = AggregatedShoppingItem(
          id: '${category}_$key',
          label: item.label,
          recipeSummary: summary,
          references: references,
          quantity: item.quantity,
          completed: completed,
        );
      }
    }

    final sections = grouped.entries.map((entry) {
      final items = entry.value.values.toList()
        ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
      return AggregatedShoppingSection(
        id: entry.key,
        title: entry.key,
        items: items,
      );
    }).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return sections;
  }

  String _inferMarketCategory(String input) {
    final normalized = input.toLowerCase();
    const hortifrutiKeywords = <String>[
      'alface',
      'tomate',
      'cenoura',
      'batata',
      'banana',
      'maçã',
      'laranja',
      'limão',
      'folha',
      'couve',
      'pepino',
      'abacate',
      'abobrinha',
      'berinjela',
    ];
    const acougueKeywords = <String>[
      'carne',
      'frango',
      'bife',
      'filé',
      'peito',
      'cox',
      'linguiça',
      'salsicha',
      'pernil',
      'costela',
    ];
    const laticinioKeywords = <String>[
      'leite',
      'queijo',
      'manteiga',
      'iogurte',
      'requeijão',
      'creme de leite',
      'nata',
    ];
    const merceariaKeywords = <String>[
      'arroz',
      'feijão',
      'farinha',
      'massa',
      'macarrão',
      'cereal',
      'aveia',
      'grão',
      'lentilha',
      'grão-de-bico',
      'açúcar',
      'sal',
      'café',
      'chá',
    ];
    const temperosKeywords = <String>[
      'alho',
      'cebola',
      'azeite',
      'vinagre',
      'pimenta',
      'orégano',
      'salsa',
      'coentro',
      'tempero',
      'mostarda',
      'molho',
      'shoyu',
      'manjeric',
    ];
    const padariaKeywords = <String>[
      'pão',
      'bolo',
      'rosca',
      'torta',
      'massa folhada',
    ];
    const limpezaKeywords = <String>[
      'sabão',
      'detergente',
      'desinfetante',
      'esponja',
      'limpeza',
    ];

    bool matchesAny(Iterable<String> keywords) =>
        keywords.any((keyword) => normalized.contains(keyword));

    if (matchesAny(hortifrutiKeywords)) {
      return 'Hortifruti';
    }
    if (matchesAny(acougueKeywords)) {
      return 'Açougue';
    }
    if (matchesAny(laticinioKeywords)) {
      return 'Laticínios';
    }
    if (matchesAny(merceariaKeywords)) {
      return 'Mercearia';
    }
    if (matchesAny(temperosKeywords)) {
      return 'Temperos e molhos';
    }
    if (matchesAny(padariaKeywords)) {
      return 'Padaria';
    }
    if (matchesAny(limpezaKeywords)) {
      return 'Casa e limpeza';
    }

    return 'Outros';
  }

  String _mergeRecipeSummary(String? currentSummary, String recipeName) {
    final normalized = recipeName.trim();
    if (normalized.isEmpty) {
      return currentSummary ?? 'Receitas diversas';
    }

    if (currentSummary == null || currentSummary.isEmpty) {
      return normalized;
    }

    final entries = currentSummary.split(',').map((item) => item.trim()).toSet();
    entries.add(normalized);
    return entries.join(', ');
  }
}
