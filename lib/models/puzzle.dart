class Puzzle {
  final int id;
  final String tier;
  final int n;
  final List<int> fleet; // ship lengths, descending
  final List<int> rowClues;
  final List<int> colClues;
  final List<List<int>> revealed; // 0 = none, 1 = water, 2 = ship
  final List<List<bool>> solution;

  Puzzle({
    required this.id,
    required this.tier,
    required this.n,
    required this.fleet,
    required this.rowClues,
    required this.colClues,
    required this.revealed,
    required this.solution,
  });

  factory Puzzle.fromJson(Map<String, dynamic> j) {
    final n = j['n'] as int;
    final revFlat = (j['revealed'] as List).map((e) => e as int).toList();
    final solFlat = (j['solution'] as List).map((e) => e as int).toList();
    return Puzzle(
      id: j['id'] as int,
      tier: j['tier'] as String,
      n: n,
      fleet: (j['fleet'] as List).map((e) => e as int).toList(),
      rowClues: (j['rowClues'] as List).map((e) => e as int).toList(),
      colClues: (j['colClues'] as List).map((e) => e as int).toList(),
      revealed:
          List.generate(n, (r) => List.generate(n, (c) => revFlat[r * n + c])),
      solution: List.generate(
          n, (r) => List.generate(n, (c) => solFlat[r * n + c] == 1)),
    );
  }
}
