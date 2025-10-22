import 'package:flutter/services.dart';

class DeviceTimezone {
  static const MethodChannel _channel =
      MethodChannel('receitagora/device_timezone');

  static Future<String?> getLocalTimezone() async {
    try {
      final timezone = await _channel.invokeMethod<String>('getLocalTimezone');
      if (timezone == null || timezone.isEmpty) {
        return null;
      }
      return timezone;
    } on PlatformException {
      return null;
    }
  }
}
