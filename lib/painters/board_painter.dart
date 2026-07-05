import 'package:flutter/material.dart';
import '../models/puzzle.dart';
import '../services/palette.dart';

/// Cell state: 0 = unknown, 1 = ship, 2 = marked water (dot)
class BoardPainter extends CustomPainter {
  final Puzzle puzzle;
  final List<List<int>> state;
  final Set<String> conflicts;
  final double clueBand;

  BoardPainter({
    required this.puzzle,
    required this.state,
    required this.conflicts,
    required this.clueBand,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = puzzle.n;
    final boardSize = size.width - clueBand;
    final cell = boardSize / n;
    final ox = clueBand, oy = clueBand;

    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.abyss);

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final rect = Rect.fromLTWH(ox + c * cell, oy + r * cell, cell, cell);
        final revealedVal = puzzle.revealed[r][c]; // 0 none,1 water,2 ship
        final isFixed = revealedVal != 0;
        final s = state[r][c];
        final isConf = conflicts.contains('$r,$c');
        Color fill;
        if (isConf) {
          fill = Palette.coral.withValues(alpha: 0.4);
        } else if (isFixed) {
          fill = Palette.raised;
        } else if (s == 2) {
          fill = Palette.waterMarked;
        } else {
          fill = Palette.board;
        }
        canvas.drawRect(rect, Paint()..color = fill);

        final displayVal = isFixed ? (revealedVal == 2 ? 1 : 2) : s;
        if (displayVal == 1) {
          canvas.drawRect(
              rect.deflate(cell * 0.14),
              Paint()
                ..color = Palette.shipFill
                ..style = PaintingStyle.fill);
        } else if (displayVal == 2) {
          canvas.drawCircle(rect.center, cell * 0.07,
              Paint()..color = Palette.haze.withValues(alpha: 0.7));
        }
        if (isFixed) {
          canvas.drawRect(
              rect.deflate(1.5),
              Paint()
                ..color = Palette.brass.withValues(alpha: 0.6)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.6);
        }
      }
    }

    final gridPaint = Paint()
      ..color = Palette.line
      ..strokeWidth = 1;
    for (int r = 0; r <= n; r++) {
      canvas.drawLine(Offset(ox, oy + r * cell),
          Offset(ox + boardSize, oy + r * cell), gridPaint);
    }
    for (int c = 0; c <= n; c++) {
      canvas.drawLine(Offset(ox + c * cell, oy),
          Offset(ox + c * cell, oy + boardSize), gridPaint);
    }
    canvas.drawRect(
        Rect.fromLTWH(ox, oy, boardSize, boardSize),
        Paint()
          ..color = Palette.haze.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2);

    // row/col clues (top row, left column)
    for (int c = 0; c < n; c++) {
      _drawClue(canvas, puzzle.colClues[c],
          Offset(ox + (c + 0.5) * cell, clueBand / 2));
    }
    for (int r = 0; r < n; r++) {
      _drawClue(
          canvas, puzzle.rowClues[r], Offset(clueBand / 2, oy + (r + 0.5) * cell));
    }
  }

  void _drawClue(Canvas canvas, int val, Offset center) {
    final tp = TextPainter(
      text: TextSpan(
          text: '$val',
          style: TextStyle(
              color: Palette.brass,
              fontSize: clueBand * 0.42,
              fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.state != state || old.conflicts != conflicts || old.puzzle != puzzle;
}
