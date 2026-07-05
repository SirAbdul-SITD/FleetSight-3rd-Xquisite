import 'package:audioplayers/audioplayers.dart';
import 'settings_service.dart';

class AudioManager {
  final SettingsService settings;
  final AudioPlayer _sfx = AudioPlayer(playerId: 'bs_sfx');
  final AudioPlayer _music = AudioPlayer(playerId: 'bs_music');
  bool _musicStarted = false;

  AudioManager(this.settings);

  Future<void> _play(String asset) async {
    if (!settings.sound) return;
    try {
      await _sfx.stop();
      await _sfx.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> hit() => _play('audio/hit.wav');
  Future<void> splash() => _play('audio/splash.wav');
  Future<void> clear() => _play('audio/clear.wav');
  Future<void> win() => _play('audio/win.wav');
  Future<void> tap() => _play('audio/tap.wav');

  Future<void> startMusic() async {
    if (!settings.sound) return;
    if (_musicStarted) return;
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.play(AssetSource('audio/ambient.wav'), volume: 0.4);
      _musicStarted = true;
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    try {
      await _music.stop();
      _musicStarted = false;
    } catch (_) {}
  }

  void dispose() {
    _sfx.dispose();
    _music.dispose();
  }
}
