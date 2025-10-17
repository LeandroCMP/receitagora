import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/modules/paywall/paywall_controller.dart';
import 'package:receitagora/services/billing/billing_service.dart';

class PaywallPage extends GetView<PaywallController> {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ReceitaAgora Premium'),
      ),
      body: SafeArea(
        child: Obx(() {
          final isPremium = controller.isPremium.value;
          final isStoreAvailable = controller.isStoreAvailable;
          final products = controller.products;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HeaderHighlight(isPremium: isPremium),
                    const SizedBox(height: 24),
                    if (!isStoreAvailable)
                      _UnavailableStoreNotice(color: surfaces?.high ?? theme.colorScheme.surfaceVariant)
                    else if (products.isEmpty)
                      _LoadingProducts(color: theme.colorScheme.primary),
                    if (isStoreAvailable && products.isNotEmpty) ...[
                      _FeatureComparisonCard(),
                      const SizedBox(height: 24),
                      ...products.map(
                        (product) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _PlanOptionButton(
                            product: product,
                            controller: controller,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed:
                            controller.isBusy ? null : controller.restorePurchases,
                        icon: const Icon(Icons.history_rounded),
                        label: const Text('Restaurar compras'),
                      ),
                    ],
                    const SizedBox(height: 40),
                    _FaqSection(color: surfaces?.low ?? theme.colorScheme.surfaceVariant),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _HeaderHighlight extends StatelessWidget {
  const _HeaderHighlight({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.12),
            colorScheme.primaryContainer.withOpacity(0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPremium ? Icons.emoji_events_rounded : Icons.star_outline_rounded,
            color: colorScheme.primary,
            size: 36,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? 'Você já é Premium' : 'Receitas ilimitadas te esperam',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isPremium
                      ? 'Continue explorando sem limites e aproveite todas as vantagens exclusivas.'
                      : 'Desbloqueie gerações ilimitadas, exportações completas e suporte prioritário para transformar sua cozinha.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureComparisonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    final features = <_FeatureRowData>[
      const _FeatureRowData(
        title: 'Geração de receitas',
        freeValue: '30/mês',
        premiumValue: 'Ilimitado',
      ),
      const _FeatureRowData(
        title: 'Compartilhamentos',
        freeValue: '10/mês',
        premiumValue: 'Ilimitado',
      ),
      const _FeatureRowData(
        title: 'Histórico',
        freeValue: '1 mês',
        premiumValue: '12 meses',
      ),
      const _FeatureRowData(
        title: 'Preferências personalizadas',
        freeValue: '3 combinações',
        premiumValue: 'Sem limites',
      ),
      const _FeatureRowData(
        title: 'Suporte',
        freeValue: 'FAQ e e-mail',
        premiumValue: 'Prioritário',
      ),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: surfaces?.medium ?? theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Compare os planos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            for (final feature in features) ...[
              _FeatureRow(feature: feature),
              const Divider(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureRowData {
  const _FeatureRowData({
    required this.title,
    required this.freeValue,
    required this.premiumValue,
  });

  final String title;
  final String freeValue;
  final String premiumValue;
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});

  final _FeatureRowData feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            feature.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            feature.freeValue,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            feature.premiumValue,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _PlanOptionButton extends StatelessWidget {
  const _PlanOptionButton({
    required this.product,
    required this.controller,
  });

  final BillingProduct product;
  final PaywallController controller;

  String _planLabel() {
    switch (product.type) {
      case BillingProductType.premiumMonthly:
        return 'Plano Mensal';
      case BillingProductType.premiumAnnual:
        return 'Plano Anual';
    }
  }

  String _billingCycle() {
    switch (product.type) {
      case BillingProductType.premiumMonthly:
        return 'cobrado mensalmente';
      case BillingProductType.premiumAnnual:
        return 'cobrado anualmente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final isBusy = controller.isBusy;
      final isPremium = controller.isPremium.value;
      return ElevatedButton(
        onPressed: isBusy || isPremium
            ? null
            : () => controller.buyProduct(product.type),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _planLabel(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _billingCycle(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  controller.formatPrice(product.details),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                if (isBusy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _UnavailableStoreNotice extends StatelessWidget {
  const _UnavailableStoreNotice({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.store_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'A loja de assinaturas não está disponível no momento. Verifique sua conexão ou tente novamente mais tarde.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingProducts extends StatelessWidget {
  const _LoadingProducts({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(color: color),
          ),
          const SizedBox(height: 12),
          Text(
            'Carregando planos disponíveis...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  const _FaqSection({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final faqs = <Map<String, String>>[
      {
        'question': 'Posso cancelar quando quiser?',
        'answer':
            'Sim! Você pode cancelar direto pela loja do seu dispositivo e continua com acesso premium até o fim do período pago.',
      },
      {
        'question': 'O que acontece com minhas receitas salvas?',
        'answer':
            'Nada muda. Suas receitas, histórico e preferências continuam salvos mesmo se você cancelar a assinatura.',
      },
      {
        'question': 'Consigo usar o premium em mais de um dispositivo?',
        'answer':
            'Sim, basta utilizar a mesma conta em todos os dispositivos e restaurar as compras quando necessário.',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perguntas frequentes',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          for (final faq in faqs) ...[
            Text(
              faq['question'] ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              faq['answer'] ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}
