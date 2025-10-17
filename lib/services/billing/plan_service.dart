import 'dart:async';

import 'package:receitagora/models/subscription_plan.dart';

abstract class PlanService {
  Future<SubscriptionPlan> fetchPlan(String userId);
  Stream<SubscriptionPlan> watchPlan(String userId);
  Future<void> upsertPlan({required String userId, required SubscriptionPlan plan});
  Future<void> clearPlan(String userId);
}
