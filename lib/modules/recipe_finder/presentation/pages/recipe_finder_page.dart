import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/session_service.dart';
import '../controllers/recipe_finder_controller.dart';
import '../widgets/ingredient_chip.dart';

class RecipeFinderPage extends StatefulWidget {
  const RecipeFinderPage({super.key});

  @override
  State<RecipeFinderPage> createState() => _RecipeFinderPageState();
}

class _RecipeFinderPageState extends State<RecipeFinderPage>
    with SingleTickerProviderStateMixin {
  late final RecipeFinderController controller =
      Get.find<RecipeFinderController>();
  late final AnimationController _introController;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerOffset;
  late final Animation<double> _quotaOpacity;
  late final Animation<Offset> _quotaOffset;
  late final Animation<double> _ingredientsOpacity;
  late final Animation<Offset> _ingredientsOffset;
  late final Animation<double> _buttonOpacity;
  late final Animation<Offset> _buttonOffset;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _headerOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0, 0.45, curve: Curves.easeOutCubic),
    );
    _headerOffset = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    _quotaOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.25, 0.6, curve: Curves.easeOutCubic),
    );
    _quotaOffset = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.25, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _ingredientsOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
    );
    _ingredientsOffset = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _buttonOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.7, 1, curve: Curves.easeOutCubic),
    );
    _buttonOffset = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.7, 1, curve: Curves.easeOutCubic),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _introController.forward();
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.background;
    final topBlend = Color.alphaBlend(
      theme.colorScheme.primary.withOpacity(0.04),
      background,
    );
    final bottomBlend = Color.alphaBlend(
      theme.colorScheme.secondary.withOpacity(0.03),
      background,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr),
        centerTitle: false,
        actions: [
          Obx(() {
            if (controller.isGuest.value) {
              return const SizedBox.shrink();
            }

            final user = controller.sessionService.user;
            if (user == null) {
              return const SizedBox.shrink();
            }

            final initialsSource =
                user.displayName.isNotEmpty ? user.displayName : user.email;
            final sanitized = initialsSource.trim();
            final initials =
                sanitized.isNotEmpty ? sanitized.substring(0, 1).toUpperCase() : '?';

            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.28),
                backgroundImage:
                    user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                child: user.avatarUrl == null
                    ? Text(
                        initials,
                        style: theme.textTheme.titleMedium,
                      )
                    : null,
              ),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [topBlend, background, bottomBlend],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minHeight = (constraints.maxHeight - 56).clamp(0.0, double.infinity);
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeTransition(
                          opacity: _headerOpacity,
                          child: SlideTransition(
                            position: _headerOffset,
                            child: _buildHeroHeader(theme),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: _quotaOpacity,
                          child: SlideTransition(
                            position: _quotaOffset,
                            child: _buildGuestQuota(theme),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: _ingredientsOpacity,
                          child: SlideTransition(
                            position: _ingredientsOffset,
                            child: _buildIngredientSection(theme),
                          ),
                        ),
                        const SizedBox(height: 32),
                        FadeTransition(
                          opacity: _buttonOpacity,
                          child: SlideTransition(
                            position: _buttonOffset,
                            child: _buildGenerateButton(theme),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Os resultados chegam com um resumo suave e detalhes em uma segunda tela.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.alphaBlend(
                      theme.colorScheme.primary.withOpacity(0.16),
                      theme.colorScheme.surface,
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    'Inspire-se agora',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Conte o que tem em casa para receber sugestões leves e prontas para o momento.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.68),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestQuota(ThemeData theme) {
    return Obx(() {
      if (!controller.isGuest.value) {
        return const SizedBox.shrink();
      }

      final remaining = controller.guestSearchesRemaining.value;
      final bool hasQuota = remaining > 0;
      final accentColor = hasQuota
          ? theme.colorScheme.primary
          : theme.colorScheme.error;
      final icon = hasQuota ? Icons.timelapse : Icons.lock_outline;
      final message = hasQuota
          ? 'Modo visitante: restam $remaining de ${SessionService.guestDailyLimit} buscas hoje. Cada pesquisa revela até ${SessionService.guestRecipeLimit} receitas resumidas.'
          : 'Modo visitante: limite diário atingido. Relaxe um pouco e volte amanhã para descobrir novas sugestões.';

      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildIngredientSection(ThemeData theme) {
    return Obx(
      () => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quais ingredientes você tem hoje?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller.ingredientTextController,
                focusNode: controller.ingredientFocusNode,
                textInputAction: TextInputAction.done,
                onSubmitted: controller.addIngredient,
                decoration: InputDecoration(
                  hintText: 'Digite um ingrediente e toque em adicionar',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => controller.addIngredient(
                      controller.ingredientTextController.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (controller.ingredients.isEmpty)
                Text(
                  'empty_ingredient_hint'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    height: 1.45,
                  ),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: controller.ingredients
                      .map(
                        (ingredient) => IngredientChip(
                          label: ingredient,
                          onDeleted: () => controller.removeIngredient(ingredient),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateButton(ThemeData theme) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: controller.isLoading.value
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onPrimary,
                    ),
                  ),
                )
              : const Icon(Icons.search_rounded),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('generate_recipes'.tr),
          ),
          onPressed:
              controller.isLoading.value ? null : controller.fetchRecipes,
        ),
      ),
    );
  }
}
