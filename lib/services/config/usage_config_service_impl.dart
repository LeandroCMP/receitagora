import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
    } catch (error, stackTrace) {
      Get.log(
        'Falha ao carregar configuração de uso: $error\n$stackTrace',
        isError: true,
      );
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

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

}
