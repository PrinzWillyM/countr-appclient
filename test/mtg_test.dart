import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:easy_score_board/games/magic_the_gathering.dart';
import 'package:easy_score_board/games/mtg/mtg_layouts.dart';
import 'package:easy_score_board/games/mtg/mtg_model.dart';

const _stateKey = 'ongoing_state_game_title_mtg';

Future<Map<String, dynamic>> _saved() async {
  final prefs = await SharedPreferences.getInstance();
  return jsonDecode(prefs.getString(_stateKey)!) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> _savedPlayer(int i) async => ((await _saved())['players'] as List)[i] as Map<String, dynamic>;

void main() {
  group('model', () {
    MtgPlayer player() => MtgPlayer(name: 'A', colorIndex: 0, life: 40);

    test('commander damage also changes life and never goes below 0', () {
      final p = player();
      expect(p.changeCommanderDamage(1, 5), 5);
      expect(p.life, 35);
      expect(p.damageFrom(1), 5);
      expect(p.changeCommanderDamage(1, -8), -5);
      expect(p.life, 40);
      expect(p.damageFrom(1), 0);
    });

    test('player is out at 0 life, 10 poison or 21 from one commander', () {
      final p = player()..life = 100; // genug Leben, damit nur der Commander-Schaden zählt
      expect(p.isDead, isFalse);
      p.changeCommanderDamage(1, 20);
      p.changeCommanderDamage(2, 20);
      expect(p.isDead, isFalse, reason: '20 + 20 from two different commanders is not lethal');
      p.changeCommanderDamage(2, 1);
      expect(p.isDead, isTrue);

      final q = player()..changeCounter(MtgCounter.poison, 10);
      expect(q.isDead, isTrue);
      final r = player()..life = 0;
      expect(r.isDead, isTrue);
    });

    test('foreground contrast: yellow → dark, navy → white', () {
      expect(mtgForegroundOn(kMtgPlayerColors[0]), kMtgInk);
      expect(mtgForegroundOn(kMtgPlayerColors[9]), Colors.white);
    });

    test('every layout has a clockwise seat order covering all players', () {
      for (final entry in kMtgLayouts.entries) {
        for (final layout in entry.value) {
          expect(layout.clockwiseOrder.toSet(), {for (var i = 0; i < entry.key; i++) i});
        }
      }
      // Kopf oben, Seiten, Kopf unten: oben → rechts → unten → links
      expect(kMtgLayouts[4]![1].clockwiseOrder, [0, 2, 3, 1]);
    });

    test('menu anchor sits on a tile border, never inside a single tile', () {
      for (final entry in kMtgLayouts.entries) {
        for (final layout in entry.value) {
          final touching = [for (var i = 0; i < entry.key; i++) layout.menuAnchorInSeat(i)].whereType<Offset>().length;
          expect(touching, greaterThanOrEqualTo(2), reason: '${entry.key} players ${layout.rows}');
        }
      }
      // 2 Spieler gegenüber: Knopf liegt für beide an der oberen Kante (Tischmitte), mittig
      final facing = kMtgLayouts[2]![0];
      expect(facing.menuAnchorInSeat(0), const Offset(0.5, 0));
      expect(facing.menuAnchorInSeat(1), const Offset(0.5, 0));
    });

    test('passing the turn skips dead players', () {
      final g = MtgGame.create(playerCount: 4, startLife: 40, defaultName: (i) => 'P$i');
      g.startTurns(0);
      g.players[1].life = 0;
      g.passTurn([0, 1, 2, 3]);
      expect(g.activePlayer, 2);
    });

    test('commander tax steps by 2', () {
      final p = player()..changeCounter(MtgCounter.tax, MtgCounter.tax.step);
      expect(p.counter(MtgCounter.tax), 2);
    });

    test('json round trip', () {
      final g = MtgGame.create(playerCount: 3, startLife: 40, defaultName: (i) => 'P$i');
      g.layoutIndex = 1;
      g.players[0].changeCommanderDamage(2, 7);
      g.players[1].changeCounter(MtgCounter.poison, 3);
      final back = MtgGame.fromJson(jsonDecode(jsonEncode(g.toJson())) as Map<String, dynamic>)!;
      expect(back.layoutIndex, 1);
      expect(back.players[0].damageFrom(2), 7);
      expect(back.players[0].life, 33);
      expect(back.players[1].counter(MtgCounter.poison), 3);
    });

    test('saves of the old MTG module (v1) are migrated', () {
      final old = {
        'playerCount': 2,
        'startLife': 20,
        'players': [
          {'name': 'Alice', 'life': 14, 'cmdDamage': [0, 6]},
          {'name': 'Bob', 'life': 20, 'cmdDamage': [0, 0]},
        ],
      };
      final g = MtgGame.fromJson(old)!;
      expect(g.playerCount, 2);
      expect(g.startLife, 20);
      expect(g.players[0].name, 'Alice');
      expect(g.players[0].life, 14);
      expect(g.players[0].damageFrom(1), 6);
      expect(g.players[1].commanderDamage, isEmpty);
    });
  });

  group('screen', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> pumpGame(WidgetTester tester, {Size size = const Size(1170, 2532), bool resume = false}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: MagicTheGatheringGame(resume: resume)));
      await tester.pumpAndSettle();
    }

    testWidgets('every player count and layout renders without overflow on a 360pt phone', (tester) async {
      for (final entry in kMtgLayouts.entries) {
        for (var layout = 0; layout < entry.value.length; layout++) {
          final g = MtgGame.create(playerCount: entry.key, startLife: 40, defaultName: (i) => 'Planeswalker ${i + 1}');
          g.layoutIndex = layout;
          // Ein paar Chips anzeigen lassen, damit auch die untere Leiste geprüft wird
          g.players[0].changeCommanderDamage(1, 12);
          g.players[0].changeCounter(MtgCounter.poison, 4);
          g.players[0].changeCounter(MtgCounter.tax, 2);
          SharedPreferences.setMockInitialValues({_stateKey: jsonEncode(g.toJson())});

          await pumpGame(tester, size: const Size(1080, 2400), resume: true);
          expect(tester.takeException(), isNull, reason: '${entry.key} players, layout $layout');
          expect(find.byType(RotatedBox), findsNWidgets(entry.key), reason: '${entry.key} players, layout $layout');
          await tester.pumpWidget(const SizedBox());
        }
      }
    });

    testWidgets('menu button never covers tile controls, in any layout', (tester) async {
      Rect rectOf(Finder f) => Rect.fromPoints(tester.getTopLeft(f), tester.getBottomRight(f));
      for (final entry in kMtgLayouts.entries) {
        for (var layout = 0; layout < entry.value.length; layout++) {
          final g = MtgGame.create(playerCount: entry.key, startLife: 40, defaultName: (i) => 'P$i', turnTimerEnabled: true, missedTriggersEnabled: true);
          g.layoutIndex = layout;
          SharedPreferences.setMockInitialValues({_stateKey: jsonEncode(g.toJson())});
          await pumpGame(tester, size: const Size(1080, 2400), resume: true);

          final button = rectOf(find.byKey(const ValueKey('mtg_menu_button')));
          final controls = <String>[
            for (var i = 0; i < entry.key; i++) ...[
              'mtg_settings_$i',
              'mtg_badge_$i',
              'mtg_tax_$i',
              'mtg_start_turn_$i',
              for (var k = 0; k < 3; k++) 'mtg_trigger_${i}_$k',
            ],
          ];
          for (final key in controls) {
            expect(rectOf(find.byKey(ValueKey(key))).overlaps(button), isFalse, reason: '$key under menu button (${entry.key} players, layout $layout)');
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }
      }
    });

    testWidgets('a new game starts with the last used setup (but fresh life, colors and no commanders)', (tester) async {
      await pumpGame(tester);
      await tester.tap(find.byKey(const ValueKey('mtg_menu_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_menu_settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_count_6')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_layout_2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_life_30')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_opt_turn_timer')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('mtg_opt_missed_triggers')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_opt_missed_triggers')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_zone_0_minus')));
      await tester.pump();

      // Neues Spiel (nicht fortsetzen)
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const MaterialApp(home: MagicTheGatheringGame()));
      await tester.pumpAndSettle();

      final saved = await _saved();
      expect((saved['players'] as List).length, 6);
      expect(saved['layout'], 2);
      expect(saved['startLife'], 30);
      expect(saved['turnTimer'], isTrue);
      expect(saved['missedTriggers'], isTrue);
      expect((await _savedPlayer(0))['life'], 30, reason: 'life starts fresh');
      expect(find.byKey(const ValueKey('mtg_start_turn_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('mtg_trigger_0_0')), findsOneWidget);
    });

    testWidgets('menu opens as a list of buttons and closes with its X button', (tester) async {
      await pumpGame(tester);
      await tester.tap(find.byKey(const ValueKey('mtg_menu_button')));
      await tester.pumpAndSettle();
      for (final key in ['high_roll', 'dice', 'settings', 'restart', 'help', 'exit']) {
        expect(find.byKey(ValueKey('mtg_menu_$key')), findsOneWidget);
      }
      // Einträge stehen untereinander in der Mitte
      final xs = {for (final key in ['high_roll', 'settings', 'exit']) tester.getCenter(find.byKey(ValueKey('mtg_menu_$key'))).dx.round()};
      expect(xs.length, 1);

      await tester.tap(find.byKey(const ValueKey('mtg_menu_close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mtg_menu_high_roll')), findsNothing);
      expect(find.byKey(const ValueKey('mtg_menu_button')), findsOneWidget);
    });

    testWidgets('a player who is out shows only the broken heart instead of the life total', (tester) async {
      await pumpGame(tester);
      Finder inTile(int i, Finder f) => find.descendant(of: find.byKey(ValueKey('mtg_tile_$i')), matching: f);

      await tester.longPress(find.byKey(const ValueKey('mtg_zone_0_minus'))); // 40 → 30
      for (var i = 0; i < 30; i++) {
        await tester.tap(find.byKey(const ValueKey('mtg_zone_0_minus')));
      }
      await tester.pump();
      expect(inTile(0, find.byKey(const ValueKey('mtg_dead'))), findsOneWidget);
      expect(inTile(0, find.byKey(const ValueKey('mtg_life'))), findsNothing);

      // Leben zurückgeben belebt wieder
      await tester.tap(find.byKey(const ValueKey('mtg_zone_0_plus')));
      await tester.pump();
      expect(inTile(0, find.byKey(const ValueKey('mtg_dead'))), findsNothing);
      expect(inTile(0, find.text('1')), findsOneWidget);

      // 21 Commander-Schaden vom selben Gegner (bei genug Leben)
      final g = MtgGame.create(playerCount: 4, startLife: 40, defaultName: (i) => 'P$i');
      g.players[1].life = 60;
      g.players[1].changeCommanderDamage(0, 21);
      SharedPreferences.setMockInitialValues({_stateKey: jsonEncode(g.toJson())});
      await tester.pumpWidget(const SizedBox());
      await pumpGame(tester, resume: true);
      expect(inTile(1, find.byKey(const ValueKey('mtg_dead'))), findsOneWidget);
      expect(inTile(1, find.byKey(const ValueKey('mtg_life'))), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('tapping the left / right half changes life by 1, holding by 10', (tester) async {
      await pumpGame(tester);
      await tester.tap(find.byKey(const ValueKey('mtg_zone_0_minus')));
      await tester.pump();
      expect((await _savedPlayer(0))['life'], 39);

      await tester.tap(find.byKey(const ValueKey('mtg_zone_0_plus')));
      await tester.tap(find.byKey(const ValueKey('mtg_zone_0_plus')));
      await tester.pump();
      expect((await _savedPlayer(0))['life'], 41);
      expect(find.text('+1'), findsOneWidget, reason: 'recent change indicator (-1 +1 +1)');

      await tester.longPress(find.byKey(const ValueKey('mtg_zone_1_minus')));
      await tester.pump();
      expect((await _savedPlayer(1))['life'], 30);

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('dragging a commander badge onto another player opens the stepper', (tester) async {
      await pumpGame(tester);

      final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('mtg_badge_0'))));
      await tester.pump();
      await gesture.moveBy(const Offset(20, 20));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey('mtg_tile_3'))));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('mtg_cmd_plus')), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('mtg_cmd_plus')));
      }
      await tester.tap(find.byKey(const ValueKey('mtg_cmd_minus')));
      await tester.pump();

      final victim = await _savedPlayer(3);
      expect(victim['cmd'], {'0': 2});
      expect(victim['life'], 38);

      await tester.tap(find.byKey(const ValueKey('mtg_cmd_done')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mtg_cmd_plus')), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a badge dropped on its own tile does nothing', (tester) async {
      await pumpGame(tester);
      await tester.drag(find.byKey(const ValueKey('mtg_badge_2')), const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mtg_cmd_plus')), findsNothing);
    });

    testWidgets('center menu: setup changes players, layout and starting life; restart resets', (tester) async {
      await pumpGame(tester);

      await tester.tap(find.byKey(const ValueKey('mtg_zone_0_minus')));
      await tester.tap(find.byKey(const ValueKey('mtg_menu_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_menu_settings')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('mtg_count_6')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_layout_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_life_30')));
      await tester.pumpAndSettle();

      final saved = await _saved();
      expect((saved['players'] as List).length, 6);
      expect(saved['layout'], 1);
      expect(saved['startLife'], 30);
      expect((await _savedPlayer(0))['life'], 30);
      expect(tester.takeException(), isNull);

      // Sheet schliessen, Leben ändern, Neustart
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_zone_2_plus')));
      await tester.tap(find.byKey(const ValueKey('mtg_menu_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_menu_restart')));
      await tester.pumpAndSettle();
      expect((await _savedPlayer(2))['life'], 30);
    });

    testWidgets('high roll: every player rolls on their own tile, ties reroll, one winner starts', (tester) async {
      await pumpGame(tester);
      await tester.tap(find.byKey(const ValueKey('mtg_menu_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_menu_settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_opt_turn_timer')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('mtg_menu_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_menu_high_roll')));
      await tester.pump();
      expect(find.text('d20 werfen'), findsNWidgets(4));

      // Einer würfelt: 1 s Animation, danach steht die Zahl
      await tester.tap(find.byKey(const ValueKey('mtg_roll_0')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('d20 werfen'), findsNWidgets(3));
      await tester.pump(const Duration(seconds: 1));

      // Alle anderen würfeln, bei Gleichstand so lange nachwürfeln, bis es einen Sieger gibt
      for (var round = 0; round < 20 && find.byIcon(Icons.emoji_events).evaluate().isEmpty; round++) {
        for (var i = 0; i < 4; i++) {
          final box = find.byKey(ValueKey('mtg_roll_$i'));
          if (find.descendant(of: box, matching: find.text('d20 werfen')).evaluate().isNotEmpty) {
            await tester.tap(box);
          }
        }
        await tester.pump(const Duration(milliseconds: 1100));
      }
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.text('Beginnt!'), findsOneWidget);

      // Mit Zug-Timer beginnt der Sieger automatisch seinen Zug
      final saved = await _saved();
      expect(saved['active'], isNotNull);
      expect(saved['starter'], saved['active']);

      await tester.tap(find.byKey(const ValueKey('mtg_roll_2')));
      await tester.pump();
      expect(find.byIcon(Icons.emoji_events), findsNothing);
      await tester.pumpWidget(const SizedBox()); // Ticker des Zug-Timers beenden
    });

    testWidgets('commander tax button: tap +2, hold -2', (tester) async {
      await pumpGame(tester);
      await tester.tap(find.byKey(const ValueKey('mtg_tax_1')));
      await tester.tap(find.byKey(const ValueKey('mtg_tax_1')));
      await tester.pump();
      expect((await _savedPlayer(1))['counters'], {'tax': 4});
      await tester.longPress(find.byKey(const ValueKey('mtg_tax_1')));
      await tester.pump();
      expect((await _savedPlayer(1))['counters'], {'tax': 2});
    });

    testWidgets('missed triggers: hidden until enabled, max 3, can be taken back', (tester) async {
      await pumpGame(tester);
      expect(find.byKey(const ValueKey('mtg_trigger_0_0')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('mtg_menu_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_menu_settings')));
      await tester.pumpAndSettle();
      expect(find.textContaining('3 verpasste Trigger'), findsOneWidget, reason: 'explanation is shown');
      await tester.ensureVisible(find.byKey(const ValueKey('mtg_opt_missed_triggers')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_opt_missed_triggers')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      for (var k = 0; k < 3; k++) {
        await tester.tap(find.byKey(ValueKey('mtg_trigger_0_$k')));
      }
      await tester.pump();
      expect((await _savedPlayer(0))['missed'], 3);
      // Alle verbraucht: ein weiterer Tipp auf ein verbrauchtes Symbol nimmt einen zurück
      await tester.tap(find.byKey(const ValueKey('mtg_trigger_0_2')));
      await tester.pump();
      expect((await _savedPlayer(0))['missed'], 2);
      expect((await _saved())['missedTriggers'], isTrue);
    });

    testWidgets('turn timer: start, pass clockwise, count rounds', (tester) async {
      await pumpGame(tester);
      await tester.tap(find.byKey(const ValueKey('mtg_menu_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_menu_settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_opt_turn_timer')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Noch niemand am Zug: jeder kann "Ich beginne" tippen
      expect(find.byKey(const ValueKey('mtg_start_turn_0')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('mtg_start_turn_0')));
      await tester.pump(const Duration(seconds: 65));
      expect(find.text('Runde 1 · 01:05'), findsOneWidget);

      // 2x2-Layout im Uhrzeigersinn: oben links (0) → oben rechts (1) → unten rechts (3) → unten links (2)
      final visited = <int>[];
      for (var i = 0; i < 4; i++) {
        final active = (await _saved())['active'] as int;
        visited.add(active);
        await tester.tap(find.byKey(ValueKey('mtg_turn_$active')));
        await tester.pump();
      }
      expect(visited, [0, 1, 3, 2]);
      expect((await _saved())['active'], 0);
      expect((await _saved())['round'], 2);
      expect(find.text('Runde 2 · 00:00'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('light tiles get dark text, dark tiles get white text', (tester) async {
      await pumpGame(tester);
      await tester.tap(find.byKey(const ValueKey('mtg_settings_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_color_9'))); // Nachtblau
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      Color lifeColor(int player) => tester
          .widget<Text>(find.descendant(of: find.byKey(ValueKey('mtg_tile_$player')), matching: find.text('40')))
          .style!
          .color!;
      expect(lifeColor(0), Colors.white);
      expect(lifeColor(1), isNot(Colors.white)); // Rot bleibt bei Anthrazit
      expect((await _savedPlayer(0))['color'], 9);
    });

    testWidgets('player sheet edits counters and commander damage', (tester) async {
      await pumpGame(tester);
      await tester.tap(find.byKey(const ValueKey('mtg_settings_3')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('mtg_counter_poison_plus')));
      await tester.tap(find.byKey(const ValueKey('mtg_counter_tax_plus')));
      await tester.tap(find.byKey(const ValueKey('mtg_sheet_cmd_1_plus')));
      await tester.pump();

      final p = await _savedPlayer(3);
      expect(p['counters'], {'poison': 1, 'tax': 2});
      expect(p['cmd'], {'1': 1});
      expect(p['life'], 39);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
