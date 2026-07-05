import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/palette.dart';
import '../services/puzzle_repository.dart';
import '../services/progress_service.dart';
import '../services/audio_manager.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final PuzzleRepository repo;
  final AudioManager audio;
  const HomeScreen({super.key, required this.repo, required this.audio});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressService>();
    final tiers = [
      ('easy', 'Coastal Waters', '6×6'),
      ('medium', 'Open Sea', '8×8'),
      ('hard', 'Deep Ocean', '9×9'),
    ];
    return Scaffold(
      backgroundColor: Palette.abyss,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Palette.haze),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SettingsScreen(audio: audio)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Palette.brass, width: 2),
                      color: Palette.raised,
                    ),
                    child: const Icon(Icons.directions_boat,
                        color: Palette.brass, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('FLEETSIGHT',
                          style: TextStyle(
                              color: Palette.foam,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5)),
                      Text('find the one true fleet',
                          style:
                              TextStyle(color: Palette.haze, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('CHOOSE A CHART',
                  style: TextStyle(
                      color: Palette.haze.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2)),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: tiers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final (tier, name, dim) = tiers[i];
                    final ids = repo.byTier(tier).map((p) => p.id).toList();
                    final solved = progress.tierSolved(ids);
                    final stars = progress.tierStars(ids);
                    final accent = Palette.tierColors[tier]!;
                    return _TierCard(
                      name: name,
                      dim: dim,
                      accent: accent,
                      solved: solved,
                      total: ids.length,
                      stars: stars,
                      onTap: () {
                        audio.tap();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LevelSelectScreen(
                              tier: tier,
                              tierName: name,
                              repo: repo,
                              audio: audio,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  final String name, dim;
  final Color accent;
  final int solved, total, stars;
  final VoidCallback onTap;
  const _TierCard({
    required this.name,
    required this.dim,
    required this.accent,
    required this.solved,
    required this.total,
    required this.stars,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : solved / total;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Palette.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.waves, color: accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Palette.foam,
                              fontSize: 19,
                              fontWeight: FontWeight.w700)),
                      Text('$dim grid · $total puzzles',
                          style: const TextStyle(
                              color: Palette.haze, fontSize: 12.5)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: accent, size: 16),
                    const SizedBox(width: 4),
                    Text('$stars',
                        style: TextStyle(
                            color: accent, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: Palette.raised,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
            const SizedBox(height: 8),
            Text('$solved / $total solved',
                style: const TextStyle(color: Palette.haze, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}
