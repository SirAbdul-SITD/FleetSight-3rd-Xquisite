import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const _soundKey = 'bs_sound';
  static const _hapticKey = 'bs_haptic';
  bool _sound = true;
  bool _haptics = true;
  SharedPreferences? _prefs;

  bool get sound => _sound;
  bool get haptics => _haptics;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _sound = _prefs!.getBool(_soundKey) ?? true;
    _haptics = _prefs!.getBool(_hapticKey) ?? true;
    notifyListeners();
  }

  Future<void> setSound(bool v) async {
    _sound = v;
    await _prefs!.setBool(_soundKey, v);
    notifyListeners();
  }

  Future<void> setHaptics(bool v) async {
    _haptics = v;
    await _prefs!.setBool(_hapticKey, v);
    notifyListeners();
  }
}
