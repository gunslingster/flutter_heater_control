import 'package:shared_preferences/shared_preferences.dart';

Future<void> setCustomDeviceName(String deviceId, String customName) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString(deviceId, customName);
}

Future<String?> getCustomDeviceName(String deviceId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(deviceId);
}
