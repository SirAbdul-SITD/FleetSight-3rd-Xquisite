import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/puzzle.dart';
import '../services/palette.dart';
import '../services/puzzle_repository.dart';
import '../services/progress_service.dart';
import '../services/audio_manager.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatelessWidget {
  final String tier;
  final String tierName;
  final PuzzleRepository repo;
  final AudioManager audio;
  const LevelSelectScreen({
    super.key,
    required this.tier,
    required this.tierName,
    required this.repo,
    required this.audio,
  });

  void _openLevel(BuildContext context, List<Puzzle> levels, int index) {
    audio.tap();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          puzzle: levels[index],
          audio: audio,
          onNext: index + 1 < levels.length
              ? () => _openLevel(context, levels, index + 1)
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressService>();
    final levels = repo.byTier(tier);
    final accent = Palette.tierColors[tier]!;
    return Scaffold(
      backgroundColor: Palette.abyss,
      appBar: AppBar(
        backgroundColor: Palette.abyss,
        elevation: 0,
        foregroundColor: Palette.foam,
        title: Text(tierName,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: levels.length,
            itemBuilder: (context, i) {
              final p = levels[i];
              final stars = progress.starsFor(p.id);
              final solved = progress.isSolved(p.id);
              return GestureDetector(
                onTap: () => _openLevel(context, levels, i),
                child: Container(
                  decoration: BoxDecoration(
                    color: solved ? Palette.raised : Palette.panel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: solved
                          ? accent.withValues(alpha: 0.6)
                          : Palette.line,
                      width: 1.3,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${i + 1}',
                          style: TextStyle(
                              color: solved ? Palette.foam : Palette.haze,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (s) => Icon(
                            Icons.star,
                            size: 9,
                            color: s < stars ? accent : Palette.line,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
