import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mtg_commander_art.dart';
import 'mtg_i18n.dart';
import 'mtg_model.dart';

enum MtgRollPhase { ready, rolling, result }

/// Zustand von "Wer beginnt?" für eine Kachel.
class MtgRollState {
  final MtgRollPhase phase;
  final int? value;
  final bool decided; // Sieger steht fest
  final bool isWinner;
  final bool isTieReroll; // muss wegen Gleichstand nochmal würfeln

  const MtgRollState({required this.phase, this.value, this.decided = false, this.isWinner = false, this.isTieReroll = false});
}

/// Eine Spieler-Kachel. Alles hier ist im Blickwinkel des Spielers gebaut, die Drehung
/// zum Sitzplatz passiert aussen per RotatedBox. Links = −, rechts = +.
/// Oben (zur Tischmitte): Zug-Timer, Missed Triggers, Einstellungen.
/// Unten (beim Spieler): Commander-Abzeichen, Steuer-Knopf, Chips.
class MtgPlayerTile extends StatefulWidget {
  final int index;
  final List<MtgPlayer> players;
  final int? recentDelta;
  final int? commanderEditSource;
  final MtgRollState? roll;
  final bool missedTriggersEnabled;
  final bool isActiveTurn;
  final String? turnLabel;
  final bool showStartTurn;
  // Lage des Menü-Knopfs im Blickwinkel dieses Spielers (0..1), falls er an dieser Kachel liegt
  final Offset? menuAnchor;

  final ValueChanged<int> onLifeChange;
  final VoidCallback onOpenSheet;
  final ValueChanged<int> onCommanderDrop;
  final void Function(int source, int delta) onCommanderChange;
  final ValueChanged<int> onOpenCommanderEdit;
  final VoidCallback onCloseCommanderEdit;
  final ValueChanged<int> onTaxChange;
  final ValueChanged<int> onMissedTriggerChange;
  final VoidCallback onRoll;
  final VoidCallback onDismissRoll;
  final VoidCallback onPassTurn;
  final VoidCallback onStartTurn;

  const MtgPlayerTile({
    super.key,
    required this.index,
    required this.players,
    required this.onLifeChange,
    required this.onOpenSheet,
    required this.onCommanderDrop,
    required this.onCommanderChange,
    required this.onOpenCommanderEdit,
    required this.onCloseCommanderEdit,
    required this.onTaxChange,
    required this.onMissedTriggerChange,
    required this.onRoll,
    required this.onDismissRoll,
    required this.onPassTurn,
    required this.onStartTurn,
    this.recentDelta,
    this.commanderEditSource,
    this.roll,
    this.missedTriggersEnabled = false,
    this.isActiveTurn = false,
    this.turnLabel,
    this.showStartTurn = false,
    this.menuAnchor,
  });

  @override
  State<MtgPlayerTile> createState() => _MtgPlayerTileState();
}

class _MtgPlayerTileState extends State<MtgPlayerTile> {
  Timer? _repeat;

  MtgPlayer get _player => widget.players[widget.index];
  Color get _fg => _player.foreground;

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  void _startRepeat(int sign) {
    HapticFeedback.mediumImpact();
    widget.onLifeChange(10 * sign);
    _repeat?.cancel();
    _repeat = Timer.periodic(const Duration(milliseconds: 600), (_) {
      HapticFeedback.selectionClick();
      widget.onLifeChange(10 * sign);
    });
  }

  void _stopRepeat() {
    _repeat?.cancel();
    _repeat = null;
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != widget.index,
      onAcceptWithDetails: (d) {
        HapticFeedback.heavyImpact();
        widget.onCommanderDrop(d.data);
      },
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        final highlight = hovering || widget.isActiveTurn;
        final art = _player.art;
        return LayoutBuilder(builder: (context, box) {
          final s = min(box.maxWidth, box.maxHeight);
          final bar = (s * 0.18).clamp(26.0, 44.0);
          final edge = (s * 0.07).clamp(8.0, 20.0); // Abstand aller Elemente zum Kachelrand
          final glyph = (s * 0.24).clamp(36.0, 68.0); // Grösse der − / + Knöpfe
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: _player.color,
              borderRadius: BorderRadius.circular(18),
              // Mit Artwork bleibt die Spielerfarbe als Rahmen sichtbar, damit man sich zuordnen kann
              border: Border.all(color: highlight ? Colors.white : (art != null ? _player.color : Colors.transparent), width: 4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  if (art != null) ...[
                    Positioned.fill(child: mtgArtImageBuilder(art.artUrl)),
                    // Abdunkeln + Verlauf zu den Kanten, damit Zahl, Knöpfe und Chips lesbar bleiben
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0, 0.3, 0.7, 1],
                              colors: [Color(0xB3000000), Color(0x59000000), Color(0x59000000), Color(0xB3000000)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Ausgeschieden: Hintergrund abdunkeln (Knöpfe bleiben bedienbar, um Fehler zu korrigieren)
                  if (_player.isDead) Positioned.fill(child: IgnorePointer(child: ColoredBox(color: Colors.black.withValues(alpha: 0.35)))),
                  _buildTapZones(edge, glyph),
                  _buildLife(bar, edge, glyph, s),
                  ..._buildTopBars(bar: bar, edge: edge, width: box.maxWidth),
                  _bar(top: false, edge: edge, height: bar, width: box.maxWidth, child: _buildBottomBar(bar, _barAlignment(top: false))),
                  // Künstler & Copyright müssen laut Scryfall beim Artwork sichtbar sein
                  if (art != null)
                    Positioned(
                      right: 8,
                      bottom: 2,
                      child: IgnorePointer(
                        child: Text(
                          art.artist.isEmpty ? '© WotC' : '${art.artist} · © WotC',
                          style: const TextStyle(color: Colors.white54, fontSize: 8),
                        ),
                      ),
                    ),
                  if (hovering) _buildDropHint(s),
                  if (widget.roll != null) _buildRollOverlay(widget.roll!),
                  if (widget.commanderEditSource != null) _buildCommanderStepper(widget.commanderEditSource!),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // Platz, den der Menü-Knopf (58 px) samt Luft an einer Kachelkante braucht
  static const double _menuClearance = 58 / 2 + 10;

  bool _anchorNear({required bool top}) {
    final anchor = widget.menuAnchor;
    return anchor != null && (top ? anchor.dy < 0.3 : anchor.dy > 0.7);
  }

  /// Obere / untere Leiste. Liegt der Menü-Knopf an dieser Kante, bekommt die Leiste nur den
  /// freien Bereich neben dem Knopf (und verkleinert sich bei Bedarf darin).
  Widget _bar({required bool top, required double edge, required double height, required double width, required Widget child}) {
    final (left, right) = _barInsets(top: top, edge: edge, width: width);
    return Positioned(top: top ? edge : null, bottom: top ? null : edge, left: left, right: right, height: height, child: child);
  }

  (double, double) _barInsets({required bool top, required double edge, required double width}) {
    var left = edge, right = edge;
    if (_anchorNear(top: top)) {
      final x = widget.menuAnchor!.dx * width;
      if (widget.menuAnchor!.dx >= 0.5) {
        right = max(edge, width - (x - _menuClearance));
      } else {
        left = max(edge, x + _menuClearance);
      }
    }
    return (left, right);
  }

  double _barSpace({required bool top, required double edge, required double width}) {
    final (left, right) = _barInsets(top: top, edge: edge, width: width);
    return width - left - right;
  }

  // Liegt der Menü-Knopf an der oberen / unteren Kante dieser Kachel, rutscht die Leiste
  // auf die Seite, die vom Knopf weg liegt.
  Alignment _barAlignment({required bool top}) {
    final anchor = widget.menuAnchor;
    if (anchor == null) return Alignment.center;
    final near = top ? anchor.dy < 0.3 : anchor.dy > 0.7;
    if (!near) return Alignment.center;
    return anchor.dx < 0.5 ? Alignment.centerRight : Alignment.centerLeft;
  }

  Widget _buildTapZones(double edge, double glyph) {
    Widget zone(int sign, Alignment glyphAlign) => Expanded(
          child: GestureDetector(
            key: ValueKey('mtg_zone_${widget.index}_${sign > 0 ? 'plus' : 'minus'}'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onLifeChange(sign);
            },
            onLongPressStart: (_) => _startRepeat(sign),
            onLongPressEnd: (_) => _stopRepeat(),
            onLongPressCancel: _stopRepeat,
            child: Align(
              alignment: glyphAlign,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: edge),
                // Gut sichtbare, runde − / + Knöpfe (die ganze Kachelhälfte bleibt die Tipp-Fläche)
                child: Container(
                  width: glyph,
                  height: glyph,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _fg.withValues(alpha: 0.1),
                    border: Border.all(color: _fg.withValues(alpha: 0.28), width: 1.5),
                  ),
                  child: Icon(sign > 0 ? Icons.add : Icons.remove, color: _fg.withValues(alpha: 0.8), size: glyph * 0.6),
                ),
              ),
            ),
          ),
        );
    return Positioned.fill(child: Row(children: [zone(-1, Alignment.centerLeft), zone(1, Alignment.centerRight)]));
  }

  Widget _buildLife(double bar, double edge, double glyph, double s) {
    final delta = widget.recentDelta;
    final shadows = _player.art != null ? const [Shadow(color: Colors.black87, blurRadius: 18)] : null;
    return Positioned.fill(
      top: edge + bar,
      bottom: edge + bar,
      left: edge * 1.5 + glyph,
      right: edge * 1.5 + glyph,
      child: IgnorePointer(
        child: Center(
          child: ConstrainedBox(
            // Lebenspunkte gross, aber nicht raumfüllend
            constraints: BoxConstraints(maxHeight: s * 0.42),
            child: FittedBox(
              fit: BoxFit.contain,
              child: _player.isDead
                  // Ausgeschieden: nur noch das zerrissene Herz statt der Lebenspunkte
                  ? Icon(Icons.heart_broken, key: const ValueKey('mtg_dead'), size: 150, color: _fg.withValues(alpha: 0.9), shadows: shadows)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Reservierter Platz, damit die Lebensanzeige beim Einblenden nicht springt
                        Opacity(
                          opacity: delta == null || delta == 0 ? 0 : 1,
                          child: Text(
                            delta == null ? '+0' : (delta > 0 ? '+$delta' : '$delta'),
                            style: TextStyle(color: _fg.withValues(alpha: 0.65), fontSize: 44, fontWeight: FontWeight.w800, height: 1, shadows: shadows),
                          ),
                        ),
                        Text(
                          '${_player.life}',
                          key: const ValueKey('mtg_life'),
                          style: TextStyle(color: _fg, fontSize: 150, fontWeight: FontWeight.w900, height: 1, shadows: shadows),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// Obere Leiste(n). Liegt der Menü-Knopf mittig auf dieser Kante, wird die Leiste geteilt:
  /// links vom Knopf Zug-Timer (bzw. Missed Triggers), rechts der Rest.
  List<Widget> _buildTopBars({required double bar, required double edge, required double width}) {
    final anchor = widget.menuAnchor;
    final near = _anchorNear(top: true);
    final lead = _topLead(bar, compact: false);
    final pips = _topPips(bar);
    final settings = _topSettings(bar);

    if (near && anchor!.dx > 0.3 && anchor.dx < 0.7) {
      final x = anchor.dx * width;
      final leftWidth = x - _menuClearance - edge;
      final leftItems = lead.isNotEmpty ? _topLead(bar, compact: leftWidth < bar * 6) : pips;
      final rightItems = [if (lead.isNotEmpty) ...pips, if (lead.isNotEmpty && pips.isNotEmpty) SizedBox(width: bar * 0.3), ...settings];
      return [
        Positioned(top: edge, left: edge, width: max(0, leftWidth), height: bar, child: _barRow(leftItems, bar, Alignment.center)),
        Positioned(top: edge, left: x + _menuClearance, right: edge, height: bar, child: _barRow(rightItems, bar, Alignment.center)),
      ];
    }

    final compact = near && _barSpace(top: true, edge: edge, width: width) < bar * 9;
    final items = [
      ..._topLead(bar, compact: compact),
      if (lead.isNotEmpty) SizedBox(width: bar * 0.3),
      ...pips,
      if (pips.isNotEmpty) SizedBox(width: bar * 0.3),
      ...settings,
    ];
    return [_bar(top: true, edge: edge, height: bar, width: width, child: _barRow(items, bar, _barAlignment(top: true)))];
  }

  Widget _barRow(List<Widget> items, double bar, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.all(bar * 0.1),
          child: Row(mainAxisSize: MainAxisSize.min, children: items),
        ),
      ),
    );
  }

  // Zug-Timer (am Zug) bzw. "Ich beginne" (noch niemand am Zug)
  List<Widget> _topLead(double bar, {required bool compact}) {
    final pillText = TextStyle(fontWeight: FontWeight.w800, fontSize: bar * 0.4);
    if (widget.isActiveTurn && widget.turnLabel != null) {
      return [
        GestureDetector(
          key: ValueKey('mtg_turn_${widget.index}'),
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onPassTurn();
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: bar * 0.3, vertical: bar * 0.08),
            decoration: BoxDecoration(color: _fg, borderRadius: BorderRadius.circular(bar)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.hourglass_bottom, size: bar * 0.45, color: _player.color),
              SizedBox(width: bar * 0.1),
              // Kompakt (wenig Platz neben dem Menü-Knopf): nur die Zeit
              Text(compact ? widget.turnLabel!.split('·').last.trim() : widget.turnLabel!,
                  style: pillText.copyWith(color: _player.color, fontFeatures: const [FontFeature.tabularFigures()])),
              SizedBox(width: bar * 0.1),
              Icon(Icons.skip_next, size: bar * 0.5, color: _player.color),
            ]),
          ),
        ),
      ];
    }
    if (widget.showStartTurn) {
      return [
        GestureDetector(
          key: ValueKey('mtg_start_turn_${widget.index}'),
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onStartTurn();
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: bar * 0.3, vertical: bar * 0.08),
            decoration: BoxDecoration(border: Border.all(color: _fg.withValues(alpha: 0.6), width: 1.5), borderRadius: BorderRadius.circular(bar)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.play_arrow, size: bar * 0.5, color: _fg),
              if (!compact) ...[
                SizedBox(width: bar * 0.08),
                Text(mtgT('start_turn'), style: pillText.copyWith(color: _fg)),
              ],
            ]),
          ),
        ),
      ];
    }
    return const [];
  }

  List<Widget> _topPips(double bar) {
    if (!widget.missedTriggersEnabled) return const [];
    return [
      for (var k = 0; k < kMissedTriggersPerGame; k++)
        Builder(builder: (context) {
          // Von hinten verbrauchen: die ersten Symbole bleiben am längsten "voll"
          final used = k >= kMissedTriggersPerGame - _player.missedTriggersUsed;
          return GestureDetector(
            key: ValueKey('mtg_trigger_${widget.index}_$k'),
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onMissedTriggerChange(used ? -1 : 1);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: bar * 0.05),
              child: Container(
                width: bar * 0.72,
                height: bar * 0.72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: used ? Colors.transparent : _fg.withValues(alpha: 0.18),
                  border: Border.all(color: _fg.withValues(alpha: used ? 0.25 : 0.7), width: 1.5),
                ),
                child: Icon(used ? Icons.close : Icons.replay, size: bar * 0.42, color: _fg.withValues(alpha: used ? 0.3 : 0.9)),
              ),
            ),
          );
        }),
    ];
  }

  List<Widget> _topSettings(double bar) => [
        GestureDetector(
          key: ValueKey('mtg_settings_${widget.index}'),
          onTap: widget.onOpenSheet,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.all(bar * 0.1),
            child: Icon(Icons.auto_awesome, size: bar * 0.55, color: _fg.withValues(alpha: 0.75)),
          ),
        ),
      ];

  // Untere Kante = die Kante beim Spieler. Dort sitzt das Commander-Abzeichen (nie in der Tischmitte
  // beim Menü-Knopf), der Steuer-Knopf und die Chips für erhaltenen Commander-Schaden und Marken.
  Widget _buildBottomBar(double bar, Alignment alignment) {
    final badge = bar * 0.8;
    final size = bar * 0.62;
    final tax = _player.counter(MtgCounter.tax);
    final chips = <Widget>[
      // Commander-Abzeichen: auf einen anderen Spieler ziehen = Commander-Schaden zufügen
      Draggable<int>(
        key: ValueKey('mtg_badge_${widget.index}'),
        data: widget.index,
        onDragStarted: HapticFeedback.mediumImpact,
        feedback: Material(color: Colors.transparent, child: MtgCommanderBadge(player: _player, size: badge * 1.4, lifted: true)),
        childWhenDragging: Opacity(opacity: 0.3, child: MtgCommanderBadge(player: _player, size: badge)),
        child: MtgCommanderBadge(player: _player, size: badge),
      ),
      SizedBox(width: bar * 0.15),
      // Commander-Steuer: Tippen +2, Halten −2
      GestureDetector(
        key: ValueKey('mtg_tax_${widget.index}'),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTaxChange(MtgCounter.tax.step);
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.onTaxChange(-MtgCounter.tax.step);
        },
        child: Container(
          height: badge,
          padding: EdgeInsets.symmetric(horizontal: size * 0.4),
          decoration: BoxDecoration(
            color: _fg.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(badge),
            border: Border.all(color: _fg.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(MtgCounter.tax.icon, size: size * 0.7, color: _fg),
            SizedBox(width: size * 0.15),
            Text('$tax', style: TextStyle(color: _fg, fontWeight: FontWeight.w900, fontSize: size * 0.7)),
          ]),
        ),
      ),
    ];

    for (final entry in widget.players.asMap().entries) {
      final dmg = _player.damageFrom(entry.key);
      if (dmg == 0) continue;
      final lethal = dmg >= kCommanderLethal;
      chips.add(_chip(
        onTap: () => widget.onOpenCommanderEdit(entry.key),
        color: entry.value.color,
        textColor: entry.value.foreground,
        border: lethal ? Colors.white : _fg.withValues(alpha: 0.4),
        icon: Icons.shield,
        text: '$dmg',
        size: size,
      ));
    }
    for (final c in MtgCounter.values) {
      final v = _player.counter(c);
      if (v == 0 || c == MtgCounter.tax) continue;
      chips.add(_chip(
        onTap: widget.onOpenSheet,
        color: _fg.withValues(alpha: 0.16),
        textColor: _fg,
        border: c == MtgCounter.poison && v >= kPoisonLethal ? Colors.white : Colors.transparent,
        icon: c.icon,
        text: '$v',
        size: size,
      ));
    }
    return Align(
      alignment: alignment,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.all(bar * 0.1),
          child: Row(mainAxisSize: MainAxisSize.min, children: chips),
        ),
      ),
    );
  }

  Widget _chip({
    required VoidCallback onTap,
    required Color color,
    required Color textColor,
    required Color border,
    required IconData icon,
    required String text,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(left: size * 0.25),
        padding: EdgeInsets.symmetric(horizontal: size * 0.3, vertical: size * 0.08),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size), border: Border.all(color: border, width: 1.5)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: size * 0.7, color: textColor),
            SizedBox(width: size * 0.12),
            Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: size * 0.7)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropHint(double s) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          alignment: Alignment.center,
          child: Icon(Icons.shield, color: Colors.white, size: s * 0.4),
        ),
      ),
    );
  }

  // "Wer beginnt?": dunkle Abdeckung über der Kachel mit einer hellen Würfel-Box - auf jeder
  // Kachelfarbe gut lesbar. Jeder Spieler würfelt selbst durch Antippen seiner Box.
  Widget _buildRollOverlay(MtgRollState roll) {
    final winner = roll.decided && roll.isWinner;
    final loser = roll.decided && !roll.isWinner;
    const gold = Color(0xFFFFD54F);

    Widget content;
    switch (roll.phase) {
      case MtgRollPhase.ready:
        content = Column(mainAxisSize: MainAxisSize.min, children: [
          if (roll.isTieReroll) Text(mtgT('tie'), style: const TextStyle(color: kMtgInk, fontSize: 18, fontWeight: FontWeight.w900)),
          const Icon(Icons.casino, size: 56, color: kMtgInk),
          const SizedBox(height: 4),
          Text(mtgT('roll_d20'), style: const TextStyle(color: kMtgInk, fontSize: 18, fontWeight: FontWeight.w800)),
        ]);
      case MtgRollPhase.rolling:
        content = const _ShufflingNumber();
      case MtgRollPhase.result:
        content = Column(mainAxisSize: MainAxisSize.min, children: [
          if (winner) const Icon(Icons.emoji_events, size: 34, color: kMtgInk),
          Text('${roll.value}', style: const TextStyle(color: kMtgInk, fontSize: 72, height: 1, fontWeight: FontWeight.w900)),
          if (winner) Text(mtgT('starts'), style: const TextStyle(color: kMtgInk, fontSize: 18, fontWeight: FontWeight.w900)),
        ]);
    }

    return Positioned.fill(
      child: GestureDetector(
        key: ValueKey('mtg_roll_${widget.index}'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (roll.phase == MtgRollPhase.ready) {
            HapticFeedback.mediumImpact();
            widget.onRoll();
          } else if (roll.decided) {
            widget.onDismissRoll();
          }
        },
        child: Container(
          color: Colors.black.withValues(alpha: winner ? 0.25 : 0.6),
          padding: const EdgeInsets.all(12),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: loser ? 0.45 : 1,
              child: Container(
                constraints: const BoxConstraints(minWidth: 150, minHeight: 130),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  color: winner ? gold : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 14, offset: Offset(0, 4))],
                ),
                alignment: Alignment.center,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommanderStepper(int source) {
    final from = widget.players[source];
    final value = _player.damageFrom(source);
    final lethal = value >= kCommanderLethal;

    Widget roundBtn(IconData icon, int delta, String key) => Material(
          color: Colors.white12,
          shape: const CircleBorder(),
          child: InkWell(
            key: ValueKey(key),
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onCommanderChange(source, delta);
            },
            child: Padding(padding: const EdgeInsets.all(14), child: Icon(icon, color: Colors.white, size: 34)),
          ),
        );

    return Positioned.fill(
      child: GestureDetector(
        // Taps ausserhalb der Knöpfe nicht an die Lebens-Zonen darunter durchreichen
        onTap: () {},
        child: Container(
          color: const Color(0xFF1E2124),
          padding: const EdgeInsets.all(10),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MtgCommanderBadge(player: from, size: 30, lifted: true),
                    const SizedBox(width: 8),
                    Text(mtgT('commander_damage'), style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    roundBtn(Icons.remove, -1, 'mtg_cmd_minus'),
                    SizedBox(
                      width: 96,
                      child: Text('$value',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: lethal ? const Color(0xFFFF5252) : Colors.white, fontSize: 52, fontWeight: FontWeight.w900)),
                    ),
                    roundBtn(Icons.add, 1, 'mtg_cmd_plus'),
                  ],
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  key: const ValueKey('mtg_cmd_done'),
                  onPressed: widget.onCloseCommanderEdit,
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: Text(mtgT('done'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Zahlen wirbeln ~1 Sekunde durcheinander, bevor das Ergebnis feststeht.
class _ShufflingNumber extends StatefulWidget {
  const _ShufflingNumber();

  @override
  State<_ShufflingNumber> createState() => _ShufflingNumberState();
}

class _ShufflingNumberState extends State<_ShufflingNumber> {
  final _random = Random();
  late int _value = _random.nextInt(20) + 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 70), (_) => setState(() => _value = _random.nextInt(20) + 1));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: (_value.isEven ? 1 : -1) * 0.12,
      child: Text('$_value', style: TextStyle(color: kMtgInk.withValues(alpha: 0.75), fontSize: 72, height: 1, fontWeight: FontWeight.w900)),
    );
  }
}

/// Commander-Abzeichen. Auf der eigenen Kachel in Kontrastfarbe (hebt sich immer ab),
/// beim Ziehen in der Spielerfarbe, damit alle sehen, wessen Commander angreift.
class MtgCommanderBadge extends StatelessWidget {
  final MtgPlayer player;
  final double size;
  final bool lifted;

  const MtgCommanderBadge({super.key, required this.player, required this.size, this.lifted = false});

  @override
  Widget build(BuildContext context) {
    final fg = player.foreground;
    final fill = lifted ? player.color : fg;
    final mark = lifted ? fg : (fg == Colors.white ? kMtgInk : Colors.white);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: mark, width: max(2, size * 0.07)),
        boxShadow: lifted ? const [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4))] : null,
      ),
      child: Icon(Icons.shield, color: mark, size: size * 0.55),
    );
  }
}
