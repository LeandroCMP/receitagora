import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/application/ui/widgets/app_page_background.dart';
import 'package:receitagora/application/utils/app_layout.dart';
import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/modules/favorites/favorited_recipe_entity.dart';
import 'package:receitagora/services/recipe/notebooks/favorites_notebook_service.dart';

import 'favorites_notebook_detail_controller.dart';

class FavoritesNotebookDetailPage
    extends GetView<FavoritesNotebookDetailController> {
  const FavoritesNotebookDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final notebook = controller.current;
          return Text(notebook?.title ?? 'Caderno');
        }),
      ),
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
                  final notebook = controller.current;
                  final favorites = controller.favorites.toList();
                  if (notebook == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final surfaces = theme.extension<ReceitagoraSurfaceColors>();

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
                            _NotebookOverview(
                              theme: theme,
                              surfaces: surfaces,
                              controller: controller,
                              notebook: notebook,
                            ),
                            const SizedBox(height: 24),
                            _FavoritesSection(
                              theme: theme,
                              controller: controller,
                              favorites: favorites,
                            ),
                            const SizedBox(height: 24),
                            _CommentsSection(
                              theme: theme,
                              controller: controller,
                              notebook: notebook,
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
}

class _NotebookOverview extends StatelessWidget {
  const _NotebookOverview({
    required this.theme,
    required this.surfaces,
    required this.controller,
    required this.notebook,
  });

  final ThemeData theme;
  final ReceitagoraSurfaceColors? surfaces;
  final FavoritesNotebookDetailController controller;
  final FavoritesNotebook notebook;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              notebook.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              notebook.description ??
                  'Sem descrição. Adicione notas para contextualizar este caderno.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.people_alt_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '${notebook.members.length} colaborador${notebook.members.length == 1 ? '' : 'es'}',
                  style: theme.textTheme.bodyMedium,
                ),
                const Spacer(),
                Switch.adaptive(
                  value: notebook.isCollaborative,
                  onChanged:
                      notebook.isOwner ? controller.toggleCollaboration : null,
                ),
                const SizedBox(width: 8),
                Text(
                  notebook.isOwner ? 'Colaborativo' : 'Somente leitura',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        (notebook.isOwner ||
                                (notebook.shareCode != null &&
                                    notebook.shareCode!.isNotEmpty))
                            ? () async {
                                final code = await controller.ensureShareCode();
                                if (code != null) {
                                  await Clipboard.setData(
                                    ClipboardData(text: code),
                                  );
                                  AppSnackbar.success(
                                    title: 'Código copiado',
                                    message:
                                        'Envie $code para convidar outras pessoas.',
                                  );
                                }
                              }
                            : null,
                    icon: const Icon(Icons.share_outlined),
                    label: Text(
                      notebook.shareCode == null
                          ? (notebook.isOwner
                              ? 'Gerar código'
                              : 'Aguardando convite')
                          : (notebook.isOwner
                              ? 'Compartilhar ${notebook.shareCode}'
                              : 'Copiar ${notebook.shareCode}'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Exportar resumo',
                  onPressed: () async {
                    final export = await controller.exportNotebook();
                    if (export != null) {
                      await Clipboard.setData(ClipboardData(text: export));
                      AppSnackbar.info(
                        title: 'Resumo copiado',
                        message: 'Cole a mensagem para compartilhar o caderno.',
                      );
                    }
                  },
                  icon: const Icon(Icons.download_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection({
    required this.theme,
    required this.controller,
    required this.favorites,
  });

  final ThemeData theme;
  final FavoritesNotebookDetailController controller;
  final List<FavoritedRecipeEntity> favorites;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final notebook = controller.current;
    if (notebook == null) {
      return const SizedBox.shrink();
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Selecione as receitas deste caderno',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (favorites.isEmpty)
              Text(
                'Nenhuma receita favoritada ainda. Adicione favoritos primeiro e organize-os aqui.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              )
            else
              ...favorites.map(
                (favorite) => CheckboxListTile(
                  value: controller.containsFavorite(favorite.id),
                  onChanged: (checked) => controller.toggleFavorite(
                    favorite,
                    checked ?? false,
                  ),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(favorite.recipe.name),
                  subtitle: Text(
                    favorite.recipe.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CommentsSection extends StatefulWidget {
  const _CommentsSection({
    required this.theme,
    required this.controller,
    required this.notebook,
  });

  final ThemeData theme;
  final FavoritesNotebookDetailController controller;
  final FavoritesNotebook notebook;

  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final colorScheme = theme.colorScheme;
    final notebook = widget.notebook;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Comentários',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'Agradeça uma dica ou combine ajustes nas receitas...',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    final text = _commentController.text.trim();
                    if (text.isEmpty) {
                      return;
                    }
                    widget.controller.addComment(text);
                    _commentController.clear();
                  },
                  child: const Text('Enviar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (notebook.comments.isEmpty)
              Text(
                'Sem comentários até agora. Use este espaço para combinar ajustes e sugestões com seus colaboradores.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              )
            else
              ...notebook.comments.map(
                (comment) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      comment.authorName.isEmpty
                          ? '?'
                          : comment.authorName.characters.first.toUpperCase(),
                    ),
                  ),
                  title: Text(comment.authorName),
                  subtitle: Text(comment.message),
                  trailing: Text(
                    _formatDate(comment.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
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
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}
