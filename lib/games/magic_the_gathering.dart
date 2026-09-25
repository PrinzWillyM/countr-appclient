import 'dart:async';
import 'dart:math';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/game_persistence.dart';
import 'mtg/mtg_commander_art.dart';
import 'mtg/mtg_commander_search.dart';
import 'mtg/mtg_i18n.dart';
import 'mtg/mtg_layouts.dart';
import 'mtg/mtg_model.dart';
import 'mtg/mtg_panels.dart';
import 'mtg/mtg_tile.dart';

class MagicTheGatheringGame extends StatefulWidget {
  final Color? themeColor;
  final bool resume;

  const MagicTheGatheringGame({super.key, this.themeColor, this.resume = false});

  @override
  State<MagicTheGatheringGame> createState() => _MagicTheGatheringGameState();
}

class _MagicTheGatheringGameState extends State<MagicTheGatheringGame> {
  static const String gameId = 'game_title_mtg';
  static const Duration _rollAnimation = Duration(seconds: 1);

  Color get accent => widget.themeColor ?? const Color(0xFFEBCB63);

  final _random = Random();

  // Commander ist der häufigste Anwendungsfall: 4 Spieler, 40 Leben
  late MtgGame game = MtgGame.create(playerCount: 4, startLife: 40, defaultName: _defaultName);

  // Kurz eingeblendete Summe der letzten Lebensänderungen je Spieler ("-3")
  final Map<int, int> _deltas = {};
  final Map<int, Timer> _deltaTimers = {};

  // Offener Commander-Schaden-Stepper: Ziel-Spieler und Quelle
  ({int target, int source})? _commanderEdit;

  // "Wer beginnt?": jeder Spieler würfelt selbst. Leer = nicht aktiv.
  final Map<int, MtgRollPhase> _rollPhase = {};
  final Map<int, int> _rollValue = {};
  Set<int> _rollContenders = {};
  bool _rollTie = false;
  int? _rollWinner;
  final List<Timer> _rollTimers = [];

  // Zug-Timer: Start des aktuellen Zuges (nicht gespeichert, beim Fortsetzen startet die Uhr neu)
  DateTime _turnStartedAt = clock.now();
  Timer? _ticker;

  bool _menuOpen = false;

  // Commander-Artwork: zuletzt gewählte Bilder (SharedPreferences) und Scryfall-Suche
  List<MtgCommanderArt> _recentArts = [];
  final ScryfallClient _scryfall = ScryfallClient();

  static String _defaultName(int i) => '${mtgT('player')} ${i + 1}';

  MtgLayout get _layout => mtgLayoutFor(game.playerCount, game.layoutIndex);

  // Bis Spielstand bzw. letztes Setup geladen sind, bleibt der Bildschirm schwarz (kein Aufblitzen)
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (widget.resume) {
      _load();
    } else {
      _startFromLastSetup();
    }
    MtgRecentCommanders.load().then((arts) {
      if (mounted) setState(() => _recentArts = arts);
    });
  }

  // Neues Spiel: Runden spielen meist in derselben Gruppe mit denselben Einstellungen
  Future<void> _startFromLastSetup() async {
    final setup = await MtgSetupStore.load();
    if (!mounted) return;
    setState(() {
      if (setup != null) game = setup.createGame(defaultName: _defaultName);
      _ready = true;
    });
    _persist();
  }

  @override
  void dispose() {
    for (final t in _deltaTimers.values) {
      t.cancel();
    }
    for (final t in _rollTimers) {
      t.cancel();
    }
    _ticker?.cancel();
    _scryfall.close();
    super.dispose();
  }

  Future<void> _load() async {
    final saved = await GamePersistence.load(gameId);
    if (!mounted) return;
    final restored = saved == null ? null : MtgGame.fromJson(saved);
    if (restored == null || kMtgLayouts[restored.playerCount] == null) {
      await _startFromLastSetup();
      return;
    }
    setState(() {
      for (var i = 0; i < restored.players.length; i++) {
        if (restored.players[i].name.isEmpty) restored.players[i].name = _defaultName(i);
      }
      game = restored;
      _turnStartedAt = clock.now();
      _ready = true;
    });
    _syncTicker();
  }

  void _persist() {
    GamePersistence.save(gameId, game.toJson());
    // Einstellungen gleich mit merken, damit das nächste neue Spiel so startet
    MtgSetupStore.save(MtgSetup.of(game));
  }

  void _mutate(VoidCallback fn) {
    setState(fn);
    _persist();
  }

  // --- Leben & Commander-Schaden ---

  void _trackDelta(int index, int delta) {
    if (delta == 0) return;
    _deltas[index] = (_deltas[index] ?? 0) + delta;
    _deltaTimers[index]?.cancel();
    _deltaTimers[index] = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _deltas.remove(index));
    });
  }

  void _changeLife(int index, int delta) {
    _mutate(() {
      game.players[index].life += delta;
      _trackDelta(index, delta);
    });
  }

  void _changeCommander(int target, int source, int delta) {
    _mutate(() {
      final applied = game.players[target].changeCommanderDamage(source, delta);
      _trackDelta(target, -applied);
    });
  }

  // --- Zug-Timer ---

  // Die Uhr läuft nur, solange der Timer aktiv ist und jemand am Zug ist
  void _syncTicker() {
    final shouldRun = game.turnTimerEnabled && game.activePlayer != null;
    if (shouldRun && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!shouldRun) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _startTurns(int player) {
    _mutate(() {
      game.startTurns(player);
      _turnStartedAt = clock.now();
    });
    _syncTicker();
  }

  void _passTurn() {
    _mutate(() {
      game.passTurn(_layout.clockwiseOrder);
      _turnStartedAt = clock.now();
    });
  }

  String get _turnLabel {
    final elapsed = clock.now().difference(_turnStartedAt);
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '${mtgT('round')} ${game.round} · $minutes:$seconds';
  }

  // --- Wer beginnt? ---

  void _startHighRoll() {
    HapticFeedback.heavyImpact();
    _cancelRollTimers();
    setState(() {
      _menuOpen = false;
      _commanderEdit = null;
      _rollValue.clear();
      _rollWinner = null;
      _rollTie = false;
      _rollContenders = {for (var i = 0; i < game.playerCount; i++) i};
      _rollPhase
        ..clear()
        ..addAll({for (final i in _rollContenders) i: MtgRollPhase.ready});
    });
  }

  void _roll(int player) {
    if (_rollPhase[player] != MtgRollPhase.ready) return;
    setState(() => _rollPhase[player] = MtgRollPhase.rolling);
    _rollTimers.add(Timer(_rollAnimation, () {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _rollValue[player] = _random.nextInt(20) + 1;
        _rollPhase[player] = MtgRollPhase.result;
        _evaluateRolls();
      });
    }));
  }

  // Wenn alle, die noch im Rennen sind, gewürfelt haben: Sieger bestimmen oder bei
  // Gleichstand nur die Gleichstehenden nochmal würfeln lassen.
  void _evaluateRolls() {
    if (_rollContenders.any((p) => _rollPhase[p] != MtgRollPhase.result)) return;
    final best = _rollContenders.map((p) => _rollValue[p]!).reduce(max);
    final top = _rollContenders.where((p) => _rollValue[p] == best).toSet();
    if (top.length > 1) {
      _rollContenders = top;
      _rollTie = true;
      for (final p in top) {
        _rollPhase[p] = MtgRollPhase.ready;
      }
      return;
    }
    _rollWinner = top.first;
    if (game.turnTimerEnabled) {
      game.startTurns(_rollWinner!);
      _turnStartedAt = clock.now();
      _persist();
      _syncTicker();
    }
  }

  void _dismissHighRoll() {
    _cancelRollTimers();
    setState(() {
      _rollPhase.clear();
      _rollValue.clear();
      _rollContenders = {};
      _rollWinner = null;
      _rollTie = false;
    });
  }

  void _cancelRollTimers() {
    for (final t in _rollTimers) {
      t.cancel();
    }
    _rollTimers.clear();
  }

  MtgRollState? _rollStateFor(int player) {
    final phase = _rollPhase[player];
    if (phase == null) return null;
    return MtgRollState(
      phase: phase,
      value: _rollValue[player],
      decided: _rollWinner != null,
      isWinner: _rollWinner == player,
      isTieReroll: _rollTie && _rollContenders.contains(player),
    );
  }

  // --- Menü & Einstellungen ---

  void _closeMenu() => setState(() => _menuOpen = false);

  void _clearTransient() {
    _commanderEdit = null;
    _cancelRollTimers();
    _rollPhase.clear();
    _rollValue.clear();
    _rollWinner = null;
    _deltas.clear();
    for (final t in _deltaTimers.values) {
      t.cancel();
    }
    _deltaTimers.clear();
  }

  void _restart() {
    HapticFeedback.mediumImpact();
    _mutate(() {
      _clearTransient();
      game.restart();
      _menuOpen = false;
    });
    _syncTicker();
  }

  void _setPlayerCount(int count) {
    if (count == game.playerCount) return;
    _mutate(() {
      _clearTransient();
      game = MtgGame.create(
        playerCount: count,
        startLife: game.startLife,
        defaultName: _defaultName,
        keep: game.players,
        turnTimerEnabled: game.turnTimerEnabled,
        missedTriggersEnabled: game.missedTriggersEnabled,
      );
    });
    _syncTicker();
  }

  void _setStartLife(int life) {
    _mutate(() {
      _clearTransient();
      game.startLife = life;
      game.restart();
    });
    _syncTicker();
  }

  void _setTurnTimer(bool enabled) {
    _mutate(() {
      game.turnTimerEnabled = enabled;
      if (!enabled) game.resetTurns();
    });
    _syncTicker();
  }

  void _openPlayerSheet(int index) {
    setState(() => _commanderEdit = null);
    showMtgPlayerSheet(
      context: context,
      game: () => game,
      index: index,
      accent: accent,
      mutate: _mutate,
      changeCommander: _changeCommander,
      recents: () => _recentArts,
      setArt: (art) => _setArt(index, art),
      searchArt: () => showMtgCommanderSearch(context, client: _scryfall, recents: _recentArts, accent: accent),
    );
  }

  Future<void> _setArt(int index, MtgCommanderArt? art) async {
    _mutate(() => game.players[index].art = art);
    if (art == null) return;
    final recents = await MtgRecentCommanders.add(_recentArts, art);
    if (mounted) setState(() => _recentArts = recents);
  }

  void _openSettings() {
    _closeMenu();
    showMtgSetupSheet(
      context: context,
      game: () => game,
      accent: accent,
      onPlayerCount: _setPlayerCount,
      onLayout: (i) => _mutate(() => game.layoutIndex = i),
      onStartLife: _setStartLife,
      onTurnTimer: _setTurnTimer,
      onMissedTriggers: (v) => _mutate(() => game.missedTriggersEnabled = v),
    );
  }

  void _showHelp() {
    _closeMenu();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kMtgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: accent)),
        title: Text(mtgT('rules_title'), style: TextStyle(color: accent)),
        content: SingleChildScrollView(child: Text(mtgT('rules_text'), style: const TextStyle(color: Colors.white70, height: 1.5))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(mtgT('ok'), style: TextStyle(color: accent)))],
      ),
    );
  }

  // Reihenfolge nach Häufigkeit während eines Spielabends
  List<MtgMenuItem> get _menuItems => [
        MtgMenuItem(key: 'high_roll', icon: Icons.emoji_events, label: mtgT('high_roll'), color: kMtgPlayerColors[6], onTap: _startHighRoll),
        MtgMenuItem(
            key: 'dice',
            icon: Icons.casino,
            label: mtgT('dice'),
            color: kMtgPlayerColors[7],
            onTap: () {
              _closeMenu();
              showMtgDiceDialog(context, accent);
            }),
        MtgMenuItem(key: 'settings', icon: Icons.settings, label: mtgT('settings'), color: kMtgPlayerColors[4], onTap: _openSettings),
        MtgMenuItem(key: 'restart', icon: Icons.refresh, label: mtgT('restart'), color: kMtgPlayerColors[0], onTap: _restart),
        MtgMenuItem(key: 'help', icon: Icons.help_outline, label: mtgT('help'), color: kMtgPlayerColors[3], onTap: _showHelp),
        MtgMenuItem(key: 'exit', icon: Icons.logout, label: mtgT('exit'), color: Colors.white, onTap: () => Navigator.of(context).maybePop()),
      ];

  Widget _buildTile(int index) {
    final edit = _commanderEdit;
    final timerOn = game.turnTimerEnabled;
    final isActive = timerOn && game.activePlayer == index;
    return MtgPlayerTile(
      key: ValueKey('mtg_tile_$index'),
      index: index,
      players: game.players,
      recentDelta: _deltas[index],
      commanderEditSource: edit != null && edit.target == index ? edit.source : null,
      roll: _rollStateFor(index),
      missedTriggersEnabled: game.missedTriggersEnabled,
      isActiveTurn: isActive,
      turnLabel: isActive ? _turnLabel : null,
      showStartTurn: timerOn && game.activePlayer == null,
      menuAnchor: _layout.menuAnchorInSeat(index),
      onLifeChange: (d) => _changeLife(index, d),
      onOpenSheet: () => _openPlayerSheet(index),
      onCommanderDrop: (source) => setState(() => _commanderEdit = (target: index, source: source)),
      onCommanderChange: (source, d) => _changeCommander(index, source, d),
      onOpenCommanderEdit: (source) => setState(() => _commanderEdit = (target: index, source: source)),
      onCloseCommanderEdit: () => setState(() => _commanderEdit = null),
      onTaxChange: (d) => _mutate(() => game.players[index].changeCounter(MtgCounter.tax, d)),
      onMissedTriggerChange: (d) => _mutate(() {
        final p = game.players[index];
        p.missedTriggersUsed = (p.missedTriggersUsed + d).clamp(0, kMissedTriggersPerGame);
      }),
      onRoll: () => _roll(index),
      onDismissRoll: _dismissHighRoll,
      onPassTurn: _passTurn,
      onStartTurn: () => _startTurns(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Scaffold(backgroundColor: Colors.black);
    return PopScope(
      // Zurück-Geste schliesst zuerst das Menü bzw. bricht "Wer beginnt?" ab
      canPop: !_menuOpen && _rollPhase.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_rollPhase.isNotEmpty) {
          _dismissHighRoll();
        } else {
          _closeMenu();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: LayoutBuilder(builder: (context, box) {
              const pad = 6.0, gap = 6.0;
              // Menü-Knopf auf der Kachelgrenze nahe der Mitte (nie mitten auf einer Lebensanzeige)
              final anchor = _layout.menuAnchorPixels(Size(box.maxWidth - 2 * pad, box.maxHeight - 2 * pad), gap) + const Offset(pad, pad);
              const buttonSize = MtgCenterButton.size;
              return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(pad),
                  child: MtgLayoutGrid(
                    layout: _layout,
                    gap: gap,
                    seatBuilder: (index, _) => _buildTile(index),
                  ),
                ),
                if (_menuOpen) Positioned.fill(child: MtgFloatingMenu(items: _menuItems, onClose: _closeMenu)),
                // Bei offenem Menü übernimmt dessen eigener ✕-Knopf
                if (!_menuOpen) Positioned(
                  left: anchor.dx - buttonSize / 2,
                  top: anchor.dy - buttonSize / 2,
                  child: MtgCenterButton(
                    // Während "Wer beginnt?" läuft, bricht der Knopf das Würfeln ab
                    open: _menuOpen || _rollPhase.isNotEmpty,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (_rollPhase.isNotEmpty) {
                        _dismissHighRoll();
                        return;
                      }
                      setState(() {
                        _menuOpen = !_menuOpen;
                        _commanderEdit = null;
                      });
                    },
                  ),
                ),
              ],
            );
            }),
          ),
        ),
      ),
    );
  }
}
