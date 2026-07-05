import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressService extends ChangeNotifier {
  static const _starsKey = 'bs_stars_v1';
  final Map<int, int> _stars = {}; // puzzleId -> stars (1..3)
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getStringList(_starsKey) ?? [];
    for (final entry in raw) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        _stars[int.parse(parts[0])] = int.parse(parts[1]);
      }
    }
    notifyListeners();
  }

  int starsFor(int id) => _stars[id] ?? 0;
  bool isSolved(int id) => _stars.containsKey(id);

  Future<void> recordWin(int id, int stars) async {
    final prev = _stars[id] ?? 0;
    if (stars > prev) {
      _stars[id] = stars;
      await _save();
      notifyListeners();
    }
  }

  int tierStars(List<int> ids) =>
      ids.fold(0, (sum, id) => sum + starsFor(id));

  int tierSolved(List<int> ids) =>
      ids.where((id) => isSolved(id)).length;

  Future<void> _save() async {
    final list = _stars.entries.map((e) => '${e.key}:${e.value}').toList();
    await _prefs!.setStringList(_starsKey, list);
  }

  Future<void> reset() async {
    _stars.clear();
    await _prefs!.remove(_starsKey);
    notifyListeners();
  }
}
