import 'package:receitagora/models/billing_plan.dart';

class BillingResult {
  const BillingResult({
    required this.completed,
    this.subscriptionId,
    this.message,
  });

  final bool completed;
  final String? subscriptionId;
  final String? message;
}

abstract class BillingService {
  Future<void> ensureInitialized();
  Future<List<BillingPlan>> fetchPlans();
  Future<BillingResult> subscribe(BillingPlan plan);
  Future<BillingPortalSession> createPortalSession();
  Future<void> cancelSubscription(String subscriptionId);
}
