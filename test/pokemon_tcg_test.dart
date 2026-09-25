import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:easy_score_board/games/pokemon_tcg.dart';

// Liest den gespeicherten Spielstand von Spieler 1 (unten) aus der Persistenz.
Future<Map<String, dynamic>> _player1() async {
  final prefs = await SharedPreferences.getInstance();
  final state = jsonDecode(prefs.getString('ongoing_state_game_title_pkm')!) as Map<String, dynamic>;
  return state['player1'] as Map<String, dynamic>;
}

Future<Map<String, dynamic>> _p1Active() async => (await _player1())['active'] as Map<String, dynamic>;
Future<Map<String, dynamic>> _p1Bench(int i) async => ((await _player1())['bench'] as List)[i] as Map<String, dynamic>;

Finder _inSheet(Finder matching) => find.descendant(of: find.byType(BottomSheet), matching: matching);

// Spieler 1 wird nach Spieler 2 gebaut, darum jeweils .last bzw. die letzten 5 Bank-Slots
Finder get _p1ActiveSlot => find.text('Aktiv').last;
Finder _p1BenchSlot(int i) => find.text('Bank').at(5 + i);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpGame(WidgetTester tester, {Size size = const Size(1170, 2532)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: PokemonTCGGame()));
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(WidgetTester tester, Finder slot) async {
    await tester.tap(slot);
    await tester.pumpAndSettle();
  }

  Future<void> closeSheet(WidgetTester tester) async {
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  }

  Future<void> dragToken(WidgetTester tester, Finder token, Finder target) async {
    final gesture = await tester.startGesture(tester.getCenter(token));
    // Zuerst vertikal bewegen, damit nicht die horizontale Token-Leiste scrollt
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('damage buttons in the edit sheet apply their amount exactly once', (tester) async {
    await pumpGame(tester);
    await openSheet(tester, _p1ActiveSlot);

    await tester.tap(_inSheet(find.text('+10')));
    await tester.pump();
    expect((await _p1Active())['damage'], 10);

    await tester.tap(_inSheet(find.text('+50')));
    await tester.pump();
    expect((await _p1Active())['damage'], 60);

    await tester.tap(_inSheet(find.text('-10')));
    await tester.pump();
    expect((await _p1Active())['damage'], 50);

    await tester.tap(_inSheet(find.text('-50')));
    await tester.pump();
    expect((await _p1Active())['damage'], 0);
  });

  testWidgets('burn, poison and conditions can be toggled off again on the active Pokémon', (tester) async {
    await pumpGame(tester);

    // Verbrennung per Drag & Drop setzen (wie im echten Spiel)
    await dragToken(tester, find.byIcon(Icons.local_fire_department).first, _p1ActiveSlot);
    expect((await _p1Active())['isBurned'], isTrue);

    await openSheet(tester, _p1ActiveSlot);
    await tester.tap(_inSheet(find.byIcon(Icons.local_fire_department)));
    await tester.pump();
    expect((await _p1Active())['isBurned'], isFalse);

    await tester.tap(_inSheet(find.byIcon(Icons.sick)));
    await tester.pump();
    expect((await _p1Active())['isPoisoned'], isTrue);
    await tester.tap(_inSheet(find.byIcon(Icons.sick)));
    await tester.pump();
    expect((await _p1Active())['isPoisoned'], isFalse);

    // Schlaf / Paralyse / Verwirrung schliessen sich gegenseitig aus
    await tester.tap(_inSheet(find.byIcon(Icons.nights_stay)));
    await tester.pump();
    expect((await _p1Active())['condition'], 'asleep');
    await tester.tap(_inSheet(find.byIcon(Icons.bolt)));
    await tester.pump();
    expect((await _p1Active())['condition'], 'paralyzed');
    await tester.tap(_inSheet(find.byIcon(Icons.bolt)));
    await tester.pump();
    expect((await _p1Active())['condition'], 'none');
  });

  testWidgets('bench slots accept damage tokens but no status tokens', (tester) async {
    await pumpGame(tester);

    await dragToken(tester, find.byIcon(Icons.local_fire_department).first, _p1BenchSlot(0));
    expect((await _p1Bench(0))['isBurned'], isFalse);

    await dragToken(tester, find.text('10').first, _p1BenchSlot(0));
    expect((await _p1Bench(0))['damage'], 10);
  });

  testWidgets('switching clears conditions of the Pokémon going to the bench, keeps damage', (tester) async {
    await pumpGame(tester);

    await dragToken(tester, find.byIcon(Icons.local_fire_department).first, _p1ActiveSlot);
    await dragToken(tester, find.text('50').first, _p1ActiveSlot);

    await openSheet(tester, _p1BenchSlot(0));
    await tester.tap(_inSheet(find.text('Einwechseln')));
    await tester.pumpAndSettle();

    final benched = await _p1Bench(0);
    expect(benched['isBurned'], isFalse);
    expect(benched['damage'], 50);
  });

  testWidgets('middle lane has no turn counter anymore', (tester) async {
    await pumpGame(tester);
    expect(find.text('Zug'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit sheet fits on a narrow 360pt Android phone', (tester) async {
    await pumpGame(tester, size: const Size(1080, 2400));
    await openSheet(tester, _p1ActiveSlot);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit sheet fits on screen without overflow', (tester) async {
    await pumpGame(tester);
    await openSheet(tester, _p1ActiveSlot);
    expect(tester.takeException(), isNull);
    await closeSheet(tester);
    await openSheet(tester, _p1BenchSlot(0));
    expect(tester.takeException(), isNull);
  });
}
