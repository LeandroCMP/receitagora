import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:receitagora/models/subscription_plan.dart';

import 'plan_service.dart';

class PlanServiceImpl extends GetxService implements PlanService {
  PlanServiceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const String _collectionPath = 'users';
  static const String _planDocumentId = 'plan';

  DocumentReference<Map<String, dynamic>> _planDoc(String userId) {
    return _firestore
        .collection(_collectionPath)
        .doc(userId)
        .collection('billing')
        .doc(_planDocumentId);
  }

  @override
  Future<SubscriptionPlan> fetchPlan(String userId) async {
    try {
      final snapshot = await _planDoc(userId).get();
      if (!snapshot.exists) {
        return SubscriptionPlan.free();
      }
      final data = snapshot.data();
      if (data == null || data.isEmpty) {
        return SubscriptionPlan.free();
      }
      return SubscriptionPlan.fromMap(data);
    } catch (error, stackTrace) {
      Get.log(
        'Erro ao carregar plano de assinatura: $error\n$stackTrace',
        isError: true,
      );
      return SubscriptionPlan.free();
    }
  }

  @override
  Stream<SubscriptionPlan> watchPlan(String userId) {
    return _planDoc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (snapshot.exists && data != null && data.isNotEmpty) {
        return SubscriptionPlan.fromMap(data);
      }
      return SubscriptionPlan.free();
    });
  }

  @override
  Future<void> upsertPlan({
    required String userId,
    required SubscriptionPlan plan,
  }) async {
    await _planDoc(userId).set(plan.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> clearPlan(String userId) async {
    await _planDoc(userId).delete();
  }
}
