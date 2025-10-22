import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/application/ui/widgets/app_page_background.dart';
import 'package:receitagora/application/utils/app_layout.dart';
import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/modules/favorites/favorited_recipe_entity.dart';
import 'package:receitagora/services/recipe/notebooks/favorites_notebook_service.dart';

import 'favorites_notebook_detail_controller.dart';
import 'favorites_notebooks_controller.dart';

class FavoritesNotebooksPage extends GetView<FavoritesNotebooksController> {
  const FavoritesNotebooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadernos colaborativos'),
        actions: [
          IconButton(
            tooltip: 'Entrar com código',
            icon: const Icon(Icons.qr_code_2_outlined),
            onPressed: () => _showJoinDialog(context),
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: Obx(() {
        final isCreating = controller.isCreating.value;
        return FloatingActionButton.extended(
          onPressed: isCreating ? null : () => _showCreateDialog(context),
          icon: isCreating
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.create_new_folder_outlined),
          label: Text(isCreating ? 'Criando...' : 'Novo caderno'),
        );
      }),
      body: AppPageBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = AppPageLayout.resolve(
                constraints,
                maxWidth: 760,
                topPadding: 24,
                bottomPadding: 32,
              );

              final mediaQuery = MediaQuery.of(context);

              return MediaQuery(
                data: mediaQuery.copyWith(textScaler: layout.textScaler),
                child: Obx(() {
                  final notebooks = controller.notebooks.toList();
                  final favoritesMap =
                      Map<String, FavoritedRecipeEntity>.from(
                    controller.favoritesById,
                  );
                  return SingleChildScrollView(
                    padding: layout.padding,
                    physics: const BouncingScrollPhysics(),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: layout.maxContentWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _NotebooksIntroCard(theme: theme, surfaces: surfaces),
                            const SizedBox(height: 24),
                            if (notebooks.isEmpty)
                              _EmptyNotebooks(theme: theme, surfaces: surfaces)
                            else
                              ...notebooks.map(
                                (notebook) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _NotebookCard(
                                    theme: theme,
                                    surfaces: surfaces,
                                    controller: controller,
                                    notebook: notebook,
                                    favorites: favoritesMap,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    var collaborative = false;

    final result = await Get.dialog<_CreateNotebookResult>(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Novo caderno'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nome do caderno',
                      hintText: 'Ex.: Jantares rápidos',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (opcional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    value: collaborative,
                    onChanged: (value) => setState(() => collaborative = value),
                    title: const Text('Permitir colaboração'),
                    subtitle: const Text(
                      'Compartilhe um código para que amigos adicionem ou comentem receitas.',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  if (title.isEmpty) {
                    AppSnackbar.info(
                      title: 'Informe um nome',
                      message: 'Dê um nome ao caderno para identificá-lo depois.',
                    );
                    return;
                  }
                  Get.back(
                    result: _CreateNotebookResult(
                      title: title,
                      description: descriptionController.text.trim(),
                      collaborative: collaborative,
                    ),
                  );
                },
                child: const Text('Criar'),
              ),
            ],
          );
        },
      ),
      barrierDismissible: false,
      barrierColor: theme.colorScheme.scrim.withValues(alpha: 0.35),
    );

    if (result != null) {
      await controller.createNotebook(
        title: result.title,
        description: result.description.isEmpty ? null : result.description,
        collaborative: result.collaborative,
      );
    }
  }

  Future<void> _showJoinDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final codeController = TextEditingController();

    final result = await Get.dialog<String?>(
      AlertDialog(
        title: const Text('Entrar com código'),
        content: TextField(
          controller: codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Código de compartilhamento',
            hintText: 'Ex.: ABC123',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: codeController.text.trim()),
            child: const Text('Participar'),
          ),
        ],
      ),
      barrierDismissible: false,
      barrierColor: theme.colorScheme.scrim.withValues(alpha: 0.35),
    );

    if (result != null && result.isNotEmpty) {
      await controller.joinByShareCode(result);
    }
  }
}

class _CreateNotebookResult {
  const _CreateNotebookResult({
    required this.title,
    required this.description,
    required this.collaborative,
  });

  final String title;
  final String description;
  final bool collaborative;
}

class _NotebooksIntroCard extends StatelessWidget {
  const _NotebooksIntroCard({required this.theme, required this.surfaces});

  final ThemeData theme;
  final ReceitagoraSurfaceColors? surfaces;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.85),
            (surfaces?.surface ?? colorScheme.surfaceVariant).withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Organize coleções e convide amigos',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Agrupe favoritos por tema, marque comentários rápidos e compartilhe um código para montar cardápios colaborativos.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimary.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotebookCard extends StatelessWidget {
  const _NotebookCard({
    required this.theme,
    required this.surfaces,
    required this.controller,
    required this.notebook,
    required this.favorites,
  });

  final ThemeData theme;
  final ReceitagoraSurfaceColors? surfaces;
  final FavoritesNotebooksController controller;
  final FavoritesNotebook notebook;
  final Map<String, FavoritedRecipeEntity> favorites;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final recipeCount = notebook.favoriteIds.length;
    final membersCount = notebook.members.length;
    final formattedDate = _formatDate(notebook.updatedAt);
    final previewNames = notebook.favoriteIds
        .map((id) => favorites[id]?.recipe.name ?? '')
        .where((name) => name.trim().isNotEmpty)
        .map((name) => name.trim())
        .toList(growable: false);
    final preview = previewNames.take(3).toList(growable: false);
    final remaining = recipeCount - preview.length;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notebook.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notebook.description ?? 'Sem descrição. Use este espaço para resumir o objetivo do caderno.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  notebook.isCollaborative
                      ? Icons.groups_outlined
                      : Icons.person_outline,
                  color: colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InfoChip(
                  theme: theme,
                  icon: Icons.bookmark_outline,
                  label: recipeCount == 1
                      ? '1 receita'
                      : '$recipeCount receitas',
                ),
                _InfoChip(
                  theme: theme,
                  icon: Icons.people_alt_outlined,
                  label: membersCount == 1
                      ? 'Somente você'
                      : '$membersCount colaboradores',
                ),
                _InfoChip(
                  theme: theme,
                  icon: Icons.update,
                  label: 'Atualizado em $formattedDate',
                ),
              ],
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...preview.map(
                    (name) => Chip(
                      label: Text(name),
                      backgroundColor:
                          colorScheme.surfaceVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  if (remaining > 0)
                    Chip(
                      label: Text('+$remaining'),
                      backgroundColor:
                          colorScheme.surfaceVariant.withValues(alpha: 0.3),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () => Get.toNamed(
                    AppRoutes.favoritesNotebookDetail,
                    arguments:
                        FavoritesNotebookDetailArgs(notebookId: notebook.id),
                  ),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Abrir caderno'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final code = notebook.shareCode ??
                        await controller.ensureShareCodeFor(notebook);
                    if (code != null) {
                      await Clipboard.setData(ClipboardData(text: code));
                      AppSnackbar.success(
                        title: 'Código copiado',
                        message: 'Compartilhe $code para convidar colaboradores.',
                      );
                    }
                  },
                  icon: const Icon(Icons.link_outlined),
                  label: const Text('Copiar código'),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () async {
                    final export = await controller.exportNotebook(notebook);
                    if (export != null) {
                      await Clipboard.setData(ClipboardData(text: export));
                      AppSnackbar.info(
                        title: 'Resumo copiado',
                        message:
                            'O conteúdo do caderno foi copiado para a área de transferência.',
                      );
                    }
                  },
                  icon: const Icon(Icons.ios_share_outlined),
                  label: const Text('Exportar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.theme,
    required this.icon,
    required this.label,
  });

  final ThemeData theme;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotebooks extends StatelessWidget {
  const _EmptyNotebooks({required this.theme, required this.surfaces});

  final ThemeData theme;
  final ReceitagoraSurfaceColors? surfaces;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: (surfaces?.surface ?? colorScheme.surfaceVariant).withValues(alpha: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.collections_bookmark_outlined,
              size: 48, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Você ainda não criou nenhum caderno.',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Agrupe receitas favoritas em coleções temáticas e convide outras pessoas para comentar.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.72),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
