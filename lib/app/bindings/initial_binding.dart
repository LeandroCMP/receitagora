import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
        final googleSignIn = GoogleSignIn(scopes: const ['email', 'profile']);
        Get.put<SharedPreferences>(preferences, permanent: true);
        Get.put<GoogleSignIn>(googleSignIn, permanent: true);

        final service = SessionService(
          googleSignIn: googleSignIn,
          preferences: preferences,
        );
        return service.init();
      },
      permanent: true,
    );
  }
}
