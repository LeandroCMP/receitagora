import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/application/utils/app_layout.dart';
import 'package:receitagora/models/billing_plan.dart';

import 'premium_plans_controller.dart';

class PremiumPlansPage extends GetView<PremiumPlansController> {
  const PremiumPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    final background = theme.colorScheme.background;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planos premium'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                theme.colorScheme.primary.withOpacity(0.05),
                surfaces?.lowest ?? background,
              ),
              background,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = AppPageLayout.resolve(
                constraints,
                maxWidth: 620,
                topPadding: 24,
                bottomPadding: 32,
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
                      constraints:
                          BoxConstraints(maxWidth: layout.maxContentWidth),
                      child: Obx(
                        () {
                          final plans = controller.plans;
                          final isLoading = controller.isLoading.value;
                          if (isLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 64),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (plans.isEmpty) {
                            return _EmptyState(theme: theme);
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Escolha o plano ideal para você',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Assinando o Receita Agora Premium você libera limites ampliados, recomendações exclusivas e histórico completo.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.72),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ...plans.map(
                                (plan) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: _PlanCard(
                                    plan: plan,
                                    controller: controller,
                                    theme: theme,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Ao continuar, a cobrança é processada pela Stripe com segurança e você poderá gerenciar ou cancelar quando quiser.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.controller,
    required this.theme,
  });

  final BillingPlan plan;
  final PremiumPlansController controller;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final highlight = plan.highlighted;
    final colorScheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      color: highlight
          ? Color.alphaBlend(
              colorScheme.primary.withOpacity(0.08),
              theme.colorScheme.surface,
            )
          : null,
      elevation: highlight ? 2 : 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  highlight ? Icons.workspace_premium : Icons.star_outline,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    plan.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plan.displayPrice,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
            if (plan.description != null && plan.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                plan.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Obx(
              () => FilledButton.icon(
                onPressed: controller.isProcessing.value
                    ? null
                    : () => controller.subscribe(plan),
                icon: controller.isProcessing.value
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_open),
                label: Text(controller.isProcessing.value
                    ? 'Processando...'
                    : 'Assinar este plano'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 96),
        Icon(
          Icons.workspace_premium_outlined,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Planos indisponíveis no momento',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Não encontramos opções de assinatura. Volte mais tarde ou contate o suporte.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.72),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
