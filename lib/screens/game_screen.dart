import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/puzzle.dart';
import '../painters/board_painter.dart';
import '../services/palette.dart';
import '../services/progress_service.dart';
import '../services/settings_service.dart';
import '../services/audio_manager.dart';

class GameScreen extends StatefulWidget {
  final Puzzle puzzle;
  final AudioManager audio;
  final VoidCallback? onNext;
  const GameScreen({
    super.key,
    required this.puzzle,
    required this.audio,
    this.onNext,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<List<int>> state; // 0 unknown, 1 ship, 2 water-dot
  bool won = false;
  int moves = 0;

  int get _n => widget.puzzle.n;

  @override
  void initState() {
    super.initState();
    final p = widget.puzzle;
    state = List.generate(_n, (r) => List.generate(_n, (c) {
          final rv = p.revealed[r][c];
          if (rv == 1) return 2; // pre-revealed water
          if (rv == 2) return 1; // pre-revealed ship
          return 0;
        }));
  }

  void _haptic() {
    if (context.read<SettingsService>().haptics) {
      HapticFeedback.selectionClick();
    }
  }

  void _onTap(int r, int c) {
    if (won) return;
    if (widget.puzzle.revealed[r][c] != 0) return; // fixed cells can't change
    setState(() {
      state[r][c] = (state[r][c] + 1) % 3;
      moves++;
    });
    final v = state[r][c];
    if (v == 1) {
      widget.audio.hit();
    } else if (v == 2) {
      widget.audio.splash();
    } else {
      widget.audio.clear();
    }
    _haptic();
    _checkWin();
  }

  bool _isShip(int r, int c) => state[r][c] == 1;

  Set<String> _conflicts() {
    final out = <String>{};
    final n = _n;
    // touching-ship conflicts (any two ship cells adjacent incl. diagonally
    // that don't belong to the same straight run count as a conflict only
    // if they represent genuinely different ships -- simplified: any
    // diagonal-adjacency between ship cells not sharing a row/col run)
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (!_isShip(r, c)) continue;
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            if (dr == 0 && dc == 0) continue;
            final nr = r + dr, nc = c + dc;
            if (nr < 0 || nr >= n || nc < 0 || nc >= n) continue;
            if (!_isShip(nr, nc)) continue;
            final sameRow = dr == 0;
            final sameCol = dc == 0;
            if (!sameRow && !sameCol) {
              // diagonal adjacency between two ship cells is always invalid
              out.add('$r,$c');
              out.add('$nr,$nc');
            }
          }
        }
      }
    }
    // row/col overflow
    for (int r = 0; r < n; r++) {
      int cnt = 0;
      for (int c = 0; c < n; c++) {
        if (_isShip(r, c)) cnt++;
      }
      if (cnt > widget.puzzle.rowClues[r]) {
        for (int c = 0; c < n; c++) {
          if (_isShip(r, c)) out.add('$r,$c');
        }
      }
    }
    for (int c = 0; c < n; c++) {
      int cnt = 0;
      for (int r = 0; r < n; r++) {
        if (_isShip(r, c)) cnt++;
      }
      if (cnt > widget.puzzle.colClues[c]) {
        for (int r = 0; r < n; r++) {
          if (_isShip(r, c)) out.add('$r,$c');
        }
      }
    }
    return out;
  }

  List<List<List<int>>> _extractShips() {
    final n = _n;
    final seen = List.generate(n, (_) => List.filled(n, false));
    final ships = <List<List<int>>>[];
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (_isShip(r, c) && !seen[r][c]) {
          final comp = <List<int>>[];
          final queue = <List<int>>[
            [r, c]
          ];
          seen[r][c] = true;
          while (queue.isNotEmpty) {
            final cur = queue.removeLast();
            comp.add(cur);
            for (final d in [
              [1, 0],
              [-1, 0],
              [0, 1],
              [0, -1]
            ]) {
              final nr = cur[0] + d[0], nc = cur[1] + d[1];
              if (nr >= 0 &&
                  nr < n &&
                  nc >= 0 &&
                  nc < n &&
                  _isShip(nr, nc) &&
                  !seen[nr][nc]) {
                seen[nr][nc] = true;
                queue.add([nr, nc]);
              }
            }
          }
          ships.add(comp);
        }
      }
    }
    return ships;
  }

  void _checkWin() {
    final p = widget.puzzle;
    final n = _n;
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (state[r][c] == 0) return; // must be fully decided
      }
    }
    if (_conflicts().isNotEmpty) return;
    // row/col counts must match exactly
    for (int r = 0; r < n; r++) {
      int cnt = 0;
      for (int c = 0; c < n; c++) {
        if (_isShip(r, c)) cnt++;
      }
      if (cnt != p.rowClues[r]) return;
    }
    for (int c = 0; c < n; c++) {
      int cnt = 0;
      for (int r = 0; r < n; r++) {
        if (_isShip(r, c)) cnt++;
      }
      if (cnt != p.colClues[c]) return;
    }
    // fleet composition must match exactly, ships must be straight lines
    final ships = _extractShips();
    final lens = ships.map((s) => s.length).toList()..sort((a, b) => b - a);
    final fleet = List<int>.from(p.fleet)..sort((a, b) => b - a);
    if (lens.length != fleet.length) return;
    for (int i = 0; i < lens.length; i++) {
      if (lens[i] != fleet[i]) return;
    }
    for (final s in ships) {
      final rows = s.map((e) => e[0]).toSet();
      final cols = s.map((e) => e[1]).toSet();
      if (rows.length > 1 && cols.length > 1) return; // not a straight line
    }
    won = true;
    widget.audio.win();
    final stars = _starRating();
    context.read<ProgressService>().recordWin(p.id, stars);
    Future.delayed(const Duration(milliseconds: 300), _showWinSheet);
  }

  int _starRating() {
    final cells = _n * _n;
    if (moves <= cells) return 3;
    if (moves <= (cells * 1.4).round()) return 2;
    return 1;
  }

  void _showWinSheet() {
    final stars = _starRating();
    showModalBottomSheet(
      context: context,
      backgroundColor: Palette.panel,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Fleet Located',
                style: TextStyle(
                    color: Palette.foam,
                    fontSize: 24,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    color: i < stars ? Palette.brass : Palette.haze,
                    size: 44,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Solved in $moves taps',
                style: const TextStyle(color: Palette.haze, fontSize: 14)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Palette.foam,
                      side: const BorderSide(color: Palette.line),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Levels'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.brass,
                      foregroundColor: Palette.abyss,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      widget.onNext?.call();
                    },
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      final p = widget.puzzle;
      state = List.generate(_n, (r) => List.generate(_n, (c) {
            final rv = p.revealed[r][c];
            if (rv == 1) return 2;
            if (rv == 2) return 1;
            return 0;
          }));
      moves = 0;
      won = false;
    });
    widget.audio.tap();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.puzzle;
    final conflicts = _conflicts();
    final fleetDesc = p.fleet.join(', ');
    return Scaffold(
      backgroundColor: Palette.abyss,
      appBar: AppBar(
        backgroundColor: Palette.abyss,
        elevation: 0,
        foregroundColor: Palette.foam,
        title: Text('Level ${p.id + 1}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reset),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Tap to place the fleet ($fleetDesc). Row and column numbers '
                'give ship-cell counts. Ships never touch, even diagonally.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Palette.haze.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    height: 1.4),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Center(
                child: LayoutBuilder(builder: (context, cons) {
                  final side = (cons.maxWidth < cons.maxHeight
                          ? cons.maxWidth
                          : cons.maxHeight) -
                      24;
                  final clueBand = side * 0.09;
                  final boardSize = side - clueBand;
                  final cell = boardSize / _n;
                  return GestureDetector(
                    onTapUp: (d) {
                      final x = d.localPosition.dx - clueBand;
                      final y = d.localPosition.dy - clueBand;
                      if (x < 0 || y < 0 || x > boardSize || y > boardSize) {
                        return;
                      }
                      final c = (x / cell).floor().clamp(0, _n - 1);
                      final r = (y / cell).floor().clamp(0, _n - 1);
                      _onTap(r, c);
                    },
                    child: CustomPaint(
                      size: Size(side, side),
                      painter: BoardPainter(
                        puzzle: p,
                        state: state,
                        conflicts: conflicts,
                        clueBand: clueBand,
                      ),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Taps: $moves',
                      style:
                          const TextStyle(color: Palette.haze, fontSize: 14)),
                  Text(p.tier.toUpperCase(),
                      style: TextStyle(
                          color: Palette.tierColors[p.tier],
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
