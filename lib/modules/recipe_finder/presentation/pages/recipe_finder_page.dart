import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/session_service.dart';
import '../controllers/recipe_finder_controller.dart';
import '../widgets/ingredient_chip.dart';

const double _compactBreakpoint = 480.0;
const double _mediumBreakpoint = 840.0;

bool _isCompactWidth(double width) => width < _compactBreakpoint;

bool _isExpandedWidth(double width) => width >= _mediumBreakpoint;

T _valueForWidth<T>({
  required double width,
  required T compact,
  T? medium,
  T? expanded,
}) {
  T result;

  if (_isExpandedWidth(width) && expanded != null) {
    result = expanded;
  } else if (!_isCompactWidth(width) && medium != null) {
    result = medium;
  } else {
    result = compact;
  }

  if (T == double && result is num) {
    return result.toDouble() as T;
  }

  return result;
}

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
                  final horizontalPadding = _valueForWidth<double>(
                    width: constraints.maxWidth,
                    compact: 22,
                    medium: 32,
                    expanded: 40,
                  );
                  final verticalPadding = _valueForWidth<double>(
                    width: constraints.maxWidth,
                    compact: 28,
                    medium: 32,
                    expanded: 38,
                  );
                  final maxWidth = _valueForWidth<double>(
                    width: constraints.maxWidth,
                    compact: constraints.maxWidth,
                    medium: 560,
                    expanded: 720,
                  );

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: minHeight,
                          maxWidth: maxWidth,
                        ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = _isCompactWidth(width);
        final heroGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.75),
            theme.colorScheme.primary.withOpacity(0.32),
            theme.colorScheme.primary.withOpacity(0.12),
          ],
        );
        final cardHeight = _valueForWidth<double>(
          width: width,
          compact: 250,
          medium: 230,
          expanded: 220,
        );

        final avatar = CircleAvatar(
          radius: _valueForWidth<double>(
            width: width,
            compact: 24,
            medium: 26,
            expanded: 28,
          ),
          backgroundColor: theme.colorScheme.surfaceVariant,
          child: Icon(
            Icons.person_outline,
            color: theme.colorScheme.onSurface.withOpacity(0.75),
          ),
        );

        final greetingBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, $greeting',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pronto para cozinhar hoje à noite?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.68),
              ),
            ),
          ],
        );

        final header = isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  avatar,
                  const SizedBox(height: 18),
                  greetingBlock,
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: greetingBlock),
                  const SizedBox(width: 18),
                  avatar,
                ],
              );

        final heroMeta = const [
          _HeroStat(icon: Icons.schedule_rounded, label: '40 min'),
          _HeroStat(icon: Icons.group_outlined, label: 'Serve 3'),
          _HeroStat(icon: Icons.local_fire_department_rounded, label: '480 kcal'),
        ];

        final heroCard = Card(
          margin: EdgeInsets.zero,
          child: SizedBox(
            height: cardHeight,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: heroGradient,
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -24,
                    top: _valueForWidth<double>(
                      width: width,
                      compact: 46,
                      medium: 40,
                      expanded: 36,
                    ),
                    child: Container(
                      width: _valueForWidth<double>(
                        width: width,
                        compact: 168,
                        medium: 180,
                        expanded: 190,
                      ),
                      height: _valueForWidth<double>(
                        width: width,
                        compact: 168,
                        medium: 180,
                        expanded: 190,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.18),
                      ),
                    ),
                  ),
                  Positioned(
                    right: _valueForWidth<double>(
                      width: width,
                      compact: 20,
                      medium: 26,
                      expanded: 28,
                    ),
                    top: _valueForWidth<double>(
                      width: width,
                      compact: 32,
                      medium: 34,
                      expanded: 36,
                    ),
                    child: Container(
                      width: _valueForWidth<double>(
                        width: width,
                        compact: 118,
                        medium: 128,
                        expanded: 132,
                      ),
                      height: _valueForWidth<double>(
                        width: width,
                        compact: 118,
                        medium: 128,
                        expanded: 132,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.32),
                      ),
                      child: Icon(
                        Icons.ramen_dining,
                        color: Colors.black.withOpacity(0.75),
                        size: _valueForWidth<double>(
                          width: width,
                          compact: 46,
                          medium: 48,
                          expanded: 50,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: _valueForWidth<double>(
                      width: width,
                      compact: 20,
                      medium: 24,
                      expanded: 24,
                    ),
                    right: _valueForWidth<double>(
                      width: width,
                      compact: 20,
                      medium: 24,
                      expanded: 24,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent.withOpacity(0.85),
                      ),
                      child: SizedBox(
                        width: _valueForWidth<double>(
                          width: width,
                          compact: 40,
                          medium: 42,
                          expanded: 44,
                        ),
                        height: _valueForWidth<double>(
                          width: width,
                          compact: 40,
                          medium: 42,
                          expanded: 44,
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      _valueForWidth<double>(
                        width: width,
                        compact: 22,
                        medium: 26,
                        expanded: 28,
                      ),
                      _valueForWidth<double>(
                        width: width,
                        compact: 26,
                        medium: 28,
                        expanded: 28,
                      ),
                      _valueForWidth<double>(
                        width: width,
                        compact: 22,
                        medium: 26,
                        expanded: 28,
                      ),
                      _valueForWidth<double>(
                        width: width,
                        compact: 24,
                        medium: 28,
                        expanded: 28,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(
                            'Chicken baked',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Um clássico dourado com ervas frescas.',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Comece adicionando seus ingredientes favoritos e receba sugestões sob medida.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.85),
                            height: 1.4,
                          ),
                        ),
                        const Spacer(),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: heroMeta,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 26),
            heroCard,
            const SizedBox(height: 28),
            Text(
              'Categorias de refeição',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  _CategoryChip(label: 'Café da manhã', selected: false),
                  SizedBox(width: 12),
                  _CategoryChip(label: 'Almoço', selected: true),
                  SizedBox(width: 12),
                  _CategoryChip(label: 'Jantar', selected: false),
                  SizedBox(width: 12),
                  _CategoryChip(label: 'Snacks', selected: false),
                ],
              ),
            ),
          ],
        );
      },
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withOpacity(0.18),
                accentColor.withOpacity(0.08),
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.22),
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.72),
                        height: 1.45,
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
        margin: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 30, 28, 32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surfaceVariant.withOpacity(0.35),
                theme.colorScheme.surfaceVariant.withOpacity(0.12),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.18),
                    ),
                    child: Icon(Icons.shopping_basket_outlined, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 18),
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
                          'Adicione um ingrediente de cada vez e veja sugestões alinhadas ao seu paladar.',
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
              const SizedBox(height: 24),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withOpacity(0.08),
                  ),
                ),
                child: TextField(
                  controller: controller.ingredientTextController,
                  focusNode: controller.ingredientFocusNode,
                  textInputAction: TextInputAction.done,
                  onSubmitted: controller.addIngredient,
                  decoration: InputDecoration(
                    hintText: 'Digite um ingrediente e toque em adicionar',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => controller.addIngredient(
                        controller.ingredientTextController.text,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              if (controller.ingredients.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    'empty_ingredient_hint'.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.62),
                      height: 1.45,
                    ),
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
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
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
  const _CategoryChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = selected
        ? Colors.white.withOpacity(0.18)
        : Colors.white.withOpacity(0.08);
    final textColor = selected ? Colors.white : Colors.white.withOpacity(0.7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        border: selected
            ? Border.all(color: Colors.white.withOpacity(0.45), width: 1)
            : Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.local_dining, size: 16, color: Colors.white),
            ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
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
