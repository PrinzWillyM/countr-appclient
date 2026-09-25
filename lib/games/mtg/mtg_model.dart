import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mtg_commander_art.dart';

const int kPoisonLethal = 10;
const int kCommanderLethal = 21;
const int kMissedTriggersPerGame = 3;

// Kachelfarben: zuerst kräftige (Standard), dann dunkle
const List<Color> kMtgPlayerColors = [
  Color(0xFFFFC21A), // Gelb
  Color(0xFFFF2E63), // Rot
  Color(0xFF4C5CFF), // Blau
  Color(0xFFF6A3F2), // Rosa
  Color(0xFF2ED47A), // Grün
  Color(0xFFFF8A3D), // Orange
  Color(0xFF26D0CE), // Türkis
  Color(0xFFB288FF), // Lila
  Color(0xFF2B2F36), // Anthrazit
  Color(0xFF1B2A4A), // Nachtblau
  Color(0xFF1F4D3A), // Waldgrün
  Color(0xFF5A1E2B), // Bordeaux
  Color(0xFF3D2A5C), // Dunkellila
  Color(0xFF0E4D5C), // Petrol
  Color(0xFF5C3A1E), // Braun
  Color(0xFF4A4A4A), // Graphit
];

const Color kMtgInk = Color(0xFF1F2328); // Anthrazit für Text auf hellen Kacheln

/// Text-/Icon-Farbe mit dem besseren Kontrast (WCAG) zur Hintergrundfarbe:
/// dunkle Kacheln bekommen Weiss, helle Kacheln Anthrazit.
Color mtgForegroundOn(Color background) {
  final l = background.computeLuminance();
  final inkL = kMtgInk.computeLuminance();
  final contrastWhite = 1.05 / (l + 0.05);
  final contrastInk = (l + 0.05) / (inkL + 0.05);
  return contrastWhite > contrastInk ? Colors.white : kMtgInk;
}

enum MtgCounter { poison, tax, energy, experience }

extension MtgCounterInfo on MtgCounter {
  IconData get icon => switch (this) {
        MtgCounter.poison => Icons.coronavirus,
        MtgCounter.tax => Icons.account_balance,
        MtgCounter.energy => Icons.bolt,
        MtgCounter.experience => Icons.star,
      };

  // Commander-Steuer steigt immer um 2 Mana
  int get step => this == MtgCounter.tax ? 2 : 1;
}

class MtgPlayer {
  String name;
  int colorIndex;
  int life;
  // Erhaltener Commander-Schaden, Schlüssel = Index des Spielers, dessen Commander den Schaden verursacht hat
  final Map<int, int> commanderDamage;
  final Map<MtgCounter, int> counters;
  // Bereits genutzte "Missed Triggers" (verpasster Trigger darf nachgeholt werden, max. 3 pro Spiel)
  int missedTriggersUsed;
  // Optionales Commander-Artwork als Kachel-Hintergrund
  MtgCommanderArt? art;

  MtgPlayer({
    required this.name,
    required this.colorIndex,
    required this.life,
    Map<int, int>? commanderDamage,
    Map<MtgCounter, int>? counters,
    this.missedTriggersUsed = 0,
    this.art,
  })  : commanderDamage = commanderDamage ?? {},
        counters = counters ?? {};

  Color get color => kMtgPlayerColors[colorIndex % kMtgPlayerColors.length];
  // Über Artwork (mit dunklem Verlauf) ist Weiss immer am besten lesbar
  Color get foreground => art != null ? Colors.white : mtgForegroundOn(color);

  int counter(MtgCounter c) => counters[c] ?? 0;
  int damageFrom(int source) => commanderDamage[source] ?? 0;

  bool get isDead =>
      life <= 0 || counter(MtgCounter.poison) >= kPoisonLethal || commanderDamage.values.any((d) => d >= kCommanderLethal);

  /// Setzt Leben und alle Marken zurück, Name und Farbe bleiben.
  void resetFor(int startLife) {
    life = startLife;
    commanderDamage.clear();
    counters.clear();
    missedTriggersUsed = 0;
  }

  /// Ändert den Commander-Schaden von [source] um [delta] (nie unter 0) und passt das Leben
  /// um denselben Betrag an. Gibt die tatsächliche Änderung zurück.
  int changeCommanderDamage(int source, int delta) {
    final current = damageFrom(source);
    final next = max(0, current + delta);
    final applied = next - current;
    if (next == 0) {
      commanderDamage.remove(source);
    } else {
      commanderDamage[source] = next;
    }
    life -= applied;
    return applied;
  }

  void changeCounter(MtgCounter c, int delta) {
    final next = max(0, counter(c) + delta);
    if (next == 0) {
      counters.remove(c);
    } else {
      counters[c] = next;
    }
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': colorIndex,
        'life': life,
        'cmd': commanderDamage.map((k, v) => MapEntry('$k', v)),
        'counters': counters.map((k, v) => MapEntry(k.name, v)),
        'missed': missedTriggersUsed,
        if (art != null) 'art': art!.toJson(),
      };

  factory MtgPlayer.fromJson(Map<String, dynamic> json) => MtgPlayer(
        name: json['name'] as String? ?? '',
        colorIndex: json['color'] as int? ?? 0,
        life: json['life'] as int? ?? 40,
        commanderDamage: (json['cmd'] as Map? ?? {}).map((k, v) => MapEntry(int.parse('$k'), v as int)),
        counters: {
          for (final e in (json['counters'] as Map? ?? {}).entries)
            if (MtgCounter.values.any((c) => c.name == e.key)) MtgCounter.values.byName(e.key as String): e.value as int,
        },
        missedTriggersUsed: json['missed'] as int? ?? 0,
        art: MtgCommanderArt.fromJson(json['art']),
      );
}

class MtgGame {
  int startLife;
  int layoutIndex;
  List<MtgPlayer> players;

  // Optionale Features (im Einstellungs-Sheet aktivierbar)
  bool turnTimerEnabled;
  bool missedTriggersEnabled;

  // Zug-Timer: wer ist am Zug, wer hat begonnen (für die Rundenzählung), aktuelle Runde
  int? activePlayer;
  int? startingPlayer;
  int round;

  MtgGame({
    required this.startLife,
    required this.layoutIndex,
    required this.players,
    this.turnTimerEnabled = false,
    this.missedTriggersEnabled = false,
    this.activePlayer,
    this.startingPlayer,
    this.round = 1,
  });

  int get playerCount => players.length;

  static MtgGame create({
    required int playerCount,
    required int startLife,
    required String Function(int) defaultName,
    List<MtgPlayer> keep = const [],
    bool turnTimerEnabled = false,
    bool missedTriggersEnabled = false,
  }) {
    return MtgGame(
      startLife: startLife,
      layoutIndex: 0,
      turnTimerEnabled: turnTimerEnabled,
      missedTriggersEnabled: missedTriggersEnabled,
      players: List.generate(playerCount, (i) {
        // Name & Farbe bestehender Spieler übernehmen, wenn die Spielerzahl geändert wird
        final old = i < keep.length ? keep[i] : null;
        return MtgPlayer(name: old?.name ?? defaultName(i), colorIndex: old?.colorIndex ?? i, life: startLife, art: old?.art);
      }),
    );
  }

  void restart() {
    for (final p in players) {
      p.resetFor(startLife);
    }
    resetTurns();
  }

  void resetTurns() {
    activePlayer = null;
    startingPlayer = null;
    round = 1;
  }

  void startTurns(int player) {
    activePlayer = player;
    startingPlayer = player;
    round = 1;
  }

  /// Gibt den Zug im Uhrzeigersinn ([seatOrder]) an den nächsten lebenden Spieler weiter.
  /// Die Runde zählt hoch, sobald der Zug wieder beim Startspieler (bzw. an ihm vorbei) ankommt.
  void passTurn(List<int> seatOrder) {
    final current = activePlayer;
    final starter = startingPlayer;
    if (current == null || starter == null) return;
    final n = seatOrder.length;
    int rel(int player) => (seatOrder.indexOf(player) - seatOrder.indexOf(starter) + n) % n;

    var pos = seatOrder.indexOf(current);
    for (var step = 0; step < n; step++) {
      pos = (pos + 1) % n;
      final candidate = seatOrder[pos];
      if (!players[candidate].isDead || candidate == current) {
        if (rel(candidate) <= rel(current)) round++;
        activePlayer = candidate;
        return;
      }
    }
  }

  Map<String, dynamic> toJson() => {
        'v': 2,
        'startLife': startLife,
        'layout': layoutIndex,
        'players': players.map((p) => p.toJson()).toList(),
        'turnTimer': turnTimerEnabled,
        'missedTriggers': missedTriggersEnabled,
        'active': activePlayer,
        'starter': startingPlayer,
        'round': round,
      };

  /// Liest v2 und migriert gespeicherte Spiele des alten MTG-Moduls (v1).
  static MtgGame? fromJson(Map<String, dynamic> json) {
    try {
      final rawPlayers = (json['players'] as List).map((p) => Map<String, dynamic>.from(p as Map)).toList();
      if (json['v'] == 2) {
        return MtgGame(
          startLife: json['startLife'] as int? ?? 40,
          layoutIndex: json['layout'] as int? ?? 0,
          players: rawPlayers.map(MtgPlayer.fromJson).toList(),
          turnTimerEnabled: json['turnTimer'] as bool? ?? false,
          missedTriggersEnabled: json['missedTriggers'] as bool? ?? false,
          activePlayer: json['active'] as int?,
          startingPlayer: json['starter'] as int?,
          round: json['round'] as int? ?? 1,
        );
      }
      // v1: {'name', 'life', 'cmdDamage': [Schaden je Gegner-Index]}
      return MtgGame(
        startLife: json['startLife'] as int? ?? 20,
        layoutIndex: 0,
        players: [
          for (var i = 0; i < rawPlayers.length; i++)
            MtgPlayer(
              name: rawPlayers[i]['name'] as String? ?? '',
              colorIndex: i,
              life: rawPlayers[i]['life'] as int? ?? 20,
              commanderDamage: {
                for (final e in ((rawPlayers[i]['cmdDamage'] as List?) ?? const []).asMap().entries)
                  if ((e.value as int) > 0) e.key: e.value as int,
              },
            ),
        ],
      );
    } catch (_) {
      return null;
    }
  }
}

/// Einstellungen, die eine Spielgruppe meist beibehält. Werden beim nächsten neuen Spiel
/// übernommen. Spielstand, Farben und Commander gehören bewusst nicht dazu.
class MtgSetup {
  final int playerCount;
  final int layoutIndex;
  final int startLife;
  final bool turnTimerEnabled;
  final bool missedTriggersEnabled;

  const MtgSetup({
    required this.playerCount,
    required this.layoutIndex,
    required this.startLife,
    required this.turnTimerEnabled,
    required this.missedTriggersEnabled,
  });

  factory MtgSetup.of(MtgGame game) => MtgSetup(
        playerCount: game.playerCount,
        layoutIndex: game.layoutIndex,
        startLife: game.startLife,
        turnTimerEnabled: game.turnTimerEnabled,
        missedTriggersEnabled: game.missedTriggersEnabled,
      );

  MtgGame createGame({required String Function(int) defaultName}) {
    final game = MtgGame.create(
      playerCount: playerCount,
      startLife: startLife,
      defaultName: defaultName,
      turnTimerEnabled: turnTimerEnabled,
      missedTriggersEnabled: missedTriggersEnabled,
    );
    game.layoutIndex = layoutIndex;
    return game;
  }

  Map<String, dynamic> toJson() => {
        'players': playerCount,
        'layout': layoutIndex,
        'startLife': startLife,
        'turnTimer': turnTimerEnabled,
        'missedTriggers': missedTriggersEnabled,
      };

  static MtgSetup? fromJson(Object? json) {
    if (json is! Map) return null;
    final players = json['players'];
    if (players is! int || players < 2 || players > 6) return null;
    return MtgSetup(
      playerCount: players,
      layoutIndex: json['layout'] as int? ?? 0,
      startLife: json['startLife'] as int? ?? 40,
      turnTimerEnabled: json['turnTimer'] as bool? ?? false,
      missedTriggersEnabled: json['missedTriggers'] as bool? ?? false,
    );
  }
}

class MtgSetupStore {
  static const _key = 'mtg_last_setup';

  static Future<MtgSetup?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return MtgSetup.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(MtgSetup setup) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(setup.toJson()));
  }
}
