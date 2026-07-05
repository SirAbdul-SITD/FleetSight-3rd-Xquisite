import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/palette.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import '../services/audio_manager.dart';

class SettingsScreen extends StatelessWidget {
  final AudioManager audio;
  const SettingsScreen({super.key, required this.audio});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    return Scaffold(
      backgroundColor: Palette.abyss,
      appBar: AppBar(
        backgroundColor: Palette.abyss,
        elevation: 0,
        foregroundColor: Palette.foam,
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Sound',
                        style: TextStyle(color: Palette.foam)),
                    value: settings.sound,
                    activeColor: Palette.brass,
                    onChanged: (v) {
                      settings.setSound(v);
                      if (v) {
                        audio.startMusic();
                      } else {
                        audio.stopMusic();
                      }
                    },
                  ),
                  const Divider(color: Palette.line, height: 1),
                  SwitchListTile(
                    title: const Text('Haptics',
                        style: TextStyle(color: Palette.foam)),
                    value: settings.haptics,
                    activeColor: Palette.brass,
                    onChanged: settings.setHaptics,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _card(
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How to play',
                        style: TextStyle(
                            color: Palette.foam,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 12),
                    Text(
                      'A hidden fleet of straight-line ships is somewhere in '
                      'the grid. The number beside each row and above each '
                      'column tells you how many ship cells are in that '
                      'line.\n\n'
                      'Ships never touch — not even diagonally. A few cells '
                      'are already revealed as ship or water to get you '
                      'started.\n\n'
                      'Tap a cell to cycle it: ship, then a small dot '
                      '(marking it as definitely water), then blank again. '
                      'Touching ships or a row/column with too many ship '
                      'cells are flagged in red.\n\n'
                      'Every puzzle has exactly one fleet layout, reachable '
                      'by pure deduction.',
                      style: TextStyle(
                          color: Palette.haze, fontSize: 13.5, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _card(
              child: ListTile(
                title: const Text('Reset all progress',
                    style: TextStyle(color: Palette.coral)),
                trailing:
                    const Icon(Icons.delete_outline, color: Palette.coral),
                onTap: () => _confirmReset(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Palette.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Palette.line),
        ),
        child: child,
      );

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Palette.panel,
        title: const Text('Reset progress?',
            style: TextStyle(color: Palette.foam)),
        content: const Text('This clears all stars and solved levels.',
            style: TextStyle(color: Palette.haze)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Palette.haze)),
          ),
          TextButton(
            onPressed: () {
              context.read<ProgressService>().reset();
              Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: Palette.coral)),
          ),
        ],
      ),
    );
  }
}
