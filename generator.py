#!/usr/bin/env python3
"""
Battleship generator with unique-solution verification.

Rules:
- N x N grid. A fleet of ships (straight lines of 1..K cells) is hidden in
  the grid. Ships never touch each other, not even diagonally.
- Clues: a number at the end of each row and column giving the count of
  ship cells in that row/column, plus a handful of individually revealed
  cells (ship or water) to pin down a unique fleet layout.
- A valid puzzle has exactly ONE fleet placement consistent with the fleet
  composition, row/column counts, and revealed cells.

Generation:
1. Place the fleet (largest ships first) via randomized backtracking so no
   two ships are adjacent (incl. diagonally).
2. Derive row/column counts from the solution.
3. Reveal as few individual cells as possible (chosen randomly, added one at
   a time) until the puzzle has exactly one valid fleet placement.
"""

import random
import sys
from collections import deque


def fleet_for_size(N):
    """Return a descending list of ship lengths appropriate for grid size N."""
    if N <= 6:
        return [3, 2, 2, 1, 1, 1]
    if N <= 8:
        return [4, 3, 2, 2, 1, 1, 1]
    if N <= 9:
        return [4, 3, 3, 2, 2, 1, 1, 1]
    return [4, 3, 3, 2, 2, 2, 1, 1, 1, 1]


def neighbors8(r, c, N):
    for dr in (-1, 0, 1):
        for dc in (-1, 0, 1):
            if dr == 0 and dc == 0:
                continue
            nr, nc = r + dr, c + dc
            if 0 <= nr < N and 0 <= nc < N:
                yield nr, nc


def place_fleet(N, fleet, rng, tries=300):
    """Randomized backtracking placement of the fleet, largest ships first,
    with no two ships touching (incl. diagonally). Returns a boolean grid
    (True = ship cell) or None."""
    for _ in range(tries):
        occupied = [[False] * N for _ in range(N)]

        def can_place(r, c, length, horiz):
            cells = []
            for i in range(length):
                rr, cc = (r, c + i) if horiz else (r + i, c)
                if not (0 <= rr < N and 0 <= cc < N):
                    return None
                cells.append((rr, cc))
            for (rr, cc) in cells:
                if occupied[rr][cc]:
                    return None
                for nr, nc in neighbors8(rr, cc, N):
                    if occupied[nr][nc] and (nr, nc) not in cells:
                        return None
            return cells

        def bt(idx):
            if idx == len(fleet):
                return True
            length = fleet[idx]
            positions = []
            for r in range(N):
                for c in range(N):
                    for horiz in (True, False):
                        if length == 1 and not horiz:
                            continue
                        cells = can_place(r, c, length, horiz)
                        if cells:
                            positions.append(cells)
            rng.shuffle(positions)
            for cells in positions:
                for (r, c) in cells:
                    occupied[r][c] = True
                if bt(idx + 1):
                    return True
                for (r, c) in cells:
                    occupied[r][c] = False
            return False

        if bt(0):
            return occupied
    return None


def row_col_counts(occupied, N):
    rows = [sum(1 for c in range(N) if occupied[r][c]) for r in range(N)]
    cols = [sum(1 for r in range(N) if occupied[r][c]) for c in range(N)]
    return rows, cols


def extract_ships(occupied, N):
    """Return list of ships as sorted cell lists, for fleet-composition
    checks."""
    seen = [[False] * N for _ in range(N)]
    ships = []
    for r in range(N):
        for c in range(N):
            if occupied[r][c] and not seen[r][c]:
                # flood fill (ships are straight lines; 4-dir connectivity
                # suffices since diagonal touching between different ships
                # is forbidden)
                comp = []
                dq = deque([(r, c)])
                seen[r][c] = True
                while dq:
                    cr, cc = dq.popleft()
                    comp.append((cr, cc))
                    for nr, nc in ((cr + 1, cc), (cr - 1, cc),
                                   (cr, cc + 1), (cr, cc - 1)):
                        if (0 <= nr < N and 0 <= nc < N and
                                occupied[nr][nc] and not seen[nr][nc]):
                            seen[nr][nc] = True
                            dq.append((nr, nc))
                ships.append(sorted(comp))
    return ships


def count_solutions(N, fleet, row_clues, col_clues, revealed, cap=2,
                     node_limit=300000):
    """Backtracking solver: place ships (by descending length, matching the
    exact fleet composition) into the grid such that row/col counts and
    revealed cell clues (dict (r,c)->bool, True=ship) are all satisfied, and
    no two ships touch. Cap the returned solution count."""
    occupied = [[None] * N for _ in range(N)]  # None unknown, True ship, False water
    for (r, c), val in revealed.items():
        occupied[r][c] = val

    solutions = [0]
    nodes = [0]
    aborted = [False]
    seen_grids = set()

    fleet_sorted = sorted(fleet, reverse=True)

    # incremental counters: ship-cell count and unknown-cell count per
    # row/column, updated as cells are placed/unplaced instead of rescanned
    row_ship = [0] * N
    row_unknown = [0] * N
    col_ship = [0] * N
    col_unknown = [0] * N
    for r in range(N):
        for c in range(N):
            if occupied[r][c] is True:
                row_ship[r] += 1
                col_ship[c] += 1
            elif occupied[r][c] is None:
                row_unknown[r] += 1
                col_unknown[c] += 1

    def fits(r, c, length, horiz):
        cells = []
        for i in range(length):
            rr, cc = (r, c + i) if horiz else (r + i, c)
            if not (0 <= rr < N and 0 <= cc < N):
                return None
            if occupied[rr][cc] is False:
                return None
            cells.append((rr, cc))
        for (rr, cc) in cells:
            for nr, nc in neighbors8(rr, cc, N):
                if (nr, nc) not in cells and occupied[nr][nc] is True:
                    return None
        return cells

    def counts_ok():
        for r in range(N):
            if row_ship[r] > row_clues[r]:
                return False
            if row_ship[r] + row_unknown[r] < row_clues[r]:
                return False
        for c in range(N):
            if col_ship[c] > col_clues[c]:
                return False
            if col_ship[c] + col_unknown[c] < col_clues[c]:
                return False
        return True

    def place_cells(cells):
        for (rr, cc) in cells:
            was_unknown = occupied[rr][cc] is None
            occupied[rr][cc] = True
            if was_unknown:
                row_ship[rr] += 1
                col_ship[cc] += 1
                row_unknown[rr] -= 1
                col_unknown[cc] -= 1

    def unplace_cells(cells, prev):
        for (rr, cc), p in zip(cells, prev):
            if p is None:
                row_ship[rr] -= 1
                col_ship[cc] -= 1
                row_unknown[rr] += 1
                col_unknown[cc] += 1
            occupied[rr][cc] = p

    def bt(idx):
        if solutions[0] >= cap or aborted[0]:
            return
        nodes[0] += 1
        if nodes[0] > node_limit:
            aborted[0] = True
            return
        if idx == len(fleet_sorted):
            # fill remaining unknowns as water, then verify everything
            snapshot = [row[:] for row in occupied]
            for r in range(N):
                for c in range(N):
                    if occupied[r][c] is None:
                        occupied[r][c] = False
            ok = True
            rows, cols = row_col_counts(
                [[occupied[r][c] is True for c in range(N)] for r in range(N)], N)
            if rows != row_clues or cols != col_clues:
                ok = False
            if ok:
                grid_bool = [[occupied[r][c] is True for c in range(N)] for r in range(N)]
                ships = extract_ships(grid_bool, N)
                lens = sorted((len(s) for s in ships), reverse=True)
                if lens != fleet_sorted:
                    ok = False
                if ok:
                    for s in ships:
                        rs = set(x[0] for x in s)
                        cs = set(x[1] for x in s)
                        if len(rs) > 1 and len(cs) > 1:
                            ok = False
                            break
            if ok:
                grid_sig = tuple(
                    tuple(occupied[r][c] is True for c in range(N))
                    for r in range(N))
                if grid_sig not in seen_grids:
                    seen_grids.add(grid_sig)
                    solutions[0] += 1
            occupied[:] = snapshot
            return
        length = fleet_sorted[idx]
        for r in range(N):
            for c in range(N):
                for horiz in (True, False):
                    if length == 1 and not horiz:
                        continue
                    cells = fits(r, c, length, horiz)
                    if not cells:
                        continue
                    prev = [occupied[rr][cc] for (rr, cc) in cells]
                    place_cells(cells)
                    if counts_ok():
                        bt(idx + 1)
                    unplace_cells(cells, prev)
                    if solutions[0] >= cap or aborted[0]:
                        return

    bt(0)
    if aborted[0]:
        return cap + 1
    return solutions[0]


def make_puzzle(N, rng, max_tries=15, time_budget=4.0):
    import time as _time
    start = _time.time()
    fleet = fleet_for_size(N)
    for _ in range(max_tries):
        if _time.time() - start > time_budget:
            return None
        occupied = place_fleet(N, fleet, rng)
        if occupied is None:
            continue
        row_clues, col_clues = row_col_counts(occupied, N)
        all_cells = [(r, c) for r in range(N) for c in range(N)]
        rng.shuffle(all_cells)
        revealed = {}
        n = count_solutions(N, fleet, row_clues, col_clues, revealed, cap=2,
                             node_limit=20000)
        if n == 1:
            return occupied, row_clues, col_clues, revealed, fleet
        batch_size = max(1, N // 3)
        i = 0
        while i < len(all_cells):
            if _time.time() - start > time_budget:
                return None
            batch = all_cells[i:i + batch_size]
            i += batch_size
            for (r, c) in batch:
                revealed[(r, c)] = occupied[r][c]
            n = count_solutions(N, fleet, row_clues, col_clues, revealed,
                                 cap=2, node_limit=20000)
            if n == 1:
                return occupied, row_clues, col_clues, revealed, fleet
    return None


def serialize(N, occupied, row_clues, col_clues, revealed, fleet, pid, tier):
    flat_sol = []
    for r in range(N):
        for c in range(N):
            flat_sol.append(1 if occupied[r][c] else 0)
    flat_revealed = []
    for r in range(N):
        for c in range(N):
            if (r, c) in revealed:
                flat_revealed.append(2 if revealed[(r, c)] else 1)
            else:
                flat_revealed.append(0)
    return {
        "id": pid, "tier": tier, "n": N,
        "fleet": sorted(fleet, reverse=True),
        "rowClues": row_clues, "colClues": col_clues,
        "revealed": flat_revealed,
        "solution": flat_sol,
    }


def main():
    rng = random.Random(20260707)
    tiers = [
        (50, 6, "easy"),
        (50, 8, "medium"),
        (50, 9, "hard"),
    ]
    out = []
    pid = 0
    for cnt, N, tier in tiers:
        made = attempts = 0
        while made < cnt and attempts < cnt * 30:
            attempts += 1
            res = make_puzzle(N, rng, max_tries=15)
            if res is None:
                continue
            occupied, row_clues, col_clues, revealed, fleet = res
            out.append(serialize(N, occupied, row_clues, col_clues, revealed,
                                  fleet, pid, tier))
            pid += 1
            made += 1
            if made % 10 == 0:
                print(f"  {tier} N={N}: {made}/{cnt}", file=sys.stderr)
        print(f"Tier {tier}: {made} ({attempts} attempts)", file=sys.stderr)
    import json
    with open("/home/claude/battleship/puzzles.json", "w") as f:
        json.dump(out, f)
    print(f"TOTAL: {len(out)}", file=sys.stderr)


if __name__ == "__main__":
    main()
