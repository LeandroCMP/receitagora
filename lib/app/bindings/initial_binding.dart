import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/environment_config.dart';
import '../../core/services/openai_service.dart';
import '../../core/services/session_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<EnvironmentConfig>(EnvironmentConfig.fromEnv(), permanent: true);
    Get.lazyPut<http.Client>(() => http.Client(), fenix: true);
    Get.lazyPut<OpenAIService>(
      () => OpenAIService(
        client: Get.find<http.Client>(),
        config: Get.find<EnvironmentConfig>(),
      ),
      fenix: true,
    );
    Get.putAsync<SessionService>(
      () async {
        final preferences = await SharedPreferences.getInstance();
        Get.put<SharedPreferences>(preferences, permanent: true);

        final service = SessionService(
          preferences: preferences,
        );
        return service.init();
      },
      permanent: true,
    );
  }
}
