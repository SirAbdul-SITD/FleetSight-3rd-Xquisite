import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/puzzle.dart';

class PuzzleRepository {
  List<Puzzle> _all = [];
  bool _loaded = false;

  List<Puzzle> get all => _all;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/puzzles.json');
    final List<dynamic> list = json.decode(raw) as List<dynamic>;
    _all =
        list.map((e) => Puzzle.fromJson(e as Map<String, dynamic>)).toList();
    _loaded = true;
  }

  List<Puzzle> byTier(String tier) =>
      _all.where((p) => p.tier == tier).toList();
}
