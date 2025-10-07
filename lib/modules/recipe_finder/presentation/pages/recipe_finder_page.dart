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
      theme.colorScheme.primary.withOpacity(0.08),
      background,
    );
    final bottomBlend = Color.alphaBlend(
      Colors.black.withOpacity(0.12),
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
          child: Stack(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [topBlend, background, bottomBlend],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                top: -160,
                right: -90,
                child: _BackgroundOrb(color: theme.colorScheme.primary.withOpacity(0.24)),
              ),
              Positioned(
                bottom: -190,
                left: -70,
                child: _BackgroundOrb(color: theme.colorScheme.secondary.withOpacity(0.18)),
              ),
              LayoutBuilder(
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
                          const SizedBox(height: 26),
                          FadeTransition(
                            opacity: _quotaOpacity,
                            child: SlideTransition(
                              position: _quotaOffset,
                              child: _buildGuestQuota(theme),
                            ),
                          ),
                          const SizedBox(height: 26),
                          FadeTransition(
                            opacity: _ingredientsOpacity,
                            child: SlideTransition(
                              position: _ingredientsOffset,
                              child: _buildIngredientSection(theme),
                            ),
                          ),
                          const SizedBox(height: 34),
                          FadeTransition(
                            opacity: _buttonOpacity,
                            child: SlideTransition(
                              position: _buttonOffset,
                              child: _buildGenerateButton(theme),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Os resultados chegam em cartões animados com todos os detalhes na próxima tela.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.62),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(ThemeData theme) {
    final user = controller.sessionService.user;
    final name = user?.displayName?.trim();
    final rawGreeting = name != null && name.isNotEmpty ? name.split(' ').first : 'convidado';
    final sanitized = rawGreeting.trim();
    final greeting = sanitized.isNotEmpty
        ? '${sanitized[0].toUpperCase()}${sanitized.length > 1 ? sanitized.substring(1) : ''}'
        : 'Convidado';

    final gradient = LinearGradient(
      colors: [
        theme.colorScheme.primary.withOpacity(0.55),
        theme.colorScheme.primary.withOpacity(0.08),
      ],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    );

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: gradient,
        ),
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, $greeting',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pronto para descobrir algo delicioso hoje? Informe os ingredientes e nós cuidamos do resto.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.18),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: Colors.white.withOpacity(0.9),
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                _CategoryChip(label: 'Café da manhã'),
                _CategoryChip(label: 'Almoço'),
                _CategoryChip(label: 'Jantar'),
                _CategoryChip(label: 'Snacks'),
              ],
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
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(0.16),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasQuota ? 'Limite diário disponível' : 'Limite diário atingido',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.72),
                        height: 1.5,
                      ),
                    ),
                  ],
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
          padding: const EdgeInsets.fromLTRB(26, 28, 26, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withOpacity(0.16),
                    ),
                    child: Icon(Icons.shopping_basket_outlined, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quais ingredientes você tem hoje?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Adicione um ingrediente por vez para receber sugestões equilibradas.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.68),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
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
              const SizedBox(height: 20),
              if (controller.ingredients.isEmpty)
                Text(
                  'empty_ingredient_hint'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    height: 1.5,
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _BackgroundOrb extends StatelessWidget {
  const _BackgroundOrb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.05)],
        ),
      ),
    );
  }
}
