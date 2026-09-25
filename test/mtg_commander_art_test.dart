import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:easy_score_board/games/magic_the_gathering.dart';
import 'package:easy_score_board/games/mtg/mtg_commander_art.dart';
import 'package:easy_score_board/games/mtg/mtg_commander_search.dart';
import 'package:easy_score_board/games/mtg/mtg_model.dart';

Map<String, dynamic> _card(String id, String name, {bool doubleFaced = false}) => {
      'id': id,
      'name': name,
      if (!doubleFaced) 'artist': 'Artist $id',
      if (!doubleFaced) 'image_uris': {'art_crop': 'https://cards.scryfall.io/art_crop/$id.jpg'},
      if (doubleFaced)
        'card_faces': [
          {'artist': 'Face Artist', 'image_uris': {'art_crop': 'https://cards.scryfall.io/art_crop/$id-front.jpg'}},
          {'artist': 'Back Artist', 'image_uris': {'art_crop': 'https://cards.scryfall.io/art_crop/$id-back.jpg'}},
        ],
    };

MtgCommanderArt _art(String id) => MtgCommanderArt(id: id, name: 'Commander $id', artUrl: 'https://x/$id.jpg', artist: 'A $id');

void main() {
  // Weder Netz noch Datei-Cache in Tests: Bilder durch farbige Flächen ersetzen
  setUpAll(() => mtgArtImageBuilder = (url, {fit = BoxFit.cover}) => const ColoredBox(color: Colors.teal));

  group('ScryfallClient', () {
    test('searches commanders by EDHREC popularity with the required headers', () async {
      late http.Request sent;
      final client = ScryfallClient(client: MockClient((request) async {
        sent = request;
        return http.Response(jsonEncode({'data': [_card('a', 'Atraxa, Praetors\' Voice'), _card('b', 'Esika', doubleFaced: true)]}), 200);
      }));

      final results = await client.searchCommanders(' atraxa ');
      expect(sent.url.host, 'api.scryfall.com');
      expect(sent.url.path, '/cards/search');
      expect(sent.url.queryParameters['q'], 'atraxa is:commander');
      expect(sent.url.queryParameters['order'], 'edhrec');
      expect(sent.headers['Accept'], 'application/json');
      expect(sent.headers['User-Agent'], 'Countr/1.0');

      expect(results.map((a) => a.name), ['Atraxa, Praetors\' Voice', 'Esika']);
      expect(results.first.artist, 'Artist a');
      // Doppelseitige Karte: Bild und Künstler der Vorderseite
      expect(results.last.artUrl, endsWith('b-front.jpg'));
      expect(results.last.artist, 'Face Artist');
    });

    test('no results (404) is an empty list, 429 and network errors are reported', () async {
      expect(await ScryfallClient(client: MockClient((_) async => http.Response('{}', 404))).searchCommanders('zzz'), isEmpty);
      expect(
        () => ScryfallClient(client: MockClient((_) async => http.Response('{}', 429))).searchCommanders('atraxa'),
        throwsA(isA<MtgSearchException>().having((e) => e.error, 'error', MtgSearchError.rateLimited)),
      );
      expect(
        () => ScryfallClient(client: MockClient((_) async => throw http.ClientException('offline'))).searchCommanders('atraxa'),
        throwsA(isA<MtgSearchException>().having((e) => e.error, 'error', MtgSearchError.offline)),
      );
    });

    test('keeps at least ~0.5 s between searches (Scryfall allows 2/s)', () async {
      final times = <DateTime>[];
      final client = ScryfallClient(client: MockClient((_) async {
        times.add(DateTime.now());
        return http.Response(jsonEncode({'data': []}), 200);
      }));
      await client.searchCommanders('a b');
      await client.searchCommanders('a c');
      expect(times[1].difference(times[0]).inMilliseconds, greaterThanOrEqualTo(500));
    });
  });

  group('recent commanders', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('newest first, no duplicates, max 12, persisted', () async {
      var list = <MtgCommanderArt>[];
      for (var i = 0; i < 14; i++) {
        list = await MtgRecentCommanders.add(list, _art('$i'));
      }
      list = await MtgRecentCommanders.add(list, _art('5'));
      expect(list.length, MtgRecentCommanders.maxEntries);
      expect(list.first.id, '5');
      expect(list.where((a) => a.id == '5').length, 1);

      final loaded = await MtgRecentCommanders.load();
      expect(loaded.map((a) => a.id), list.map((a) => a.id));
    });
  });

  group('model', () {
    test('art is saved with the player and makes the text white', () {
      final p = MtgPlayer(name: 'A', colorIndex: 0, life: 40); // Gelb → dunkle Schrift
      expect(p.foreground, isNot(Colors.white));
      p.art = _art('x');
      expect(p.foreground, Colors.white);

      final back = MtgPlayer.fromJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>);
      expect(back.art?.id, 'x');
      expect(back.art?.artist, 'A x');
    });

    test('restart keeps the chosen commander art', () {
      final g = MtgGame.create(playerCount: 2, startLife: 40, defaultName: (i) => 'P$i');
      g.players[0].art = _art('x');
      g.restart();
      expect(g.players[0].art?.id, 'x');
    });
  });

  group('screens', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('search: type, see art cards with artist, pick one', (tester) async {
      phone(tester);
      final client = ScryfallClient(client: MockClient((request) async {
        return http.Response(jsonEncode({'data': [_card('a', 'Atraxa'), _card('k', 'Kenrith')]}), 200);
      }));
      MtgCommanderArt? picked;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => picked = await showMtgCommanderSearch(context, client: client, recents: [_art('r')], accent: Colors.amber),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Startzustand: Hinweis + zuletzt verwendete
      expect(find.text('Commander r'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('mtg_search_field')), 'at');
      await tester.pump(const Duration(milliseconds: 500)); // Tipp-Verzögerung
      await tester.pumpAndSettle();
      expect(find.text('Atraxa'), findsOneWidget);
      expect(find.text('Artist a'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('mtg_art_k')));
      await tester.pumpAndSettle();
      expect(picked?.name, 'Kenrith');
    });

    testWidgets('search offline shows a friendly message with retry', (tester) async {
      phone(tester);
      final client = ScryfallClient(client: MockClient((_) async => throw http.ClientException('offline')));
      await tester.pumpWidget(MaterialApp(home: MtgCommanderSearchPage(client: client, recents: const [], accent: Colors.amber)));
      await tester.enterText(find.byKey(const ValueKey('mtg_search_field')), 'atraxa');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('picking a recent commander in the player sheet sets the tile background', (tester) async {
      phone(tester);
      SharedPreferences.setMockInitialValues({
        'mtg_recent_commanders': jsonEncode([_art('r').toJson()]),
      });
      await tester.pumpWidget(const MaterialApp(home: MagicTheGatheringGame()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('mtg_settings_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mtg_art_r')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final saved = jsonDecode(prefs.getString('ongoing_state_game_title_mtg')!) as Map<String, dynamic>;
      expect(((saved['players'] as List)[0] as Map)['art']['id'], 'r');

      // Weisse Schrift + Künstler-Credit auf der Kachel
      final life = tester.widget<Text>(find.descendant(of: find.byKey(const ValueKey('mtg_tile_0')), matching: find.text('40')));
      expect(life.style!.color, Colors.white);
      expect(find.text('A r · © WotC'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
