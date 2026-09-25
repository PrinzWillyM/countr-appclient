import 'dart:math';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mtg_commander_art.dart';
import 'mtg_commander_search.dart';
import 'mtg_i18n.dart';
import 'mtg_layouts.dart';
import 'mtg_model.dart';

const Color kMtgSurface = Color(0xFF1E2124);

String mtgCounterLabel(MtgCounter c) => mtgT(c.name);

Widget _sectionTitle(String text) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(text.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
    );

Widget _stepperRow({required Widget leading, required Widget label, required int value, required VoidCallback onMinus, required VoidCallback onPlus, bool danger = false, String? keyPrefix}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(width: 30, child: Center(child: leading)),
        const SizedBox(width: 10),
        Expanded(child: label),
        IconButton(key: keyPrefix == null ? null : ValueKey('${keyPrefix}_minus'), onPressed: onMinus, icon: const Icon(Icons.remove_circle_outline, color: Colors.white54)),
        SizedBox(
          width: 40,
          child: Text('$value', textAlign: TextAlign.center, style: TextStyle(color: danger ? const Color(0xFFFF5252) : Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        IconButton(key: keyPrefix == null ? null : ValueKey('${keyPrefix}_plus'), onPressed: onPlus, icon: const Icon(Icons.add_circle_outline, color: Colors.white)),
      ],
    ),
  );
}

Widget _textLabel(String text) => Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15));

/// Einstellungen eines Spielers: Commander-Hintergrund, Kachelfarbe, Marken, erhaltener Commander-Schaden.
Future<void> showMtgPlayerSheet({
  required BuildContext context,
  required MtgGame Function() game,
  required int index,
  required Color accent,
  required void Function(VoidCallback) mutate,
  required void Function(int target, int source, int delta) changeCommander,
  required List<MtgCommanderArt> Function() recents,
  required Future<void> Function(MtgCommanderArt? art) setArt,
  required Future<MtgCommanderArt?> Function() searchArt,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: kMtgSurface,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(builder: (context, setSheet) {
      final g = game();
      final player = g.players[index];
      void apply(VoidCallback fn) {
        HapticFeedback.selectionClick();
        mutate(fn);
        setSheet(() {});
      }

      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).viewPadding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(mtgT('commander_art')),
              if (player.art != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 128,
                        height: 94,
                        child: MtgArtCard(art: player.art!, onTap: () {}, selected: true, compact: true, accent: accent),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(player.art!.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(player.art!.credit, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            TextButton.icon(
                              key: const ValueKey('mtg_art_remove'),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                              onPressed: () async {
                                HapticFeedback.selectionClick();
                                await setArt(null);
                                setSheet(() {});
                              },
                              icon: const Icon(Icons.hide_image_outlined, size: 18, color: Colors.white70),
                              label: Text(mtgT('remove_art'), style: const TextStyle(color: Colors.white70)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (recents().isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(mtgT('recent'), style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ),
                SizedBox(
                  height: 70,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recents().length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final art = recents()[i];
                      return SizedBox(
                        width: 96,
                        child: MtgArtCard(
                          art: art,
                          compact: true,
                          accent: accent,
                          selected: art.id == player.art?.id,
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            await setArt(art);
                            setSheet(() {});
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('mtg_art_search'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final art = await searchArt();
                    if (art == null) return;
                    await setArt(art);
                    setSheet(() {});
                  },
                  icon: const Icon(Icons.search),
                  label: Text(mtgT('search_commander'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              _sectionTitle(mtgT('color')),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var c = 0; c < kMtgPlayerColors.length; c++)
                    GestureDetector(
                      key: ValueKey('mtg_color_$c'),
                      onTap: () => apply(() => player.colorIndex = c),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: kMtgPlayerColors[c],
                          shape: BoxShape.circle,
                          border: Border.all(color: player.colorIndex == c ? Colors.white : Colors.white24, width: player.colorIndex == c ? 3 : 1),
                        ),
                        child: player.colorIndex == c ? Icon(Icons.check, color: mtgForegroundOn(kMtgPlayerColors[c])) : null,
                      ),
                    ),
                ],
              ),
              _sectionTitle(mtgT('counters')),
              for (final c in MtgCounter.values)
                _stepperRow(
                  keyPrefix: 'mtg_counter_${c.name}',
                  leading: Icon(c.icon, color: Colors.white70),
                  label: _textLabel(mtgCounterLabel(c)),
                  value: player.counter(c),
                  danger: c == MtgCounter.poison && player.counter(c) >= kPoisonLethal,
                  onMinus: () => apply(() => player.changeCounter(c, -c.step)),
                  onPlus: () => apply(() => player.changeCounter(c, c.step)),
                ),
              _sectionTitle(mtgT('commander_damage')),
              for (var s = 0; s < g.playerCount; s++)
                if (s != index)
                  _stepperRow(
                    keyPrefix: 'mtg_sheet_cmd_$s',
                    leading: Icon(Icons.shield, color: g.players[s].color),
                    // Keine Namen auf den Kacheln - der Gegner wird über seine Kachelfarbe erkannt
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 90,
                        height: 26,
                        decoration: BoxDecoration(color: g.players[s].color, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)),
                      ),
                    ),
                    value: player.damageFrom(s),
                    danger: player.damageFrom(s) >= kCommanderLethal,
                    onMinus: () {
                      HapticFeedback.selectionClick();
                      changeCommander(index, s, -1);
                      setSheet(() {});
                    },
                    onPlus: () {
                      HapticFeedback.selectionClick();
                      changeCommander(index, s, 1);
                      setSheet(() {});
                    },
                  ),
            ],
          ),
        ),
      );
    }),
  );
}

/// Spielerzahl, Layout, Startleben und optionale Features.
Future<void> showMtgSetupSheet({
  required BuildContext context,
  required MtgGame Function() game,
  required Color accent,
  required ValueChanged<int> onPlayerCount,
  required ValueChanged<int> onLayout,
  required ValueChanged<int> onStartLife,
  required ValueChanged<bool> onTurnTimer,
  required ValueChanged<bool> onMissedTriggers,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: kMtgSurface,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(builder: (context, setSheet) {
      final g = game();
      Widget choice(String label, bool selected, VoidCallback onTap, String key) => ChoiceChip(
            key: ValueKey(key),
            label: Text(label, style: TextStyle(color: selected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            selected: selected,
            showCheckmark: false,
            selectedColor: accent,
            backgroundColor: Colors.white10,
            onSelected: (_) {
              HapticFeedback.selectionClick();
              onTap();
              setSheet(() {});
            },
          );

      final layouts = kMtgLayouts[g.playerCount]!;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.of(context).viewPadding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(mtgT('players')),
              Wrap(spacing: 8, children: [
                for (var n = 2; n <= 6; n++) choice('$n', g.playerCount == n, () => onPlayerCount(n), 'mtg_count_$n'),
              ]),
              _sectionTitle(mtgT('layout')),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (var i = 0; i < layouts.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: MtgLayoutThumbnail(
                        key: ValueKey('mtg_layout_$i'),
                        layout: layouts[i],
                        colors: [for (final p in g.players) p.color],
                        startLife: g.startLife,
                        selected: g.layoutIndex == i,
                        accent: accent,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onLayout(i);
                          setSheet(() {});
                        },
                      ),
                    ),
                ]),
              ),
              _sectionTitle(mtgT('start_life')),
              Wrap(spacing: 8, children: [
                for (final life in const [20, 30, 40]) choice('$life', g.startLife == life, () => onStartLife(life), 'mtg_life_$life'),
              ]),
              _sectionTitle(mtgT('options')),
              _optionSwitch(
                key: 'mtg_opt_turn_timer',
                icon: Icons.hourglass_bottom,
                title: mtgT('turn_timer'),
                description: mtgT('turn_timer_desc'),
                value: g.turnTimerEnabled,
                accent: accent,
                onChanged: (v) {
                  onTurnTimer(v);
                  setSheet(() {});
                },
              ),
              _optionSwitch(
                key: 'mtg_opt_missed_triggers',
                icon: Icons.replay,
                title: mtgT('missed_triggers'),
                description: mtgT('missed_triggers_desc'),
                value: g.missedTriggersEnabled,
                accent: accent,
                onChanged: (v) {
                  onMissedTriggers(v);
                  setSheet(() {});
                },
              ),
            ],
          ),
        ),
      );
    }),
  );
}

Widget _optionSwitch({
  required String key,
  required IconData icon,
  required String title,
  required String description,
  required bool value,
  required Color accent,
  required ValueChanged<bool> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: SwitchListTile(
      key: ValueKey(key),
      value: value,
      onChanged: (v) {
        HapticFeedback.selectionClick();
        onChanged(v);
      },
      contentPadding: EdgeInsets.zero,
      activeThumbColor: Colors.black,
      activeTrackColor: accent,
      secondary: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(description, style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.35)),
      ),
    ),
  );
}

/// Münze und Würfel (d4 - d20).
Future<void> showMtgDiceDialog(BuildContext context, Color accent) {
  final random = Random();
  const dice = [0, 4, 6, 8, 10, 12, 20]; // 0 = Münze
  var selected = 20;
  String? result;

  return showDialog(
    context: context,
    builder: (context) => StatefulBuilder(builder: (context, setDialog) {
      void roll() {
        HapticFeedback.mediumImpact();
        setDialog(() {
          result = selected == 0 ? mtgT(random.nextBool() ? 'heads' : 'tails') : '${random.nextInt(selected) + 1}';
        });
      }

      return AlertDialog(
        backgroundColor: kMtgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (final d in dice)
                  ChoiceChip(
                    label: Text(d == 0 ? mtgT('coin') : 'd$d', style: TextStyle(color: selected == d ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                    selected: selected == d,
                    showCheckmark: false,
                    selectedColor: accent,
                    backgroundColor: Colors.white10,
                    onSelected: (_) => setDialog(() {
                      selected = d;
                      result = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: roll,
              child: Container(
                width: 200,
                height: 150,
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20), border: Border.all(color: accent.withValues(alpha: 0.5))),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    result ?? mtgT('tap_to_roll'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: result == null ? Colors.white54 : Colors.white, fontSize: result == null ? 18 : 72, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }),
  );
}

class MtgMenuItem {
  final String key;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const MtgMenuItem({required this.key, required this.icon, required this.label, required this.color, required this.onTap});
}

/// Knopf in der Mitte des Rasters.
class MtgCenterButton extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;
  static const double size = 58;

  const MtgCenterButton({super.key, required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('mtg_menu_button'),
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF111315),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
        ),
        child: Icon(open ? Icons.close : Icons.menu, color: Colors.white, size: 28),
      ),
    );
  }
}

/// Menü des Mittel-Knopfs: zentrierte Liste schwebender Buttons, die nacheinander hereingleiten.
class MtgFloatingMenu extends StatefulWidget {
  final List<MtgMenuItem> items;
  final VoidCallback onClose;
  const MtgFloatingMenu({super.key, required this.items, required this.onClose});

  @override
  State<MtgFloatingMenu> createState() => _MtgFloatingMenuState();
}

class _MtgFloatingMenuState extends State<MtgFloatingMenu> with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 420))..forward();

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  // Jeder Eintrag startet etwas später als der vorige
  Animation<double> _stagger(int i, int count) {
    final start = (i / (count + 1)) * 0.5;
    return CurvedAnimation(parent: _intro, curve: Interval(start, (start + 0.5).clamp(0, 1), curve: Curves.easeOutCubic));
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.items.length;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: FadeTransition(
              opacity: _intro,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.black.withValues(alpha: 0.6)),
              ),
            ),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < count; i++)
                  _animated(_stagger(i, count), Padding(padding: const EdgeInsets.only(bottom: 10), child: _entry(widget.items[i]))),
                const SizedBox(height: 8),
                _animated(
                  _stagger(count, count),
                  GestureDetector(
                    key: const ValueKey('mtg_menu_close'),
                    onTap: widget.onClose,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
                      ),
                      child: const Icon(Icons.close, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _animated(Animation<double> a, Widget child) {
    return FadeTransition(
      opacity: a,
      child: AnimatedBuilder(
        animation: a,
        builder: (context, child) => Transform.translate(offset: Offset(0, 24 * (1 - a.value)), child: child),
        child: child,
      ),
    );
  }

  Widget _entry(MtgMenuItem item) {
    return Material(
      color: const Color(0xFF1E2124),
      elevation: 8,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Colors.white12)),
      child: InkWell(
        key: ValueKey('mtg_menu_${item.key}'),
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.selectionClick();
          item.onTap();
        },
        child: SizedBox(
          width: 260,
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 10),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(11)),
                child: Icon(item.icon, color: mtgForegroundOn(item.color), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(item.label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const Icon(Icons.chevron_right, color: Colors.white24),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}
