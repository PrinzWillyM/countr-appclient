import 'dart:math';
import 'package:flutter/material.dart';
import 'mtg_model.dart';

// Sitzrichtung einer Kachel als Vierteldrehungen (RotatedBox.quarterTurns):
// 0 = unten (liest normal), 2 = oben (Kopf der Tafel gegenüber),
// 1 = sitzt an der linken Handy-Kante, 3 = sitzt an der rechten Handy-Kante.
const int kSeatBottom = 0;
const int kSeatLeft = 1;
const int kSeatTop = 2;
const int kSeatRight = 3;

class MtgLayout {
  /// Zeilen von oben nach unten, jede Zeile = Sitzrichtungen von links nach rechts.
  /// Spieler werden in Lesereihenfolge (Zeile für Zeile) auf die Plätze verteilt.
  final List<List<int>> rows;

  const MtgLayout(this.rows);

  int get seatCount => rows.fold(0, (sum, r) => sum + r.length);

  /// Spielerindizes im Uhrzeigersinn um den Tisch, beginnend oben. Die Spielerindizes selbst
  /// laufen in Lesereihenfolge; für den Zug-Timer braucht es aber die Sitzreihenfolge.
  List<int> get clockwiseOrder {
    final totalFlex = rows.fold(0, (sum, r) => sum + flexOf(r));
    final seats = <(int, double)>[];
    var index = 0;
    var top = 0.0;
    for (final row in rows) {
      final height = flexOf(row) / totalFlex;
      for (var c = 0; c < row.length; c++) {
        final x = (c + 0.5) / row.length - 0.5;
        final y = top + height / 2 - 0.5;
        // atan2 mit y nach unten = Uhrzeigersinn auf dem Bildschirm; bei "oben" (-90°) beginnen
        var angle = atan2(y, x) + pi / 2;
        if (angle < -1e-9) angle += 2 * pi;
        seats.add((index++, angle));
      }
      top += height;
    }
    seats.sort((a, b) => a.$2.compareTo(b.$2));
    return [for (final s in seats) s.$1];
  }

  // --- Position des Menü-Knopfs ---
  // Der Knopf sitzt auf der Kachelgrenze, die der Bildschirmmitte am nächsten liegt (nie mitten
  // auf einer Lebensanzeige). Die Kacheln bekommen seine Lage in ihrem eigenen Blickwinkel
  // und räumen die Stelle frei.

  /// Kandidaten auf den Kachelgrenzen: (normalisierte Position, Pixel-Position).
  List<(Offset, Offset)> _anchorCandidates(Size size, double gap) {
    final totalFlex = rows.fold(0, (sum, r) => sum + flexOf(r));
    final available = size.height - gap * (rows.length - 1);
    final candidates = <(Offset, Offset)>[];
    var top = 0.0, topPx = 0.0;
    for (var r = 0; r < rows.length; r++) {
      final h = flexOf(rows[r]) / totalFlex;
      final hPx = available * h;
      final n = rows[r].length;
      final cellW = (size.width - gap * (n - 1)) / n;
      // senkrechte Grenzen innerhalb der Zeile, auf Höhe der Mitte (soweit die Zeile reicht)
      for (var c = 1; c < n; c++) {
        final y = 0.5.clamp(top, top + h);
        final yPx = (size.height / 2).clamp(topPx, topPx + hPx);
        candidates.add((Offset(c / n, y), Offset(c * cellW + (c - 0.5) * gap, yPx)));
      }
      // waagrechte Grenze unter der Zeile
      if (r < rows.length - 1) {
        candidates.add((Offset(0.5, top + h), Offset(size.width / 2, topPx + hPx + gap / 2)));
      }
      top += h;
      topPx += hPx + gap;
    }
    if (candidates.isEmpty) candidates.add((const Offset(0.5, 0.5), Offset(size.width / 2, size.height / 2)));
    // Bei gleichem Abstand (z. B. Kreuzung im 2×2-Raster) entscheidet die echte Pixel-Nähe zur Mitte
    final centerPx = Offset(size.width / 2, size.height / 2);
    double score((Offset, Offset) c) => (c.$1 - const Offset(0.5, 0.5)).distance * 1e6 + (c.$2 - centerPx).distance * 1e-6;

    candidates.sort((a, b) => score(a).compareTo(score(b)));
    return candidates;
  }

  /// Menü-Knopf in normalisierten Bildschirmkoordinaten (0..1).
  Offset get menuAnchor => _anchorCandidates(const Size(1, 1), 0).first.$1;

  /// Menü-Knopf in Pixeln innerhalb des Rasters (inkl. Abständen zwischen den Kacheln).
  Offset menuAnchorPixels(Size size, double gap) => _anchorCandidates(size, gap).first.$2;

  /// Lage des Menü-Knopfs im Blickwinkel von Spieler [seat] (0..1, v = 0 ist "oben" = Tischmitte),
  /// oder null, wenn der Knopf nicht an dieser Kachel liegt.
  Offset? menuAnchorInSeat(int seat) {
    final totalFlex = rows.fold(0, (sum, r) => sum + flexOf(r));
    final anchor = menuAnchor;
    var index = 0;
    var top = 0.0;
    for (final row in rows) {
      final h = flexOf(row) / totalFlex;
      for (var c = 0; c < row.length; c++, index++) {
        if (index != seat) continue;
        final left = c / row.length, w = 1 / row.length;
        const eps = 1e-6;
        final touches = anchor.dx >= left - eps && anchor.dx <= left + w + eps && anchor.dy >= top - eps && anchor.dy <= top + h + eps;
        if (!touches) return null;
        final sx = (anchor.dx - left) / w, sy = (anchor.dy - top) / h;
        // Bildschirm → Blickwinkel des Spielers (Umkehrung der RotatedBox-Drehung im Uhrzeigersinn)
        return switch (row[c]) {
          kSeatLeft => Offset(sy, 1 - sx),
          kSeatTop => Offset(1 - sx, 1 - sy),
          kSeatRight => Offset(1 - sy, sx),
          _ => Offset(sx, sy),
        };
      }
      top += h;
    }
    return null;
  }

  static bool _isHeadRow(List<int> row) => row.length == 1 && (row.first == kSeatTop || row.first == kSeatBottom);

  // Kopf-Kacheln (quer über die ganze Breite) sind flacher, wenn es daneben Seiten-Plätze gibt
  int flexOf(List<int> row) => _isHeadRow(row) && rows.any((r) => !_isHeadRow(r)) ? 2 : 3;
}

const Map<int, List<MtgLayout>> kMtgLayouts = {
  2: [
    MtgLayout([[kSeatTop], [kSeatBottom]]),
    MtgLayout([[kSeatLeft, kSeatRight]]),
  ],
  3: [
    MtgLayout([[kSeatTop], [kSeatLeft, kSeatRight]]),
    MtgLayout([[kSeatLeft, kSeatRight], [kSeatBottom]]),
    MtgLayout([[kSeatTop], [kSeatBottom], [kSeatBottom]]),
  ],
  4: [
    MtgLayout([[kSeatLeft, kSeatRight], [kSeatLeft, kSeatRight]]),
    MtgLayout([[kSeatTop], [kSeatLeft, kSeatRight], [kSeatBottom]]),
    MtgLayout([[kSeatTop, kSeatTop], [kSeatBottom, kSeatBottom]]),
  ],
  5: [
    MtgLayout([[kSeatTop], [kSeatLeft, kSeatRight], [kSeatLeft, kSeatRight]]),
    MtgLayout([[kSeatLeft, kSeatRight], [kSeatLeft, kSeatRight], [kSeatBottom]]),
    MtgLayout([[kSeatTop, kSeatTop], [kSeatLeft, kSeatRight], [kSeatBottom]]),
  ],
  6: [
    MtgLayout([[kSeatLeft, kSeatRight], [kSeatLeft, kSeatRight], [kSeatLeft, kSeatRight]]),
    MtgLayout([[kSeatTop], [kSeatLeft, kSeatRight], [kSeatLeft, kSeatRight], [kSeatBottom]]),
    MtgLayout([[kSeatTop, kSeatTop, kSeatTop], [kSeatBottom, kSeatBottom, kSeatBottom]]),
  ],
};

MtgLayout mtgLayoutFor(int playerCount, int index) {
  final options = kMtgLayouts[playerCount]!;
  return options[index.clamp(0, options.length - 1)];
}

/// Baut das Kachel-Raster eines Layouts. [seatBuilder] bekommt Spielerindex und Sitzrichtung.
class MtgLayoutGrid extends StatelessWidget {
  final MtgLayout layout;
  final double gap;
  final Widget Function(int playerIndex, int quarterTurns) seatBuilder;

  const MtgLayoutGrid({super.key, required this.layout, required this.seatBuilder, this.gap = 6});

  @override
  Widget build(BuildContext context) {
    var playerIndex = 0;
    final rows = <Widget>[];
    for (var r = 0; r < layout.rows.length; r++) {
      final row = layout.rows[r];
      final cells = <Widget>[];
      for (var c = 0; c < row.length; c++) {
        if (c > 0) cells.add(SizedBox(width: gap));
        cells.add(Expanded(child: RotatedBox(quarterTurns: row[c], child: seatBuilder(playerIndex++, row[c]))));
      }
      if (r > 0) rows.add(SizedBox(height: gap));
      rows.add(Expanded(flex: layout.flexOf(row), child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

/// Kleine Vorschau eines Layouts für die Auswahl.
class MtgLayoutThumbnail extends StatelessWidget {
  final MtgLayout layout;
  final List<Color> colors;
  final int startLife;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const MtgLayoutThumbnail({
    super.key,
    required this.layout,
    required this.colors,
    required this.startLife,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 96,
        height: 150,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? accent : Colors.white24, width: selected ? 3 : 1.5),
        ),
        child: MtgLayoutGrid(
          layout: layout,
          gap: 3,
          seatBuilder: (i, _) => Container(
            decoration: BoxDecoration(
              color: selected ? colors[i % colors.length] : Colors.white24,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text('$startLife', style: TextStyle(color: selected ? mtgForegroundOn(colors[i % colors.length]) : Colors.white70, fontWeight: FontWeight.w900, fontSize: 13)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
