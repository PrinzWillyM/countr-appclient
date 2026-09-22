import 'package:flutter/material.dart';

// --- CHECKOUT HELPER ---
// Findet einen gültigen Ausgang (letzter Pfeil muss ein Doppel oder Bull sein)
// für einen gegebenen Rest-Score, mit möglichst wenigen Pfeilen.
class CheckoutHelper {
  // Alle Pfeil-Werte: Single 1-20, Double 2-40 (gerade), Triple 3-60, Bull 25 (single), Bull 50 (double)
  static final List<_DartValue> _allDarts = _buildDartValues();
  static final List<_DartValue> _doubles = _allDarts.where((d) => d.isDouble).toList();

  static List<_DartValue> _buildDartValues() {
    List<_DartValue> values = [];
    for (int i = 1; i <= 20; i++) {
      values.add(_DartValue(i, "$i", false));
      values.add(_DartValue(i * 2, "D$i", true));
      values.add(_DartValue(i * 3, "T$i", false));
    }
    values.add(_DartValue(25, "25", false));
    values.add(_DartValue(50, "Bull", true));
    // Größte Werte zuerst probieren -> realistischere, kürzere Vorschläge
    values.sort((a, b) => b.value.compareTo(a.value));
    return values;
  }

  /// Gibt eine Liste von Wurf-Labels zurück (z.B. ["T20", "T20", "D20"]),
  /// oder null wenn kein Checkout mit maximal 3 Pfeilen möglich ist.
  static List<String>? suggest(int score) {
    if (score <= 0 || score > 170) return null;
    // Bevorzugt den Checkout mit den wenigsten Pfeilen (1, dann 2, dann 3)
    for (int darts = 1; darts <= 3; darts++) {
      final result = _solve(score, darts);
      if (result != null) return result;
    }
    return null;
  }

  static List<String>? _solve(int score, int dartsLeft) {
    if (dartsLeft == 1) {
      for (final d in _doubles) {
        if (d.value == score) return [d.label];
      }
      return null;
    }
    for (final d in _allDarts) {
      if (d.value >= score) continue;
      final rest = _solve(score - d.value, dartsLeft - 1);
      if (rest != null) return [d.label, ...rest];
    }
    return null;
  }
}

class _DartValue {
  final int value;
  final String label;
  final bool isDouble;
  _DartValue(this.value, this.label, this.isDouble);
}

// --- STATS SHEET ---
// Zeigt 3-Dart-Average, Legs, bester Checkout und geworfene Darts pro Spieler.
class DartsStatsSheet extends StatelessWidget {
  final List<dynamic> players; // erwartet DartPlayer-artige Objekte
  final Color primaryColor;
  final Color surfaceColor;
  final String titleLabel;
  final String avgLabel;
  final String legsLabel;
  final String checkoutLabel;
  final String dartsLabel;

  const DartsStatsSheet({
    super.key,
    required this.players,
    required this.primaryColor,
    required this.surfaceColor,
    this.titleLabel = "STATS",
    this.avgLabel = "AVG (3 DARTS)",
    this.legsLabel = "LEGS",
    this.checkoutLabel = "BEST CHECKOUT",
    this.dartsLabel = "DARTS",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF222629),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: primaryColor, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart, color: primaryColor),
                  const SizedBox(width: 10),
                  Text(titleLabel, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 15),
          ...players.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(15)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statCol(avgLabel, p.average.toStringAsFixed(1)),
                    _statCol(legsLabel, "${p.legsWon}"),
                    _statCol(checkoutLabel, p.bestCheckout > 0 ? "${p.bestCheckout}" : "-"),
                    _statCol(dartsLabel, "${p.dartsThrown}"),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9), textAlign: TextAlign.center),
      ],
    );
  }
}
