import 'package:flutter/material.dart';

/// Naval-chart theme: deep sea-chart teal, brass grid lines, steel-grey
/// ships -- distinct from every prior game's palette in this catalog.
class Palette {
  static const abyss = Color(0xFF0C1A1D);
  static const panel = Color(0xFF122428);
  static const raised = Color(0xFF1A3339);
  static const board = Color(0xFF0F2226); // water (unknown)
  static const waterMarked = Color(0xFF163A40); // marked water (dot)
  static const shipFill = Color(0xFFB7BEC2); // ship hull grey

  static const foam = Color(0xFFE7F1EE);
  static const brass = Color(0xFFC79A4B);
  static const haze = Color(0xFF7FA3A8);
  static const line = Color(0xFF224448);
  static const coral = Color(0xFFD1685A);
  static const sage = Color(0xFF6FA37B);

  static const tierColors = {
    'easy': Color(0xFF6FA37B),
    'medium': Color(0xFFC79A4B),
    'hard': Color(0xFFD1685A),
  };
}
