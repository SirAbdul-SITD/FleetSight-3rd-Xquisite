# Fleetsight

A ship-placement logic puzzle for Android (Flutter), based on Battleship.
Find the one true fleet.

## Run

```bash
cd fleetsight
flutter create .
flutter pub get
flutter run
```

## The puzzle

A fleet of straight-line ships (lengths vary by grid size — shown at the
top of each puzzle) is hidden in the grid. Numbers beside each row and
above each column give the ship-cell count for that line. Ships never
touch, not even diagonally. A handful of cells start revealed as ship or
water.

**Tap** a cell to cycle it: blank → ship → water-dot → blank. Fixed
(pre-revealed) cells can't be changed. Touching ships or a row/column with
too many ship cells are flagged in red live.

## Why every level is solvable — and two real bugs caught along the way

Battleship's solution space is large (many ways to arrange a fleet), so
row/column counts alone almost never pin down a unique layout.
`generator.py` places the fleet first (largest ships placed via randomized
backtracking, no two touching), derives row/column counts, then reveals
individual cells — a handful at a time — until a solver confirms exactly
one valid fleet placement remains.

Two genuine bugs surfaced while building this generator, both caught by
independently re-verifying every puzzle rather than trusting the
generator's own uniqueness check:

1. **Overcounting duplicate-length ships.** The solver placed the fleet's
   ships in a fixed order, but a fleet with multiple ships of the same
   length (e.g. three length-1 submarines) can reach the *identical final
   board* through different assignment orders. Early on this made a fully
   revealed grid — which has exactly one valid state by definition — count
   as 2–3 "solutions." Fixed by deduplicating on the final board state, not
   the placement sequence.
2. **Double-counting ship cells.** After optimizing the solver to use
   incremental row/column counters (needed for speed — the naive version
   took ~9 seconds per check at 9×9), a related bug crept in: placing a ship
   over a cell that was already revealed as a ship incremented that row's
   count a second time. Fixed by only adjusting counts on a genuine
   unknown-to-ship transition.

Both were caught by testing the invariant "a fully revealed grid must always
count as exactly one solution" — which is a fast, decisive sanity check
worth keeping for any future counting-based solver.

All 150 shipped boards were independently re-verified for structure (fleet
composition, straight-line ship shapes, no touching, revealed cells
consistent with the solution, row/column counts correct) and uniqueness
before bundling.

## Project layout

```
lib/
  main.dart
  models/puzzle.dart
  services/        palette, puzzle_repository, progress, settings, audio
  painters/board_painter.dart      # grid + border row/col clues, ship hulls
  screens/         home, level_select, game, settings
assets/
  data/puzzles.json                # 150 verified puzzles
  audio/                           # procedural SFX + ambient track
screens/                           # Play Store screenshots (1080x1920)
generator.py                       # reference generator/solver
```

## Notes

- State persists locally via `shared_preferences`. No network, no accounts.
- Audio is procedurally generated WAV; the ambient track is intentionally
  large so the release build comfortably exceeds typical minimum size
  requirements.
