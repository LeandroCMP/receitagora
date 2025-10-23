import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/application/ui/widgets/app_page_background.dart';
import 'package:receitagora/application/utils/app_layout.dart';
import 'package:receitagora/services/restaurants/restaurant_discovery_service.dart';

import 'restaurant_discovery_controller.dart';

class RestaurantDiscoveryPage extends GetView<RestaurantDiscoveryController> {
  const RestaurantDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurantes recomendados'),
        actions: [
          Obx(() {
            final isLoading = controller.isLoading.value;
            final hasPlanFocus = controller.planFocuses.isNotEmpty;
            return IconButton(
              onPressed: isLoading ? null : controller.refreshPlanFocuses,
              tooltip: hasPlanFocus
                  ? 'Atualizar sugestões do plano'
                  : 'Buscar sugestões alinhadas ao plano',
              icon: const Icon(Icons.refresh_outlined),
            );
          }),
        ],
      ),
      body: AppPageBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = AppPageLayout.resolve(
                constraints,
                maxWidth: 760,
                topPadding: 28,
                bottomPadding: 40,
              );

              final mediaQuery = MediaQuery.of(context);

              return MediaQuery(
                data: mediaQuery.copyWith(textScaler: layout.textScaler),
                child: SingleChildScrollView(
                  padding: layout.padding,
                  physics: const BouncingScrollPhysics(),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
                      child: Obx(() {
                        final mode = controller.searchMode.value;
                        final selectedFocus = controller.selectedFocus.value;
                        final planFocuses = controller.planFocuses.toList();
                        final baseFocuses = controller.baseFocuses.toList();
                        final isLoading = controller.isLoading.value;
                        final feedback = controller.feedbackMessage.value;
                        final resolvedArea = controller.resolvedArea.value;
                        final results = controller.results.toList();
                        final manualCityError = controller.manualCityError.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _IntroCard(theme: theme, surfaces: surfaces),
                            const SizedBox(height: 24),
                            _SearchModeSelector(
                              theme: theme,
                              mode: mode,
                              controller: controller,
                              manualCityError: manualCityError,
                            ),
                            if (planFocuses.isNotEmpty) ...[
                              const SizedBox(height: 28),
                              _FocusSection(
                                theme: theme,
                                title: 'Sugeridos pelo seu plano',
                                subtitle:
                                    'Aproveite as categorias alinhadas ao objetivo atual do seu cardápio.',
                                focuses: planFocuses,
                                selected: selectedFocus,
                                onSelected: controller.toggleFocus,
                                highlightColor: theme.colorScheme.primaryContainer,
                              ),
                            ],
                            const SizedBox(height: 24),
                            _FocusSection(
                              theme: theme,
                              title: 'Preferências do momento',
                              subtitle:
                                  'Escolha o estilo de cozinha para refinar as recomendações de acordo com o que você quer comer agora.',
                              focuses: baseFocuses,
                              selected: selectedFocus,
                              onSelected: controller.toggleFocus,
                              allowClear: selectedFocus != null,
                              onClear: controller.clearFocus,
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () => controller.executeSearch(
                                        forceRefreshLocation:
                                            mode == RestaurantSearchMode.currentLocation,
                                      ),
                              icon: const Icon(Icons.restaurant_menu_outlined),
                              label: Text(
                                mode == RestaurantSearchMode.currentLocation
                                    ? 'Buscar restaurantes próximos'
                                    : 'Buscar restaurantes',
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (isLoading) const LinearProgressIndicator(minHeight: 2),
                            if (!isLoading && feedback == null)
                              _HintCard(theme: theme),
                            if (feedback != null) ...[
                              const SizedBox(height: 16),
                              _FeedbackBanner(
                                theme: theme,
                                message: feedback,
                                resolvedArea: resolvedArea,
                                hasResults: results.isNotEmpty,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (!isLoading && results.isEmpty && feedback != null)
                              _EmptyStateCard(
                                theme: theme,
                                focus: selectedFocus,
                                areaLabel: resolvedArea,
                              ),
                            if (results.isNotEmpty)
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: results.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final suggestion = results[index];
                                  return _RestaurantCard(theme: theme, suggestion: suggestion);
                                },
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.theme, required this.surfaces});

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
            colorScheme.primaryContainer.withValues(alpha: 0.9),
            (surfaces?.surface ?? colorScheme.surfaceVariant).withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 26, 26, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mapa de restaurantes inteligentes',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Descubra locais próximos que combinam com o seu plano nutricional ou com o desejo do momento. '
              'Use a localização atual ou informe uma cidade para receber indicações personalizadas.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.82),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                _IntroPill(icon: Icons.my_location, label: 'Localização em tempo real'),
                _IntroPill(icon: Icons.restaurant_outlined, label: 'Cardápios alinhados ao plano'),
                _IntroPill(icon: Icons.filter_list, label: 'Filtros por tipo de cozinha'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPill extends StatelessWidget {
  const _IntroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: colorScheme.onPrimary.withValues(alpha: 0.08),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colorScheme.onPrimaryContainer),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchModeSelector extends StatelessWidget {
  const _SearchModeSelector({
    required this.theme,
    required this.mode,
    required this.controller,
    this.manualCityError,
  });

  final ThemeData theme;
  final RestaurantSearchMode mode;
  final RestaurantDiscoveryController controller;
  final String? manualCityError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Como você prefere buscar?',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SegmentedButton<RestaurantSearchMode>(
          segments: const [
            ButtonSegment(
              value: RestaurantSearchMode.currentLocation,
              icon: Icon(Icons.near_me_outlined),
              label: Text('Minha localização'),
            ),
            ButtonSegment(
              value: RestaurantSearchMode.manualCity,
              icon: Icon(Icons.location_city_outlined),
              label: Text('Informar cidade'),
            ),
          ],
          selected: <RestaurantSearchMode>{mode},
          onSelectionChanged: (selection) {
            if (selection.isEmpty) {
              return;
            }
            controller.setSearchMode(selection.first);
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return colorScheme.onPrimary;
              }
              return colorScheme.onSurfaceVariant;
            }),
          ),
        ),
        if (mode == RestaurantSearchMode.manualCity) ...[
          const SizedBox(height: 16),
          TextField(
            controller: controller.cityController,
            decoration: InputDecoration(
              labelText: 'Cidade',
              hintText: 'Ex.: São Paulo ou Salvador',
              prefixIcon: const Icon(Icons.search),
              errorText: manualCityError,
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => controller.executeSearch(),
          ),
        ],
      ],
    );
  }
}

class _FocusSection extends StatelessWidget {
  const _FocusSection({
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.focuses,
    required this.selected,
    required this.onSelected,
    this.allowClear = false,
    this.onClear,
    this.highlightColor,
  });

  final ThemeData theme;
  final String title;
  final String subtitle;
  final List<RestaurantFocus> focuses;
  final RestaurantFocus? selected;
  final void Function(RestaurantFocus focus) onSelected;
  final bool allowClear;
  final VoidCallback? onClear;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    if (focuses.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      elevation: 0,
      color: highlightColor?.withValues(alpha: 0.18) ?? colorScheme.surfaceVariant.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                if (allowClear)
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Limpar'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 12,
              children: focuses.map((focus) {
                final isSelected = selected?.id == focus.id;
                final labelPrefix = focus.emoji != null ? '${focus.emoji!} ' : '';
                return Tooltip(
                  message: focus.description ?? focus.label,
                  child: ChoiceChip(
                    label: Text('$labelPrefix${focus.label}'),
                    selected: isSelected,
                    onSelected: (_) => onSelected(focus),
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Defina o modo de busca, escolha um filtro e toque em "Buscar restaurantes" para visualizar as opções recomendadas.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.theme,
    required this.message,
    required this.resolvedArea,
    required this.hasResults,
  });

  final ThemeData theme;
  final String message;
  final String? resolvedArea;
  final bool hasResults;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: hasResults
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceVariant.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              hasResults ? Icons.check_circle_outline : Icons.info_outline,
              color: hasResults ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (resolvedArea != null && resolvedArea!.isNotEmpty)
                    Text(
                      resolvedArea!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  if (resolvedArea != null && resolvedArea!.isNotEmpty)
                    const SizedBox(height: 4),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.theme,
    required this.focus,
    required this.areaLabel,
  });

  final ThemeData theme;
  final RestaurantFocus? focus;
  final String? areaLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    final focusLabel = focus?.label ?? 'os estilos selecionados';
    final area = areaLabel == null || areaLabel!.isEmpty ? 'na região escolhida' : 'em $areaLabel';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search_off_outlined, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nenhum parceiro encontrado',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Ainda não há restaurantes de $focusLabel $area. Experimente outro filtro ou busque por uma cidade vizinha.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.theme, required this.suggestion});

  final ThemeData theme;
  final RestaurantSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final distance = suggestion.distanceKm;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.restaurant_outlined, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${suggestion.primaryCuisine} • ${suggestion.priceRange}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        suggestion.address,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (suggestion.rating > 0)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            suggestion.rating.toStringAsFixed(1),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (distance != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.place_outlined, size: 18, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDistance(distance)} de você',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            if (suggestion.dietHighlights.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Por que combina com você',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...suggestion.dietHighlights.map(
                (highlight) => _BulletItem(
                  theme: theme,
                  icon: Icons.check_circle_outline,
                  text: highlight,
                ),
              ),
            ],
            if (suggestion.specialties.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Destaques do cardápio',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...suggestion.specialties.map(
                (item) => _BulletItem(
                  theme: theme,
                  icon: Icons.restaurant_menu,
                  text: item,
                ),
              ),
            ],
            if (suggestion.services.isNotEmpty) ...[
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: suggestion.services
                    .map(
                      (service) => Chip(
                        label: Text(service),
                        avatar: const Icon(Icons.event_available, size: 16),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDistance(double distance) {
    if (distance >= 10) {
      return '${distance.toStringAsFixed(0)} km';
    }
    return '${distance.toStringAsFixed(1)} km';
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({
    required this.theme,
    required this.icon,
    required this.text,
  });

  final ThemeData theme;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
