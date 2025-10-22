import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:receitagora/services/config/usage_config.dart';
import 'package:receitagora/services/config/usage_config_service.dart';

class UsageConfigServiceImpl extends GetxService implements UsageConfigService {
  UsageConfigServiceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore,
        _readyCompleter = Completer<void>(),
        _config = UsageConfig.defaults.obs;

  final FirebaseFirestore _firestore;
  final Completer<void> _readyCompleter;
  final Rx<UsageConfig> _config;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _subscription;
  bool _isInitializing = false;

  static const String _documentPath = 'config/app_usage';

  @override
  Future<void> get ready => _readyCompleter.future;

  @override
  UsageConfig get current => _config.value;

  @override
  Stream<UsageConfig> get stream => _config.stream;

  @override
  Future<void> ensureInitialized() async {
    if (_readyCompleter.isCompleted) {
      return;
    }

    if (_isInitializing) {
      await ready;
      return;
    }

    _isInitializing = true;

    try {
      await _loadInitialConfig();
      _listenForUpdates();
    } finally {
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
      _isInitializing = false;
    }
  }

  Future<void> _loadInitialConfig() async {
    try {
      final snapshot = await _firestore.doc(_documentPath).get();
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          _config.value = UsageConfig.fromMap(data, _config.value);
        }
      }
    } on FirebaseException catch (error, stackTrace) {
      await _loadFallbackConfig(error, stackTrace);
    } catch (error, stackTrace) {
      await _loadFallbackConfig(error, stackTrace);
    }
  }

  void _listenForUpdates() {
    _subscription ??=
        _firestore.doc(_documentPath).snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data != null) {
        _config.value = UsageConfig.fromMap(data, _config.value);
      }
    }, onError: (Object error, StackTrace stackTrace) {
      Get.log(
        'Erro ao escutar configuração de uso: $error\n$stackTrace',
        isError: true,
      );
    });
  }

  Future<void> _loadFallbackConfig(
    Object error,
    StackTrace stackTrace,
  ) async {
    Get.log(
      'Falha ao carregar configuração de uso no Firestore: $error\n$stackTrace',
      isError: true,
    );

    try {
      final payload = await rootBundle.loadString(_fallbackAssetPath);
      final Map<String, dynamic> data =
          jsonDecode(payload) as Map<String, dynamic>;
      _config.value = UsageConfig.fromMap(data, _config.value);
      Get.log(
        'Aplicando configuração de uso a partir do fallback local ($_fallbackAssetPath).',
      );
    } catch (assetError, assetStackTrace) {
      Get.log(
        'Falha ao carregar configuração de uso local: $assetError\n$assetStackTrace',
        isError: true,
      );
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

}

const String _fallbackAssetPath = 'assets/config/app_usage.json';
