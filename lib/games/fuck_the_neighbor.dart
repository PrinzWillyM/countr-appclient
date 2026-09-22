import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/game_persistence.dart';

// --- DATENSTRUKTUREN ---

class Player {
  String name;
  int totalScore;

  Player({required this.name, this.totalScore = 0});

  Map<String, dynamic> toJson() => {'name': name, 'totalScore': totalScore};

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        name: json['name'] as String,
        totalScore: json['totalScore'] as int,
      );
}

class RoundData {
  int roundNumber;
  int cardCount;
  int dealerIndex;
  bool isCompleted;
  bool isLocked;

  Map<String, int> bids;
  Map<String, int> tricks;
  Map<String, int> roundPoints;

  RoundData({
    required this.roundNumber,
    required this.cardCount,
    required this.dealerIndex,
    this.isCompleted = false,
    this.isLocked = true,
  }) : bids = {}, tricks = {}, roundPoints = {};

  Map<String, dynamic> toJson() => {
        'roundNumber': roundNumber,
        'cardCount': cardCount,
        'dealerIndex': dealerIndex,
        'isCompleted': isCompleted,
        'isLocked': isLocked,
        'bids': bids,
        'tricks': tricks,
        'roundPoints': roundPoints,
      };

  factory RoundData.fromJson(Map<String, dynamic> json) {
    final round = RoundData(
      roundNumber: json['roundNumber'] as int,
      cardCount: json['cardCount'] as int,
      dealerIndex: json['dealerIndex'] as int,
      isCompleted: json['isCompleted'] as bool,
      isLocked: json['isLocked'] as bool,
    );
    round.bids = Map<String, int>.from(json['bids'] as Map);
    round.tricks = Map<String, int>.from(json['tricks'] as Map);
    round.roundPoints = Map<String, int>.from(json['roundPoints'] as Map);
    return round;
  }
}

// --- WIDGET ---

class FuckTheNeighborGame extends StatefulWidget {
  final Color? themeColor;
  final bool resume;

  const FuckTheNeighborGame({super.key, this.themeColor, this.resume = false});

  @override
  State<FuckTheNeighborGame> createState() => _FuckTheNeighborGameState();
}

class _FuckTheNeighborGameState extends State<FuckTheNeighborGame> {
  static const String gameId = 'game_title_ftn';

  // --- FARBEN & STYLE ---
  Color get primaryColor => widget.themeColor ?? const Color(0xFFEBCB63); // Brand Yellow
  final Color bgColor = const Color(0xFF222629);
  final Color surfaceColor = const Color(0xFF30363B);
  final Color cardColor = const Color(0xFF3A4146);
  final Color errorColor = const Color(0xFFEB6B6B);
  final Color successColor = const Color(0xFF4CBF98);

  // --- STATE ---
  // Sprache: immer live vom globalen App-Status gelesen (reaktiv auf Sprachwechsel)
  String get _currentLang => appLocaleNotifier.value.languageCode;
  bool _gameStarted = false;
  bool _gameFinished = false;
  int _deckSize = 36; // 36 (1 Deck) oder 72 (2 Decks)
  bool _useMultiplier = false; // Strafpunkte x Rundennummer
  List<Player> _players = [];
  List<RoundData> _rounds = [];

  final TextEditingController _nameController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Für vertikales Scrollen

  @override
  void initState() {
    super.initState();
    if (widget.resume) _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final saved = await GamePersistence.load(gameId);
    if (saved == null || !mounted) return;
    setState(() {
      _gameStarted = saved['gameStarted'] as bool? ?? false;
      _gameFinished = saved['gameFinished'] as bool? ?? false;
      _deckSize = saved['deckSize'] as int? ?? _deckSize;
      _useMultiplier = saved['useMultiplier'] as bool? ?? false;
      _players = ((saved['players'] as List<dynamic>?) ?? [])
          .map((p) => Player.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
      _rounds = ((saved['rounds'] as List<dynamic>?) ?? [])
          .map((r) => RoundData.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    });
  }

  void _persist() {
    GamePersistence.save(gameId, {
      'gameStarted': _gameStarted,
      'gameFinished': _gameFinished,
      'deckSize': _deckSize,
      'useMultiplier': _useMultiplier,
      'players': _players.map((p) => p.toJson()).toList(),
      'rounds': _rounds.map((r) => r.toJson()).toList(),
    });
  }

  // --- ÜBERSETZUNG ---
  String _t(String key) {
    const Map<String, Map<String, String>> dictionary = {
      'de': {
        'title': 'Fuck the Neighbor', 'add_hint': 'Spieler Name', 'add_err': 'Maximal 12 Spieler!', 'add_err_min': 'Mindestens 3 Spieler!',
        'start': 'SPIEL STARTEN', 'rules': 'Spielanleitung', 'ok': 'VERSTANDEN',
        'round': 'R', 'score_board': 'Score Board', 'winner': 'GEWINNER', 'penalty': 'Strafpunkte',
        'rematch': 'REVANCHE (Rotation)', 'new_game': 'Neues Spiel (Setup)',
        'phase1': 'ANSAGEN MACHEN', 'phase2': 'STICHE VERTEILEN',
        'starts': 'Fängt an', 'bid_info': 'Ansage', 'forbidden': 'Nicht', 'called': 'Angesagt',
        'tricks_left': 'Noch zu verteilen: ', 'btn_p1': 'WEITER ZU DEN STICHEN', 'btn_p2': 'RUNDE ABSCHLIESSEN', 'btn_err': 'STICHE AUFGEHEN LASSEN',
        'err_dealer': 'GEBER-REGEL: Summe darf nicht aufgehen!',
        'deck_size': 'Kartendeck', 'deck_1': '1 Deck (36)', 'deck_2': '2 Decks (72)',
        'multiplier_opt': 'Steigender Multiplikator', 'multiplier_desc': 'Strafpunkte × Rundennummer (R1=×1, R3=×3, ...)',
        'shuffles': 'Mischt & gibt', 'deals_short': 'Geber',
        'lbl_players': 'Spieler', 'lbl_material': 'Material', 'lbl_goal': 'Ziel',
        'r_options': 'Optionen', 'r_options_txt': 'Im Setup lässt sich mit 2 Kartendecks (72 Karten) spielen sowie ein steigender Multiplikator aktivieren, der Strafpunkte mit der Rundennummer vervielfacht. Wer mischt/gibt wird bei jeder Runde angezeigt.',
        'r_overview': 'ÜBERSICHT', 'r_players': '3 bis 12 Personen', 'r_material': 'Jasskarten (36 oder 72 mit 2 Decks)', 'r_goal': '0 Punkte erreichen. (Differenz = Strafpunkte)',
        'r_flow': 'ABLAUF', 'r_s1': 'Karten verteilen (R1 = Max, dann -1).', 'r_s2': 'Ansagen machen.', 'r_s3': 'Spielen (Höchste Karte sticht).', 'r_s4': 'Abrechnung (|Ansage - Stich|).',
        'r_rules': 'REGELN', 'r_dealer': 'Geber-Regel', 'r_dealer_txt': 'Summe Ansagen ≠ Anzahl Karten!', 'r_block': 'Blockieren', 'r_block_txt': 'Gleiche höchste Karten blockieren sich.', 'r_final': 'Finale', 'r_final_txt': 'Letzte Karte an die Stirn (Blind)!'
      },
      'en': {
        'title': 'Fuck the Neighbor', 'add_hint': 'Player Name', 'add_err': 'Max 12 players!', 'add_err_min': 'Min 3 players!',
        'start': 'START GAME', 'rules': 'How to Play', 'ok': 'GOT IT',
        'round': 'R', 'score_board': 'Score Board', 'winner': 'WINNER', 'penalty': 'Penalty Points',
        'rematch': 'REMATCH (Rotate)', 'new_game': 'New Game (Setup)',
        'phase1': 'MAKE BIDS', 'phase2': 'ENTER TRICKS',
        'starts': 'Starts', 'bid_info': 'Bid', 'forbidden': 'Not', 'called': 'Called',
        'tricks_left': 'Remaining tricks: ', 'btn_p1': 'CONTINUE TO TRICKS', 'btn_p2': 'FINISH ROUND', 'btn_err': 'TRICKS MUST MATCH',
        'err_dealer': 'DEALER RULE: Sum of bids cannot equal cards!',
        'deck_size': 'Card Deck', 'deck_1': '1 Deck (36)', 'deck_2': '2 Decks (72)',
        'multiplier_opt': 'Escalating Multiplier', 'multiplier_desc': 'Penalty × round number (R1=×1, R3=×3, ...)',
        'shuffles': 'Shuffles & deals', 'deals_short': 'Dealer',
        'lbl_players': 'Players', 'lbl_material': 'Material', 'lbl_goal': 'Goal',
        'r_options': 'Options', 'r_options_txt': 'In setup you can play with 2 card decks (72 cards) and enable an escalating multiplier that multiplies penalty points by the round number. Who shuffles/deals is shown for every round.',
        'r_overview': 'OVERVIEW', 'r_players': '3 to 12 players', 'r_material': '36 cards (or 72 with 2 decks)', 'r_goal': 'Reach 0 points. (Difference = Penalty)',
        'r_flow': 'FLOW', 'r_s1': 'Deal cards (R1 = Max, then -1).', 'r_s2': 'Make bids.', 'r_s3': 'Play (Highest card wins trick).', 'r_s4': 'Score (|Bid - Tricks|).',
        'r_rules': 'RULES', 'r_dealer': 'Dealer Rule', 'r_dealer_txt': 'Sum of bids ≠ Card count!', 'r_block': 'Blocking', 'r_block_txt': 'Equal highest cards block each other.', 'r_final': 'Finale', 'r_final_txt': 'Last card on forehead (Blind)!'
      },
      // Kurzversionen für den Rest (Fallback auf Englisch bei fehlenden Keys im Code unten)
      'fr': { 'title': 'Fuck the Neighbor', 'add_hint': 'Nom', 'add_err': 'Maximum 12 joueurs !', 'add_err_min': 'Minimum 3 joueurs !', 'start': 'DÉMARRER', 'rules': 'Règles', 'ok': 'COMPRIS', 'round': 'R', 'score_board': 'Tableau des scores', 'winner': 'VAINQUEUR', 'penalty': 'Points de pénalité', 'rematch': 'REVANCHE', 'new_game': 'Nouvelle partie (config)', 'phase1': 'ANNONCES', 'phase2': 'PLIS', 'starts': 'Commence', 'bid_info': 'Annonce', 'forbidden': 'Pas', 'called': 'Annoncé', 'tricks_left': 'Plis restants : ', 'btn_p1': 'SUIVANT', 'btn_p2': 'TERMINER', 'btn_err': 'LES PLIS DOIVENT CORRESPONDRE', 'err_dealer': 'RÈGLE DU DONNEUR : La somme ne doit pas correspondre !', 'deck_size': 'Jeu de cartes', 'deck_1': '1 jeu (36)', 'deck_2': '2 jeux (72)', 'multiplier_opt': 'Multiplicateur croissant', 'multiplier_desc': 'Pénalité × numéro de manche (R1=×1, R3=×3, ...)', 'shuffles': 'Mélange & donne', 'deals_short': 'Donneur', 'lbl_players': 'Joueurs', 'lbl_material': 'Matériel', 'lbl_goal': 'Objectif', 'r_options': 'Options', 'r_options_txt': 'Dans la configuration, vous pouvez jouer avec 2 jeux de cartes (72 cartes) et activer un multiplicateur croissant qui multiplie les points de pénalité par le numéro de manche. Qui mélange/donne est indiqué à chaque manche.', 'r_overview': 'APERÇU', 'r_players': '3 à 12 joueurs', 'r_material': '36 cartes (ou 72 avec 2 jeux)', 'r_goal': 'Atteindre 0 point. (Différence = Pénalité)', 'r_flow': 'DÉROULEMENT', 'r_s1': 'Distribuer les cartes (R1 = Max, puis -1).', 'r_s2': 'Faire les annonces.', 'r_s3': 'Jouer (la carte la plus haute remporte le pli).', 'r_s4': 'Calcul (|Annonce - Plis|).', 'r_rules': 'RÈGLES', 'r_dealer': 'Règle du donneur', 'r_dealer_txt': 'La somme des annonces ≠ nombre de cartes !', 'r_block': 'Blocage', 'r_block_txt': 'Les cartes les plus hautes égales se bloquent entre elles.', 'r_final': 'Finale', 'r_final_txt': 'Dernière carte sur le front (à l\'aveugle) !' },
      'it': { 'title': 'Fuck the Neighbor', 'add_hint': 'Nome', 'add_err': 'Massimo 12 giocatori!', 'add_err_min': 'Minimo 3 giocatori!', 'start': 'AVVIA', 'rules': 'Regole', 'ok': 'CAPITO', 'round': 'R', 'score_board': 'Tabellone', 'winner': 'VINCITORE', 'penalty': 'Punti penalità', 'rematch': 'RIVINCITA', 'new_game': 'Nuova partita (Setup)', 'phase1': 'DICHIARAZIONI', 'phase2': 'PRESE', 'starts': 'Inizia', 'bid_info': 'Dichiar.', 'forbidden': 'Non', 'called': 'Dichiarato', 'tricks_left': 'Prese rimanenti: ', 'btn_p1': 'AVANTI', 'btn_p2': 'FINE', 'btn_err': 'LE PRESE DEVONO CORRISPONDERE', 'err_dealer': 'REGOLA DEL MAZZIERE: La somma non deve corrispondere!', 'deck_size': 'Mazzo di carte', 'deck_1': '1 mazzo (36)', 'deck_2': '2 mazzi (72)', 'multiplier_opt': 'Moltiplicatore crescente', 'multiplier_desc': 'Penalità × numero di round (R1=×1, R3=×3, ...)', 'shuffles': 'Mescola e distribuisce', 'deals_short': 'Mazziere', 'lbl_players': 'Giocatori', 'lbl_material': 'Materiale', 'lbl_goal': 'Obiettivo', 'r_options': 'Opzioni', 'r_options_txt': 'Nel setup puoi giocare con 2 mazzi di carte (72 carte) e attivare un moltiplicatore crescente che moltiplica i punti penalità per il numero del round. Chi mescola/distribuisce è mostrato ad ogni round.', 'r_overview': 'PANORAMICA', 'r_players': 'Da 3 a 12 persone', 'r_material': 'Carte da Jass (36 o 72 con 2 mazzi)', 'r_goal': 'Raggiungere 0 punti. (Differenza = Penalità)', 'r_flow': 'SVOLGIMENTO', 'r_s1': 'Distribuire le carte (R1 = Max, poi -1).', 'r_s2': 'Fare le dichiarazioni.', 'r_s3': 'Giocare (la carta più alta vince la presa).', 'r_s4': 'Conteggio (|Dichiarazione - Prese|).', 'r_rules': 'REGOLE', 'r_dealer': 'Regola del mazziere', 'r_dealer_txt': 'Somma delle dichiarazioni ≠ numero di carte!', 'r_block': 'Blocco', 'r_block_txt': 'Carte più alte uguali si bloccano a vicenda.', 'r_final': 'Finale', 'r_final_txt': 'Ultima carta sulla fronte (alla cieca)!' },
      'es': { 'title': 'Fuck the Neighbor', 'add_hint': 'Nombre', 'add_err': '¡Máximo 12 jugadores!', 'add_err_min': '¡Mínimo 3 jugadores!', 'start': 'INICIAR', 'rules': 'Reglas', 'ok': 'ENTENDIDO', 'round': 'R', 'score_board': 'Marcador', 'winner': 'GANADOR', 'penalty': 'Puntos de penalización', 'rematch': 'REVANCHA', 'new_game': 'Nueva partida (Config)', 'phase1': 'APUESTAS', 'phase2': 'BAZAS', 'starts': 'Empieza', 'bid_info': 'Apuesta', 'forbidden': 'No', 'called': 'Anunciado', 'tricks_left': 'Bazas restantes: ', 'btn_p1': 'SIGUIENTE', 'btn_p2': 'TERMINAR', 'btn_err': 'LAS BAZAS DEBEN COINCIDIR', 'err_dealer': 'REGLA DEL REPARTIDOR: ¡La suma no puede coincidir!', 'deck_size': 'Baraja', 'deck_1': '1 baraja (36)', 'deck_2': '2 barajas (72)', 'multiplier_opt': 'Multiplicador creciente', 'multiplier_desc': 'Penalización × número de ronda (R1=×1, R3=×3, ...)', 'shuffles': 'Baraja y reparte', 'deals_short': 'Repartidor', 'lbl_players': 'Jugadores', 'lbl_material': 'Material', 'lbl_goal': 'Objetivo', 'r_options': 'Opciones', 'r_options_txt': 'En la configuración puedes jugar con 2 barajas (72 cartas) y activar un multiplicador creciente que multiplica los puntos de penalización por el número de ronda. Quién baraja/reparte se muestra en cada ronda.', 'r_overview': 'RESUMEN', 'r_players': 'De 3 a 12 personas', 'r_material': 'Cartas de Jass (36 o 72 con 2 barajas)', 'r_goal': 'Llegar a 0 puntos. (Diferencia = Penalización)', 'r_flow': 'DESARROLLO', 'r_s1': 'Repartir cartas (R1 = Máx, luego -1).', 'r_s2': 'Hacer las apuestas.', 'r_s3': 'Jugar (la carta más alta gana la baza).', 'r_s4': 'Cálculo (|Apuesta - Bazas|).', 'r_rules': 'REGLAS', 'r_dealer': 'Regla del repartidor', 'r_dealer_txt': '¡Suma de apuestas ≠ número de cartas!', 'r_block': 'Bloqueo', 'r_block_txt': 'Cartas más altas iguales se bloquean entre sí.', 'r_final': 'Final', 'r_final_txt': '¡Última carta en la frente (a ciegas)!' },
      'pt': { 'title': 'Fuck the Neighbor', 'add_hint': 'Nome', 'add_err': 'Máximo 12 jogadores!', 'add_err_min': 'Mínimo 3 jogadores!', 'start': 'INICIAR', 'rules': 'Regras', 'ok': 'ENTENDIDO', 'round': 'R', 'score_board': 'Placar', 'winner': 'VENCEDOR', 'penalty': 'Pontos de penalidade', 'rematch': 'REVANCHE', 'new_game': 'Novo jogo (Config)', 'phase1': 'APOSTAS', 'phase2': 'VAZAS', 'starts': 'Começa', 'bid_info': 'Aposta', 'forbidden': 'Não', 'called': 'Anunciado', 'tricks_left': 'Vazas restantes: ', 'btn_p1': 'PRÓXIMO', 'btn_p2': 'TERMINAR', 'btn_err': 'AS VAZAS DEVEM CORRESPONDER', 'err_dealer': 'REGRA DO DISTRIBUIDOR: A soma não pode corresponder!', 'deck_size': 'Baralho', 'deck_1': '1 baralho (36)', 'deck_2': '2 baralhos (72)', 'multiplier_opt': 'Multiplicador crescente', 'multiplier_desc': 'Penalidade × número da rodada (R1=×1, R3=×3, ...)', 'shuffles': 'Embaralha e distribui', 'deals_short': 'Distribuidor', 'lbl_players': 'Jogadores', 'lbl_material': 'Material', 'lbl_goal': 'Objetivo', 'r_options': 'Opções', 'r_options_txt': 'Na configuração você pode jogar com 2 baralhos (72 cartas) e ativar um multiplicador crescente que multiplica os pontos de penalidade pelo número da rodada. Quem embaralha/distribui é mostrado a cada rodada.', 'r_overview': 'VISÃO GERAL', 'r_players': '3 a 12 pessoas', 'r_material': 'Cartas de Jass (36 ou 72 com 2 baralhos)', 'r_goal': 'Chegar a 0 pontos. (Diferença = Penalidade)', 'r_flow': 'FLUXO', 'r_s1': 'Distribuir cartas (R1 = Máx, depois -1).', 'r_s2': 'Fazer as apostas.', 'r_s3': 'Jogar (a carta mais alta ganha a vaza).', 'r_s4': 'Cálculo (|Aposta - Vazas|).', 'r_rules': 'REGRAS', 'r_dealer': 'Regra do distribuidor', 'r_dealer_txt': 'Soma das apostas ≠ número de cartas!', 'r_block': 'Bloqueio', 'r_block_txt': 'Cartas mais altas iguais se bloqueiam.', 'r_final': 'Final', 'r_final_txt': 'Última carta na testa (às cegas)!' },
      'nl': { 'title': 'Fuck the Neighbor', 'add_hint': 'Naam', 'add_err': 'Maximaal 12 spelers!', 'add_err_min': 'Minimaal 3 spelers!', 'start': 'STARTEN', 'rules': 'Regels', 'ok': 'BEGREPEN', 'round': 'R', 'score_board': 'Scorebord', 'winner': 'WINNAAR', 'penalty': 'Strafpunten', 'rematch': 'REVANCHE', 'new_game': 'Nieuw spel (Setup)', 'phase1': 'BIEDEN', 'phase2': 'SLAGEN', 'starts': 'Begint', 'bid_info': 'Bod', 'forbidden': 'Niet', 'called': 'Aangekondigd', 'tricks_left': 'Nog te verdelen: ', 'btn_p1': 'VERDER', 'btn_p2': 'AFRONDEN', 'btn_err': 'SLAGEN MOETEN KLOPPEN', 'err_dealer': 'GEVER-REGEL: Som mag niet kloppen!', 'deck_size': 'Kaartspel', 'deck_1': '1 spel (36)', 'deck_2': '2 spellen (72)', 'multiplier_opt': 'Oplopende vermenigvuldiger', 'multiplier_desc': 'Strafpunten × rondenummer (R1=×1, R3=×3, ...)', 'shuffles': 'Schudt & deelt', 'deals_short': 'Gever', 'lbl_players': 'Spelers', 'lbl_material': 'Materiaal', 'lbl_goal': 'Doel', 'r_options': 'Opties', 'r_options_txt': 'In de setup kun je spelen met 2 kaartspellen (72 kaarten) en een oplopende vermenigvuldiger activeren die strafpunten vermenigvuldigt met het rondenummer. Wie schudt/deelt wordt elke ronde getoond.', 'r_overview': 'OVERZICHT', 'r_players': '3 tot 12 personen', 'r_material': 'Jaskaarten (36 of 72 met 2 spellen)', 'r_goal': '0 punten bereiken. (Verschil = Strafpunten)', 'r_flow': 'VERLOOP', 'r_s1': 'Kaarten delen (R1 = Max, dan -1).', 'r_s2': 'Biedingen maken.', 'r_s3': 'Spelen (Hoogste kaart wint slag).', 'r_s4': 'Afrekening (|Bod - Slagen|).', 'r_rules': 'REGELS', 'r_dealer': 'Gever-regel', 'r_dealer_txt': 'Som biedingen ≠ aantal kaarten!', 'r_block': 'Blokkeren', 'r_block_txt': 'Gelijke hoogste kaarten blokkeren elkaar.', 'r_final': 'Finale', 'r_final_txt': 'Laatste kaart op het voorhoofd (blind)!' },
      'pl': { 'title': 'Fuck the Neighbor', 'add_hint': 'Imię', 'add_err': 'Maksymalnie 12 graczy!', 'add_err_min': 'Minimum 3 graczy!', 'start': 'START', 'rules': 'Zasady', 'ok': 'ZROZUMIAŁEM', 'round': 'R', 'score_board': 'Tablica wyników', 'winner': 'ZWYCIĘZCA', 'penalty': 'Punkty karne', 'rematch': 'REWANŻ', 'new_game': 'Nowa gra (Ustawienia)', 'phase1': 'LICYTACJA', 'phase2': 'LEWY', 'starts': 'Zaczyna', 'bid_info': 'Dekl.', 'forbidden': 'Nie', 'called': 'Zadeklarowano', 'tricks_left': 'Pozostało do rozdania: ', 'btn_p1': 'DALEJ', 'btn_p2': 'ZAKOŃCZ', 'btn_err': 'LEWY MUSZĄ SIĘ ZGADZAĆ', 'err_dealer': 'ZASADA ROZDAJĄCEGO: Suma nie może się zgadzać!', 'deck_size': 'Talia kart', 'deck_1': '1 talia (36)', 'deck_2': '2 talie (72)', 'multiplier_opt': 'Rosnący mnożnik', 'multiplier_desc': 'Kara × numer rundy (R1=×1, R3=×3, ...)', 'shuffles': 'Tasuje i rozdaje', 'deals_short': 'Rozdający', 'lbl_players': 'Gracze', 'lbl_material': 'Materiał', 'lbl_goal': 'Cel', 'r_options': 'Opcje', 'r_options_txt': 'W ustawieniach można grać z 2 taliami kart (72 karty) oraz włączyć rosnący mnożnik, który mnoży punkty karne przez numer rundy. Kto tasuje/rozdaje jest pokazywane w każdej rundzie.', 'r_overview': 'PRZEGLĄD', 'r_players': 'Od 3 do 12 osób', 'r_material': 'Karty do Jassa (36 lub 72 z 2 taliami)', 'r_goal': 'Osiągnąć 0 punktów. (Różnica = Kara)', 'r_flow': 'PRZEBIEG', 'r_s1': 'Rozdanie kart (R1 = Maks, potem -1).', 'r_s2': 'Licytacja.', 'r_s3': 'Gra (Najwyższa karta bierze lewę).', 'r_s4': 'Rozliczenie (|Deklaracja - Lewy|).', 'r_rules': 'ZASADY', 'r_dealer': 'Zasada rozdającego', 'r_dealer_txt': 'Suma deklaracji ≠ liczba kart!', 'r_block': 'Blokowanie', 'r_block_txt': 'Równe najwyższe karty blokują się nawzajem.', 'r_final': 'Finał', 'r_final_txt': 'Ostatnia karta na czole (na ślepo)!' },
      'tr': { 'title': 'Fuck the Neighbor', 'add_hint': 'İsim', 'add_err': 'Maksimum 12 oyuncu!', 'add_err_min': 'Minimum 3 oyuncu!', 'start': 'BAŞLAT', 'rules': 'Kurallar', 'ok': 'ANLADIM', 'round': 'R', 'score_board': 'Skor Tablosu', 'winner': 'KAZANAN', 'penalty': 'Ceza Puanları', 'rematch': 'RÖVANŞ', 'new_game': 'Yeni Oyun (Kurulum)', 'phase1': 'TAHMİNLER', 'phase2': 'ELLER', 'starts': 'Başlar', 'bid_info': 'Tahmin', 'forbidden': 'Değil', 'called': 'Tahmin Edildi', 'tricks_left': 'Kalan el: ', 'btn_p1': 'İLERİ', 'btn_p2': 'BİTİR', 'btn_err': 'ELLER EŞLEŞMELİ', 'err_dealer': 'DAĞITICI KURALI: Toplam eşit olamaz!', 'deck_size': 'Kart Destesi', 'deck_1': '1 deste (36)', 'deck_2': '2 deste (72)', 'multiplier_opt': 'Artan Çarpan', 'multiplier_desc': 'Ceza × tur numarası (R1=×1, R3=×3, ...)', 'shuffles': 'Karıştırır ve dağıtır', 'deals_short': 'Dağıtıcı', 'lbl_players': 'Oyuncular', 'lbl_material': 'Malzeme', 'lbl_goal': 'Hedef', 'r_options': 'Seçenekler', 'r_options_txt': 'Kurulumda 2 kart destesiyle (72 kart) oynayabilir ve ceza puanlarını tur numarasıyla çarpan artan bir çarpanı etkinleştirebilirsiniz. Kimin karıştırıp dağıttığı her turda gösterilir.', 'r_overview': 'GENEL BAKIŞ', 'r_players': '3 ila 12 kişi', 'r_material': 'Jass kartları (36 veya 2 desteyle 72)', 'r_goal': '0 puana ulaşmak. (Fark = Ceza)', 'r_flow': 'AKIŞ', 'r_s1': 'Kartları dağıt (R1 = Maks, sonra -1).', 'r_s2': 'Tahminleri yap.', 'r_s3': 'Oyna (En yüksek kart eli alır).', 'r_s4': 'Hesaplama (|Tahmin - El|).', 'r_rules': 'KURALLAR', 'r_dealer': 'Dağıtıcı Kuralı', 'r_dealer_txt': 'Tahminlerin toplamı ≠ kart sayısı!', 'r_block': 'Engelleme', 'r_block_txt': 'Eşit en yüksek kartlar birbirini engeller.', 'r_final': 'Final', 'r_final_txt': 'Son kart alına (körlemesine)!' },
      'id': { 'title': 'Fuck the Neighbor', 'add_hint': 'Nama', 'add_err': 'Maksimal 12 pemain!', 'add_err_min': 'Minimal 3 pemain!', 'start': 'MULAI', 'rules': 'Aturan', 'ok': 'MENGERTI', 'round': 'R', 'score_board': 'Papan Skor', 'winner': 'PEMENANG', 'penalty': 'Poin Penalti', 'rematch': 'TANDING ULANG', 'new_game': 'Permainan Baru (Setup)', 'phase1': 'TEBAKAN', 'phase2': 'TRIK', 'starts': 'Mulai', 'bid_info': 'Tebakan', 'forbidden': 'Bukan', 'called': 'Ditebak', 'tricks_left': 'Sisa trik: ', 'btn_p1': 'LANJUT', 'btn_p2': 'SELESAI', 'btn_err': 'TRIK HARUS SESUAI', 'err_dealer': 'ATURAN PEMBAGI: Jumlah tidak boleh sesuai!', 'deck_size': 'Set Kartu', 'deck_1': '1 set (36)', 'deck_2': '2 set (72)', 'multiplier_opt': 'Pengali Meningkat', 'multiplier_desc': 'Penalti × nomor ronde (R1=×1, R3=×3, ...)', 'shuffles': 'Mengocok & membagikan', 'deals_short': 'Pembagi', 'lbl_players': 'Pemain', 'lbl_material': 'Bahan', 'lbl_goal': 'Tujuan', 'r_options': 'Opsi', 'r_options_txt': 'Di pengaturan Anda dapat bermain dengan 2 set kartu (72 kartu) dan mengaktifkan pengali meningkat yang mengalikan poin penalti dengan nomor ronde. Siapa yang mengocok/membagikan ditampilkan setiap ronde.', 'r_overview': 'RINGKASAN', 'r_players': '3 sampai 12 orang', 'r_material': 'Kartu Jass (36 atau 72 dengan 2 set)', 'r_goal': 'Mencapai 0 poin. (Selisih = Penalti)', 'r_flow': 'ALUR', 'r_s1': 'Bagikan kartu (R1 = Maks, lalu -1).', 'r_s2': 'Buat tebakan.', 'r_s3': 'Bermain (Kartu tertinggi menang trik).', 'r_s4': 'Perhitungan (|Tebakan - Trik|).', 'r_rules': 'ATURAN', 'r_dealer': 'Aturan Pembagi', 'r_dealer_txt': 'Jumlah tebakan ≠ jumlah kartu!', 'r_block': 'Memblokir', 'r_block_txt': 'Kartu tertinggi yang sama saling memblokir.', 'r_final': 'Final', 'r_final_txt': 'Kartu terakhir di dahi (buta)!' },
      'sv': { 'title': 'Fuck the Neighbor', 'add_hint': 'Namn', 'add_err': 'Max 12 spelare!', 'add_err_min': 'Minst 3 spelare!', 'start': 'STARTA', 'rules': 'Regler', 'ok': 'FÖRSTÅTT', 'round': 'R', 'score_board': 'Poängtavla', 'winner': 'VINNARE', 'penalty': 'Straffpoäng', 'rematch': 'REVANSCH', 'new_game': 'Nytt spel (Inställningar)', 'phase1': 'BUD', 'phase2': 'STICK', 'starts': 'Börjar', 'bid_info': 'Bud', 'forbidden': 'Inte', 'called': 'Bud', 'tricks_left': 'Kvar att fördela: ', 'btn_p1': 'NÄSTA', 'btn_p2': 'AVSLUTA', 'btn_err': 'STICK MÅSTE STÄMMA', 'err_dealer': 'GIVARREGEL: Summan får inte stämma!', 'deck_size': 'Kortlek', 'deck_1': '1 lek (36)', 'deck_2': '2 lekar (72)', 'multiplier_opt': 'Stigande multiplikator', 'multiplier_desc': 'Straff × rundnummer (R1=×1, R3=×3, ...)', 'shuffles': 'Blandar & delar', 'deals_short': 'Givare', 'lbl_players': 'Spelare', 'lbl_material': 'Material', 'lbl_goal': 'Mål', 'r_options': 'Alternativ', 'r_options_txt': 'I inställningarna kan du spela med 2 kortlekar (72 kort) och aktivera en stigande multiplikator som multiplicerar straffpoäng med rundnumret. Vem som blandar/delar visas varje runda.', 'r_overview': 'ÖVERSIKT', 'r_players': '3 till 12 personer', 'r_material': 'Jasskort (36 eller 72 med 2 lekar)', 'r_goal': 'Nå 0 poäng. (Skillnad = Straff)', 'r_flow': 'FÖRLOPP', 'r_s1': 'Dela ut kort (R1 = Max, sedan -1).', 'r_s2': 'Gör bud.', 'r_s3': 'Spela (Högsta kortet tar sticket).', 'r_s4': 'Uträkning (|Bud - Stick|).', 'r_rules': 'REGLER', 'r_dealer': 'Givarregel', 'r_dealer_txt': 'Summan av buden ≠ antal kort!', 'r_block': 'Blockering', 'r_block_txt': 'Lika höga kort blockerar varandra.', 'r_final': 'Final', 'r_final_txt': 'Sista kortet på pannan (blint)!' },
      'hr': { 'title': 'Fuck the Neighbor', 'add_hint': 'Ime', 'add_err': 'Maksimalno 12 igrača!', 'add_err_min': 'Minimalno 3 igrača!', 'start': 'POKRENI', 'rules': 'Pravila', 'ok': 'RAZUMIJEM', 'round': 'R', 'score_board': 'Rezultatska ploča', 'winner': 'POBJEDNIK', 'penalty': 'Kazneni bodovi', 'rematch': 'UZVRAT', 'new_game': 'Nova igra (Postavke)', 'phase1': 'NAJAVE', 'phase2': 'ŠTIHOVI', 'starts': 'Počinje', 'bid_info': 'Najava', 'forbidden': 'Ne', 'called': 'Najavljeno', 'tricks_left': 'Preostalo za podjelu: ', 'btn_p1': 'DALJE', 'btn_p2': 'ZAVRŠI', 'btn_err': 'ŠTIHOVI SE MORAJU PODUDARATI', 'err_dealer': 'PRAVILO DIJELITELJA: Zbroj se ne smije podudarati!', 'deck_size': 'Špil karata', 'deck_1': '1 špil (36)', 'deck_2': '2 špila (72)', 'multiplier_opt': 'Rastući množitelj', 'multiplier_desc': 'Kazna × broj runde (R1=×1, R3=×3, ...)', 'shuffles': 'Miješa i dijeli', 'deals_short': 'Djelitelj', 'lbl_players': 'Igrači', 'lbl_material': 'Materijal', 'lbl_goal': 'Cilj', 'r_options': 'Opcije', 'r_options_txt': 'U postavkama možete igrati s 2 špila karata (72 karte) i aktivirati rastući množitelj koji množi kaznene bodove s brojem runde. Tko miješa/dijeli prikazuje se svake runde.', 'r_overview': 'PREGLED', 'r_players': '3 do 12 osoba', 'r_material': 'Jass karte (36 ili 72 s 2 špila)', 'r_goal': 'Doći do 0 bodova. (Razlika = Kazna)', 'r_flow': 'TIJEK', 'r_s1': 'Podijeliti karte (R1 = Maks, zatim -1).', 'r_s2': 'Napraviti najave.', 'r_s3': 'Igrati (Najviša karta osvaja štih).', 'r_s4': 'Obračun (|Najava - Štih|).', 'r_rules': 'PRAVILA', 'r_dealer': 'Pravilo dijelitelja', 'r_dealer_txt': 'Zbroj najava ≠ broj karata!', 'r_block': 'Blokiranje', 'r_block_txt': 'Iste najviše karte blokiraju jedna drugu.', 'r_final': 'Finale', 'r_final_txt': 'Zadnja karta na čelu (naslijepo)!' },
      'ru': { 'title': 'Fuck the Neighbor', 'add_hint': 'Имя', 'add_err': 'Максимум 12 игроков!', 'add_err_min': 'Минимум 3 игрока!', 'start': 'НАЧАТЬ', 'rules': 'Правила', 'ok': 'ПОНЯТНО', 'round': 'Р', 'score_board': 'Табло', 'winner': 'ПОБЕДИТЕЛЬ', 'penalty': 'Штрафные очки', 'rematch': 'РЕВАНШ', 'new_game': 'Новая игра (Настройка)', 'phase1': 'СТАВКИ', 'phase2': 'ВЗЯТКИ', 'starts': 'Начинает', 'bid_info': 'Ставка', 'forbidden': 'Не', 'called': 'Объявлено', 'tricks_left': 'Осталось раздать: ', 'btn_p1': 'ДАЛЕЕ', 'btn_p2': 'ЗАВЕРШИТЬ', 'btn_err': 'ВЗЯТКИ ДОЛЖНЫ СОВПАДАТЬ', 'err_dealer': 'ПРАВИЛО СДАЮЩЕГО: Сумма не должна совпадать!', 'deck_size': 'Колода карт', 'deck_1': '1 колода (36)', 'deck_2': '2 колоды (72)', 'multiplier_opt': 'Растущий множитель', 'multiplier_desc': 'Штраф × номер раунда (Р1=×1, Р3=×3, ...)', 'shuffles': 'Тасует и раздаёт', 'deals_short': 'Сдающий', 'lbl_players': 'Игроки', 'lbl_material': 'Материал', 'lbl_goal': 'Цель', 'r_options': 'Опции', 'r_options_txt': 'В настройках можно играть с 2 колодами карт (72 карты) и включить растущий множитель, который умножает штрафные очки на номер раунда. Кто тасует/сдаёт, показывается каждый раунд.', 'r_overview': 'ОБЗОР', 'r_players': 'От 3 до 12 человек', 'r_material': 'Карты для Ясса (36 или 72 с 2 колодами)', 'r_goal': 'Набрать 0 очков. (Разница = Штраф)', 'r_flow': 'ХОД ИГРЫ', 'r_s1': 'Раздать карты (Р1 = Макс, затем -1).', 'r_s2': 'Сделать ставки.', 'r_s3': 'Играть (Старшая карта берёт взятку).', 'r_s4': 'Подсчёт (|Ставка - Взятки|).', 'r_rules': 'ПРАВИЛА', 'r_dealer': 'Правило сдающего', 'r_dealer_txt': 'Сумма ставок ≠ количество карт!', 'r_block': 'Блокировка', 'r_block_txt': 'Равные старшие карты блокируют друг друга.', 'r_final': 'Финал', 'r_final_txt': 'Последняя карта на лбу (вслепую)!' },
      'ja': { 'title': 'Fuck the Neighbor', 'add_hint': '名前', 'add_err': '最大12人まで！', 'add_err_min': '最低3人必要！', 'start': '開始', 'rules': 'ルール', 'ok': '了解', 'round': 'R', 'score_board': 'スコアボード', 'winner': '勝者', 'penalty': 'ペナルティポイント', 'rematch': '再戦', 'new_game': '新しいゲーム（設定）', 'phase1': '予想', 'phase2': 'トリック', 'starts': '最初', 'bid_info': '予想', 'forbidden': '不可', 'called': '宣言済み', 'tricks_left': '残りの配分: ', 'btn_p1': '次へ', 'btn_p2': '完了', 'btn_err': 'トリックが一致している必要があります', 'err_dealer': 'ディーラールール: 合計が一致してはいけません！', 'deck_size': 'カードデッキ', 'deck_1': '1デッキ（36枚）', 'deck_2': '2デッキ（72枚）', 'multiplier_opt': '増加する倍率', 'multiplier_desc': 'ペナルティ × ラウンド番号 (R1=×1, R3=×3, ...)', 'shuffles': 'シャッフル＆配布', 'deals_short': 'ディーラー', 'lbl_players': 'プレイヤー', 'lbl_material': '道具', 'lbl_goal': '目標', 'r_options': 'オプション', 'r_options_txt': '設定では2デッキ（72枚）でプレイしたり、ラウンド番号でペナルティポイントを乗算する増加倍率を有効にできます。誰がシャッフル・配布するかは毎ラウンド表示されます。', 'r_overview': '概要', 'r_players': '3～12人', 'r_material': 'ジャスカード（36枚、2デッキなら72枚）', 'r_goal': '0点を目指す。（差 = ペナルティ）', 'r_flow': '流れ', 'r_s1': 'カードを配る（R1=最大、その後-1）。', 'r_s2': '宣言する。', 'r_s3': 'プレイ（最高カードがトリックを獲得）。', 'r_s4': '計算（|宣言 - トリック|）。', 'r_rules': 'ルール', 'r_dealer': 'ディーラールール', 'r_dealer_txt': '宣言の合計 ≠ カード枚数！', 'r_block': 'ブロック', 'r_block_txt': '同じ最高カードは互いにブロックする。', 'r_final': '最終ラウンド', 'r_final_txt': '最後のカードは額に（見ずに）！' },
      'ko': { 'title': 'Fuck the Neighbor', 'add_hint': '이름', 'add_err': '최대 12명!', 'add_err_min': '최소 3명 필요!', 'start': '시작', 'rules': '규칙', 'ok': '확인', 'round': 'R', 'score_board': '점수판', 'winner': '승자', 'penalty': '벌점', 'rematch': '재대결', 'new_game': '새 게임 (설정)', 'phase1': '예측', 'phase2': '트릭', 'starts': '시작', 'bid_info': '예측', 'forbidden': '불가', 'called': '예측됨', 'tricks_left': '남은 배분: ', 'btn_p1': '다음', 'btn_p2': '완료', 'btn_err': '트릭이 일치해야 합니다', 'err_dealer': '딜러 규칙: 합계가 일치하면 안 됩니다!', 'deck_size': '카드 덱', 'deck_1': '1덱 (36장)', 'deck_2': '2덱 (72장)', 'multiplier_opt': '증가하는 배율', 'multiplier_desc': '벌점 × 라운드 번호 (R1=×1, R3=×3, ...)', 'shuffles': '섞고 나눠줌', 'deals_short': '딜러', 'lbl_players': '플레이어', 'lbl_material': '도구', 'lbl_goal': '목표', 'r_options': '옵션', 'r_options_txt': '설정에서 2덱(72장)으로 플레이하거나 라운드 번호로 벌점을 곱하는 증가 배율을 활성화할 수 있습니다. 누가 섞고 나눠주는지는 매 라운드마다 표시됩니다.', 'r_overview': '개요', 'r_players': '3~12명', 'r_material': '야스 카드 (36장, 2덱이면 72장)', 'r_goal': '0점 도달. (차이 = 벌점)', 'r_flow': '진행', 'r_s1': '카드 나눠주기 (R1 = 최대, 이후 -1).', 'r_s2': '예측하기.', 'r_s3': '플레이 (가장 높은 카드가 트릭을 가져감).', 'r_s4': '계산 (|예측 - 트릭|).', 'r_rules': '규칙', 'r_dealer': '딜러 규칙', 'r_dealer_txt': '예측의 합 ≠ 카드 수!', 'r_block': '차단', 'r_block_txt': '같은 최고 카드는 서로 차단합니다.', 'r_final': '결승', 'r_final_txt': '마지막 카드는 이마에 (보지 않고)!' },
      'zh': { 'title': 'Fuck the Neighbor', 'add_hint': '名字', 'add_err': '最多12人！', 'add_err_min': '最少需要3人！', 'start': '开始', 'rules': '规则', 'ok': '明白了', 'round': 'R', 'score_board': '计分板', 'winner': '赢家', 'penalty': '罚分', 'rematch': '重赛', 'new_game': '新游戏（设置）', 'phase1': '预测', 'phase2': '赢墩', 'starts': '开始', 'bid_info': '预测', 'forbidden': '不可', 'called': '已预测', 'tricks_left': '剩余分配: ', 'btn_p1': '下一步', 'btn_p2': '完成', 'btn_err': '赢墩必须匹配', 'err_dealer': '庄家规则：总和不能匹配！', 'deck_size': '牌组', 'deck_1': '1副牌（36张）', 'deck_2': '2副牌（72张）', 'multiplier_opt': '递增倍数', 'multiplier_desc': '罚分 × 轮数 (R1=×1, R3=×3, ...)', 'shuffles': '洗牌并发牌', 'deals_short': '庄家', 'lbl_players': '玩家', 'lbl_material': '材料', 'lbl_goal': '目标', 'r_options': '选项', 'r_options_txt': '在设置中可以使用2副牌（72张）游戏，并启用递增倍数，将罚分乘以轮数。每轮都会显示谁洗牌/发牌。', 'r_overview': '概览', 'r_players': '3至12人', 'r_material': '雅斯纸牌（36张，2副牌则72张）', 'r_goal': '达到0分。（差值 = 罚分）', 'r_flow': '流程', 'r_s1': '发牌（R1=最大，然后-1）。', 'r_s2': '进行预测。', 'r_s3': '游戏（最大的牌赢得该墩）。', 'r_s4': '计算（|预测 - 赢墩|）。', 'r_rules': '规则', 'r_dealer': '庄家规则', 'r_dealer_txt': '预测总和 ≠ 牌数！', 'r_block': '阻挡', 'r_block_txt': '相同的最大牌互相阻挡。', 'r_final': '决赛', 'r_final_txt': '最后一张牌放在额头上（盲猜）！' },
      'hi': { 'title': 'Fuck the Neighbor', 'add_hint': 'नाम', 'add_err': 'अधिकतम 12 खिलाड़ी!', 'add_err_min': 'कम से कम 3 खिलाड़ी चाहिए!', 'start': 'शुरू', 'rules': 'नियम', 'ok': 'समझ गया', 'round': 'R', 'score_board': 'स्कोर बोर्ड', 'winner': 'विजेता', 'penalty': 'दंड अंक', 'rematch': 'रीमैच', 'new_game': 'नया खेल (सेटअप)', 'phase1': 'भविष्यवाणी', 'phase2': 'ट्रिक्स', 'starts': 'शुरू', 'bid_info': 'बोली', 'forbidden': 'नहीं', 'called': 'घोषित', 'tricks_left': 'शेष बाँटने के लिए: ', 'btn_p1': 'अगला', 'btn_p2': 'समाप्त', 'btn_err': 'ट्रिक्स मेल खानी चाहिए', 'err_dealer': 'डीलर नियम: योग मेल नहीं खाना चाहिए!', 'deck_size': 'कार्ड डेक', 'deck_1': '1 डेक (36)', 'deck_2': '2 डेक (72)', 'multiplier_opt': 'बढ़ता गुणक', 'multiplier_desc': 'दंड × राउंड संख्या (R1=×1, R3=×3, ...)', 'shuffles': 'फेंटता और बाँटता है', 'deals_short': 'डीलर', 'lbl_players': 'खिलाड़ी', 'lbl_material': 'सामग्री', 'lbl_goal': 'लक्ष्य', 'r_options': 'विकल्प', 'r_options_txt': 'सेटअप में आप 2 कार्ड डेक (72 कार्ड) के साथ खेल सकते हैं और एक बढ़ता गुणक सक्षम कर सकते हैं जो दंड अंकों को राउंड संख्या से गुणा करता है। कौन फेंटता/बाँटता है यह हर राउंड में दिखाया जाता है।', 'r_overview': 'अवलोकन', 'r_players': '3 से 12 लोग', 'r_material': 'जैस कार्ड (36 या 2 डेक के साथ 72)', 'r_goal': '0 अंक तक पहुँचें। (अंतर = दंड)', 'r_flow': 'प्रक्रिया', 'r_s1': 'कार्ड बाँटें (R1 = अधिकतम, फिर -1)।', 'r_s2': 'घोषणा करें।', 'r_s3': 'खेलें (सबसे ऊँचा कार्ड ट्रिक जीतता है)।', 'r_s4': 'गणना (|घोषणा - ट्रिक्स|)।', 'r_rules': 'नियम', 'r_dealer': 'डीलर नियम', 'r_dealer_txt': 'घोषणाओं का योग ≠ कार्डों की संख्या!', 'r_block': 'अवरोध', 'r_block_txt': 'समान सबसे ऊँचे कार्ड एक-दूसरे को रोकते हैं।', 'r_final': 'फाइनल', 'r_final_txt': 'आखिरी कार्ड माथे पर (बिना देखे)!' },
      'bn': { 'title': 'Fuck the Neighbor', 'add_hint': 'নাম', 'add_err': 'সর্বোচ্চ ১২ জন খেলোয়াড়!', 'add_err_min': 'কমপক্ষে ৩ জন খেলোয়াড় প্রয়োজন!', 'start': 'শুরু', 'rules': 'নিয়ম', 'ok': 'বুঝেছি', 'round': 'R', 'score_board': 'স্কোর বোর্ড', 'winner': 'বিজয়ী', 'penalty': 'জরিমানা পয়েন্ট', 'rematch': 'রিম্যাচ', 'new_game': 'নতুন খেলা (সেটআপ)', 'phase1': 'ভবিষ্যদ্বাণী', 'phase2': 'ট্রিকস', 'starts': 'শুরু', 'bid_info': 'ডাক', 'forbidden': 'নয়', 'called': 'ডাক দেওয়া হয়েছে', 'tricks_left': 'বাকি বিতরণ: ', 'btn_p1': 'পরবর্তী', 'btn_p2': 'শেষ', 'btn_err': 'ট্রিকস মিলতে হবে', 'err_dealer': 'ডিলার নিয়ম: যোগফল মিলতে পারবে না!', 'deck_size': 'কার্ড ডেক', 'deck_1': '১ ডেক (৩৬)', 'deck_2': '২ ডেক (৭২)', 'multiplier_opt': 'ক্রমবর্ধমান গুণক', 'multiplier_desc': 'জরিমানা × রাউন্ড নম্বর (R1=×1, R3=×3, ...)', 'shuffles': 'শাফল ও বিতরণ করে', 'deals_short': 'ডিলার', 'lbl_players': 'খেলোয়াড়', 'lbl_material': 'উপকরণ', 'lbl_goal': 'লক্ষ্য', 'r_options': 'বিকল্প', 'r_options_txt': 'সেটআপে আপনি ২টি কার্ড ডেক (৭২ কার্ড) দিয়ে খেলতে পারেন এবং একটি ক্রমবর্ধমান গুণক সক্রিয় করতে পারেন যা জরিমানা পয়েন্টকে রাউন্ড নম্বর দিয়ে গুণ করে। কে শাফল/বিতরণ করছে তা প্রতি রাউন্ডে দেখানো হয়।', 'r_overview': 'সারসংক্ষেপ', 'r_players': '৩ থেকে ১২ জন', 'r_material': 'জাস কার্ড (৩৬ বা ২ ডেক সহ ৭২)', 'r_goal': '০ পয়েন্টে পৌঁছান। (পার্থক্য = জরিমানা)', 'r_flow': 'প্রবাহ', 'r_s1': 'কার্ড বিতরণ করুন (R1 = সর্বোচ্চ, তারপর -1)।', 'r_s2': 'ডাক দিন।', 'r_s3': 'খেলুন (সর্বোচ্চ কার্ড ট্রিক জেতে)।', 'r_s4': 'গণনা (|ডাক - ট্রিকস|)।', 'r_rules': 'নিয়ম', 'r_dealer': 'ডিলার নিয়ম', 'r_dealer_txt': 'ডাকের যোগফল ≠ কার্ডের সংখ্যা!', 'r_block': 'বাধা', 'r_block_txt': 'সমান সর্বোচ্চ কার্ড একে অপরকে বাধা দেয়।', 'r_final': 'ফাইনাল', 'r_final_txt': 'শেষ কার্ড কপালে (না দেখে)!' },
    };

    if (dictionary.containsKey(_currentLang) && dictionary[_currentLang]!.containsKey(key)) {
      return dictionary[_currentLang]![key]!;
    }
    return dictionary['en']![key] ?? key;
  }

  // --- LOGIK: SETUP ---

  void _addPlayer() {
    if (_nameController.text.trim().isNotEmpty) {
      if (_players.length >= 12) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('add_err'))));
        return;
      }
      setState(() {
        _players.add(Player(name: _nameController.text.trim()));
        _nameController.clear();
      });
      _persist();
    }
  }

  void _showRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: primaryColor, width: 2)),
        title: Row(
          children: [
            Icon(Icons.menu_book, color: primaryColor),
            const SizedBox(width: 10),
            Flexible(child: Text(_t('rules'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRuleHeader(_t('r_overview')),
                _buildRuleItem(Icons.groups, _t('lbl_players'), _t('r_players')),
                _buildRuleItem(Icons.style, _t('lbl_material'), _t('r_material')),
                _buildRuleItem(Icons.emoji_events, _t('lbl_goal'), _t('r_goal')),

                const SizedBox(height: 15),
                _buildRuleHeader(_t('r_flow')),
                _buildRuleStep("1", _t('r_s1')),
                _buildRuleStep("2", _t('r_s2')),
                _buildRuleStep("3", _t('r_s3')),
                _buildRuleStep("4", _t('r_s4')),

                const SizedBox(height: 15),
                _buildRuleHeader(_t('r_rules')),
                _buildRuleSpecial(_t('r_dealer'), _t('r_dealer_txt')),
                _buildRuleSpecial(_t('r_block'), _t('r_block_txt')),
                _buildRuleSpecial(_t('r_final'), _t('r_final_txt')),
                _buildRuleSpecial(_t('r_options'), _t('r_options_txt')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('ok'), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Helpers für Rules Layout
  Widget _buildRuleHeader(String title) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(title, style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 12)));
  Widget _buildRuleItem(IconData i, String t, String x) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, color: Colors.grey, size: 16), const SizedBox(width: 10), Expanded(child: RichText(text: TextSpan(style: const TextStyle(color: Colors.white70, fontSize: 13), children: [TextSpan(text: "$t: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), TextSpan(text: x)])))]));
  Widget _buildRuleStep(String n, String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Container(width: 18, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), shape: BoxShape.circle), child: Text(n, style: TextStyle(color: primaryColor, fontSize: 11))), const SizedBox(width: 10), Expanded(child: Text(t, style: const TextStyle(color: Colors.white70, fontSize: 13)))]));
  Widget _buildRuleSpecial(String t, String x) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black26, border: Border(left: BorderSide(color: errorColor, width: 3)), borderRadius: BorderRadius.circular(4)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: TextStyle(color: errorColor, fontWeight: FontWeight.bold, fontSize: 13)), Text(x, style: const TextStyle(color: Colors.white70, fontSize: 12))]));


  void _startGame() {
    FocusScope.of(context).unfocus();

    if (_players.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('add_err_min'))));
      return;
    }
    _setupRounds();
  }

  void _rematch() {
    setState(() {
      for (var p in _players) {
        p.totalScore = 0;
      }
      if (_players.length > 1) {
        Player first = _players.removeAt(0);
        _players.add(first);
      }
      _setupRounds();
    });
    _persist();
  }

  void _setupRounds() {
    int maxCards = _deckSize ~/ _players.length;
    List<RoundData> generatedRounds = [];

    for (int i = 0; i < maxCards; i++) {
      generatedRounds.add(RoundData(
        roundNumber: i + 1,
        cardCount: maxCards - i,
        dealerIndex: i % _players.length, // Geber wechselt
        isLocked: i != 0,
      ));
    }

    setState(() {
      _rounds = generatedRounds;
      _gameStarted = true;
      _gameFinished = false;
    });
    _persist();
  }

  // --- LOGIK: GAMEPLAY ---

  void _openRoundInput(int roundIndex) {
    RoundData round = _rounds[roundIndex];
    for (var p in _players) {
      round.bids.putIfAbsent(p.name, () => 0);
      round.tricks.putIfAbsent(p.name, () => 0);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgColor,
      builder: (context) => _RoundInputSheet(
        round: round,
        players: _players,
        primaryColor: primaryColor,
        errorColor: errorColor,
        successColor: successColor,
        cardColor: cardColor,
        langDict: (key) => _t(key), // Pass translation function
        onRoundCompleted: () {
          _finishRound(roundIndex);
          Navigator.pop(context);
        },
        onDataChanged: _persist,
      ),
    );
  }

  void _finishRound(int roundIndex) {
    setState(() {
      RoundData round = _rounds[roundIndex];
      int multiplier = _useMultiplier ? round.roundNumber : 1;
      for (var player in _players) {
        int bid = round.bids[player.name]!;
        int trick = round.tricks[player.name]!;
        int points = (bid - trick).abs() * multiplier;
        round.roundPoints[player.name] = points;
        player.totalScore += points;
      }
      round.isCompleted = true;

      if (roundIndex + 1 < _rounds.length) {
        _rounds[roundIndex + 1].isLocked = false;
      } else {
        _gameFinished = true;
      }
    });
    _persist();
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(_gameStarted ? _t('score_board') : _t('title')),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: primaryColor,
          actions: [
            IconButton(icon: const Icon(Icons.help_outline), onPressed: _showRules, tooltip: _t('rules')),
          ],
        ),
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_gameFinished) return _buildGameOver();
    if (_gameStarted) return _buildScoreTable();
    return _buildSetup();
  }

  // SCREEN 1: SETUP
  Widget _buildSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Icon(Icons.style, size: 80, color: primaryColor),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _t('add_hint'),
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                  ),
                  onSubmitted: (_) => _addPlayer(),
                ),
              ),
              IconButton(onPressed: _addPlayer, icon: Icon(Icons.add_circle, color: primaryColor, size: 40)),
            ],
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _players.length,
              itemBuilder: (context, index) => Card(
                color: surfaceColor,
                child: ListTile(
                  title: Text(_players[index].name, style: const TextStyle(color: Colors.white)),
                  trailing: IconButton(icon: Icon(Icons.delete, color: errorColor), onPressed: () {
                    setState(() => _players.removeAt(index));
                    _persist();
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),

          // --- DECK SIZE ---
          Align(
            alignment: Alignment.centerLeft,
            child: Text(_t('deck_size'), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _deckChip(_t('deck_1'), 36)),
              const SizedBox(width: 10),
              Expanded(child: _deckChip(_t('deck_2'), 72)),
            ],
          ),

          const SizedBox(height: 20),

          // --- ESCALATING MULTIPLIER ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: primaryColor,
              title: Text(_t('multiplier_opt'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(_t('multiplier_desc'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              value: _useMultiplier,
              onChanged: (val) {
                setState(() => _useMultiplier = val);
                _persist();
              },
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: Text(_t('start'), style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  String _dealerName(RoundData round) {
    if (round.dealerIndex < 0 || round.dealerIndex >= _players.length) return "";
    return _players[round.dealerIndex].name;
  }

  Widget _deckChip(String label, int size) {
    bool isSelected = _deckSize == size;
    return GestureDetector(
      onTap: () {
        setState(() => _deckSize = size);
        _persist();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? primaryColor : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // SCREEN 2: SCORE TABLE (Responsive Cards mit Hybrid Layout)
  Widget _buildScoreTable() {
    const double headerWidth = 74.0;
    const double minCardWidth = 75.0;
    const double rowHeight = 86.0;
    const double headerHeight = 80.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double widthForContent = availableWidth - headerWidth - 20;

        double totalNeeded = _players.length * minCardWidth;
        bool needsScroll = totalNeeded > widthForContent;

        double cardWidth;
        if (needsScroll) {
          cardWidth = minCardWidth;
        } else {
          cardWidth = widthForContent / _players.length;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  controller: _scrollController,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // A) LINKE SPALTE
                      Column(
                        children: [
                          Container(
                            width: headerWidth,
                            height: headerHeight,
                            alignment: Alignment.center,
                            child: const Icon(Icons.grid_view, color: Colors.white12, size: 24),
                          ),
                          ..._rounds.asMap().entries.map((entry) {
                            RoundData round = entry.value;
                            bool isCurrent = !round.isLocked && !round.isCompleted;
                            return Container(
                              width: headerWidth,
                              height: rowHeight,
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              alignment: Alignment.center,
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: isCurrent ? primaryColor : surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("${_t('round')}${round.roundNumber}",
                                        style: TextStyle(
                                            color: isCurrent ? Colors.black : Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14
                                        )
                                    ),
                                    Text("${round.cardCount}",
                                        style: TextStyle(
                                            color: isCurrent ? Colors.black.withOpacity(0.6) : Colors.grey,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold
                                        )
                                    ),
                                    if (_useMultiplier)
                                      Text("×${round.roundNumber}",
                                          style: TextStyle(
                                              color: isCurrent ? Colors.black.withOpacity(0.6) : primaryColor,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold
                                          )
                                      ),
                                    const SizedBox(height: 2),
                                    Tooltip(
                                      message: "${_t('shuffles')}: ${_dealerName(round)}",
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.shuffle, size: 9, color: isCurrent ? Colors.black54 : Colors.white24),
                                          const SizedBox(width: 2),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 50),
                                            child: Text(_dealerName(round),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: TextStyle(
                                                    color: isCurrent ? Colors.black54 : Colors.white38,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600
                                                )
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if(round.isCompleted)
                                      Icon(Icons.check, size: 12, color: successColor)
                                  ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),

                      // B) RECHTER BEREICH
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: needsScroll ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. HEADER ROW (Spieler Namen)
                              Row(
                                children: _players.map((p) => Container(
                                  width: cardWidth,
                                  height: headerHeight,
                                  padding: const EdgeInsets.all(4),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: surfaceColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            p.name,
                                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(6)),
                                          child: Text("${p.totalScore}",
                                              style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                )).toList(),
                              ),

                              // 2. DATA ROWS
                              ..._rounds.asMap().entries.map((entry) {
                                int idx = entry.key;
                                RoundData round = entry.value;
                                bool isCurrent = !round.isLocked && !round.isCompleted;

                                return InkWell(
                                  onTap: round.isLocked ? null : () => _openRoundInput(idx),
                                  child: Row(
                                    children: _players.map((p) {
                                      String content = "";
                                      Color textColor = Colors.grey;
                                      Color cellBg = cardColor;
                                      Border? border;

                                      if (round.isCompleted) {
                                        int bid = round.bids[p.name]!;
                                        int trick = round.tricks[p.name]!;
                                        int pts = round.roundPoints[p.name]!;

                                        // ANPASSUNG: "Stich / Ansage"
                                        content = "$trick / $bid";

                                        if (pts == 0) {
                                          textColor = successColor;
                                          cellBg = successColor.withOpacity(0.15);
                                          border = Border.all(color: successColor.withOpacity(0.3));
                                        } else {
                                          textColor = errorColor;
                                          cellBg = errorColor.withOpacity(0.15);
                                          border = Border.all(color: errorColor.withOpacity(0.3));
                                        }
                                      } else if (isCurrent) {
                                        content = "?";
                                        textColor = primaryColor;
                                        cellBg = primaryColor.withOpacity(0.1);
                                        border = Border.all(color: primaryColor.withOpacity(0.5));
                                      } else {
                                        content = "-";
                                        textColor = Colors.white10;
                                        cellBg = Colors.black12;
                                      }

                                      return Container(
                                        width: cardWidth,
                                        height: rowHeight,
                                        padding: const EdgeInsets.all(4),
                                        child: Container(
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: cellBg,
                                            borderRadius: BorderRadius.circular(10),
                                            border: border,
                                          ),
                                          child: Text(
                                              content,
                                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              }),

                              const SizedBox(height: 50),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // SCREEN 3: GAME OVER
  Widget _buildGameOver() {
    List<Player> sorted = List.from(_players);
    sorted.sort((a, b) => a.totalScore.compareTo(b.totalScore)); // Kleinster Score gewinnt

    int bestScore = sorted.first.totalScore;
    List<Player> winners = sorted.where((p) => p.totalScore == bestScore).toList();
    String winnerNames = winners.map((p) => p.name).join(" & ");

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, size: 80, color: primaryColor),
              const SizedBox(height: 20),
              Text(_t('winner'), style: TextStyle(color: Colors.white.withOpacity(0.6), letterSpacing: 2)),
              const SizedBox(height: 5),
              Text(
                  winnerNames,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 5),
              Text("$bestScore ${_t('penalty')}", style: TextStyle(color: primaryColor, fontSize: 20)),
              const SizedBox(height: 30),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final player = sorted[index];
                  int displayRank = sorted.indexWhere((p) => p.totalScore == player.totalScore) + 1;

                  return Card(
                    color: surfaceColor,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: displayRank == 1 ? primaryColor : Colors.grey.shade700,
                        foregroundColor: displayRank == 1 ? Colors.black : Colors.white,
                        child: Text("$displayRank."),
                      ),
                      title: Text(player.name, style: const TextStyle(color: Colors.white)),
                      trailing: Text("${player.totalScore}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _rematch,
                  style: ElevatedButton.styleFrom(backgroundColor: successColor),
                  child: Text(_t('rematch'), style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                  onPressed: () {
                    GamePersistence.clear(gameId);
                    setState(() {
                      _gameFinished = false;
                      _gameStarted = false;
                      _players.clear();
                    });
                  },
                  child: Text(_t('new_game'), style: const TextStyle(color: Colors.grey))
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- INPUT SHEET ---

class _RoundInputSheet extends StatefulWidget {
  final RoundData round;
  final List<Player> players;
  final Color primaryColor;
  final Color errorColor;
  final Color successColor;
  final Color cardColor;
  final VoidCallback onRoundCompleted;
  final String Function(String) langDict; // Für Übersetzung im BottomSheet
  final VoidCallback? onDataChanged;

  const _RoundInputSheet({
    required this.round,
    required this.players,
    required this.primaryColor,
    required this.errorColor,
    required this.successColor,
    required this.cardColor,
    required this.onRoundCompleted,
    required this.langDict,
    this.onDataChanged,
  });

  @override
  State<_RoundInputSheet> createState() => _RoundInputSheetState();
}

class _RoundInputSheetState extends State<_RoundInputSheet> {
  bool isPhase2 = false;
  late List<Player> orderedPlayers;

  @override
  void initState() {
    super.initState();
    orderedPlayers = [];
    // Startspieler ist der links vom Geber (Geber-Index + 1)
    int start = (widget.round.dealerIndex + 1) % widget.players.length;
    for (int i = 0; i < widget.players.length; i++) {
      orderedPlayers.add(widget.players[(start + i) % widget.players.length]);
    }
  }

  int? get _forbiddenBid {
    int currentSum = 0;
    for (int i = 0; i < orderedPlayers.length - 1; i++) {
      currentSum += widget.round.bids[orderedPlayers[i].name]!;
    }
    int forbidden = widget.round.cardCount - currentSum;
    return forbidden >= 0 ? forbidden : null;
  }

  int get _remainingTricks {
    int currentTricks = widget.round.tricks.values.fold(0, (a, b) => a + b);
    return widget.round.cardCount - currentTricks;
  }

  void _confirmBids() {
    int total = widget.round.bids.values.fold(0, (a, b) => a + b);
    if (total == widget.round.cardCount) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: widget.errorColor,
        content: Text(widget.langDict('err_dealer')),
      ));
      return;
    }
    setState(() {
      isPhase2 = true;
    });
    widget.onDataChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF222629),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: widget.primaryColor, width: 2))
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPhase2 ? widget.langDict('phase2') : widget.langDict('phase1'),
                      style: TextStyle(color: widget.primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text("${widget.langDict('round')} ${widget.round.roundNumber} (${widget.round.cardCount})", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey))
            ],
          ),

          const SizedBox(height: 10),

          // Wer mischt & gibt diese Runde
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: widget.primaryColor.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.shuffle, color: widget.primaryColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${widget.langDict('shuffles')}: ${orderedPlayers.last.name}",
                    style: TextStyle(color: widget.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          Expanded(
            child: ListView.builder(
              itemCount: orderedPlayers.length,
              itemBuilder: (context, index) {
                final player = orderedPlayers[index];
                final isLast = index == orderedPlayers.length - 1;
                final isFirst = index == 0;
                final forbidden = (!isPhase2 && isLast) ? _forbiddenBid : null;

                int val = isPhase2
                    ? widget.round.tricks[player.name]!
                    : widget.round.bids[player.name]!;

                bool isForbiddenValue = (forbidden != null && val == forbidden);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.cardColor,
                    border: isLast && !isPhase2 ? Border.all(color: widget.primaryColor.withOpacity(0.5)) : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                    child: Text(
                                        player.name,
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis
                                    )
                                ),
                                // ANPASSUNG: Anzeige der gemachten Ansage in Phase 2
                                if (isPhase2) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: widget.primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                    child: Text(
                                        "${widget.langDict('called')}: ${widget.round.bids[player.name]}",
                                        style: TextStyle(color: widget.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)
                                    ),
                                  ),
                                ]
                              ],
                            ),
                            // ANPASSUNG: Indikator wer anfängt (in Phase 1)
                            if (isFirst && !isPhase2)
                              Text(widget.langDict('starts'), style: TextStyle(color: widget.successColor, fontSize: 12, fontWeight: FontWeight.bold)),
                            // ANPASSUNG: Info für Geber
                            if (forbidden != null)
                              Text("${widget.langDict('forbidden')} $forbidden!", style: TextStyle(color: widget.errorColor, fontSize: 12)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _circleBtn(Icons.remove, () {
                            setState(() {
                              if (val > 0) {
                                if (isPhase2) widget.round.tricks[player.name] = val - 1;
                                else widget.round.bids[player.name] = val - 1;
                              }
                            });
                            widget.onDataChanged?.call();
                          }),
                          SizedBox(
                            width: 35,
                            child: Text("$val", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isForbiddenValue ? widget.errorColor : Colors.white)),
                          ),
                          _circleBtn(Icons.add, () {
                            setState(() {
                              if (val < widget.round.cardCount) {
                                if (isPhase2) widget.round.tricks[player.name] = val + 1;
                                else widget.round.bids[player.name] = val + 1;
                              }
                            });
                            widget.onDataChanged?.call();
                          }),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          if (isPhase2)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.langDict('tricks_left'), style: const TextStyle(color: Colors.grey, fontSize: 16)),
                  Text(
                    "${_remainingTricks}",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _remainingTricks == 0 ? widget.successColor : widget.errorColor
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                if (isPhase2) {
                  if (_remainingTricks == 0) {
                    widget.onRoundCompleted();
                  }
                } else {
                  _confirmBids();
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: isPhase2
                      ? (_remainingTricks == 0 ? widget.successColor : Colors.grey.shade800)
                      : widget.primaryColor
              ),
              child: Text(
                isPhase2
                    ? (_remainingTricks == 0 ? widget.langDict('btn_p2') : widget.langDict('btn_err'))
                    : widget.langDict('btn_p1'),
                style: TextStyle(
                    color: (isPhase2 && _remainingTricks != 0) ? Colors.grey : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: Colors.white, size: 20), onPressed: onTap),
    );
  }
}