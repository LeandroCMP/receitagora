import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:receitagora/models/billing_plan.dart';

class BillingPortalPage extends StatefulWidget {
  const BillingPortalPage({super.key});

  @override
  State<BillingPortalPage> createState() => _BillingPortalPageState();
}

class _BillingPortalPageState extends State<BillingPortalPage> {
  late final BillingPortalSession? session;
  WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    session = Get.arguments is BillingPortalSession
        ? Get.arguments as BillingPortalSession
        : null;
    if (session == null) {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back<void>();
        Get.snackbar(
          'Portal indisponível',
          'Não foi possível abrir o portal de assinaturas agora.',
          snackPosition: SnackPosition.BOTTOM,
        );
      });
    } else {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
        )
        ..loadRequest(session!.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar assinatura'),
      ),
      body: Stack(
        children: [
          if (_controller != null)
            WebViewWidget(
              controller: _controller!,
            ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}
