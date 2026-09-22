import 'package:flutter/material.dart';
import 'darts_more.dart';
import '../main.dart';
import '../services/game_persistence.dart';

// --- DATEN-MODELLE ---
class DartPlayer {
  String name;
  int currentScore;
  int legsWon;
  List<int> history;

  // Statistik
  int dartsThrown = 0;
  int totalScored = 0;
  int bestCheckout = 0;

  double get average => dartsThrown == 0 ? 0 : (totalScored / dartsThrown) * 3;

  // startScore wird direkt an currentScore übergeben
  DartPlayer({required this.name, required int startScore})
      : currentScore = startScore,
        legsWon = 0,
        history = [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'currentScore': currentScore,
        'legsWon': legsWon,
        'history': history,
        'dartsThrown': dartsThrown,
        'totalScored': totalScored,
        'bestCheckout': bestCheckout,
      };

  factory DartPlayer.fromJson(Map<String, dynamic> json) {
    final player = DartPlayer(name: json['name'] as String, startScore: json['currentScore'] as int);
    player.legsWon = json['legsWon'] as int? ?? 0;
    player.history = List<int>.from((json['history'] as List<dynamic>? ?? []).map((e) => e as int));
    player.dartsThrown = json['dartsThrown'] as int? ?? 0;
    player.totalScored = json['totalScored'] as int? ?? 0;
    player.bestCheckout = json['bestCheckout'] as int? ?? 0;
    return player;
  }
}

class DartsGame extends StatefulWidget {
  // Hier nehmen wir die Farbe aus der Main.dart entgegen
  final Color? themeColor;
  final bool resume;

  const DartsGame({super.key, this.themeColor, this.resume = false});

  @override
  State<DartsGame> createState() => _DartsGameState();
}

class _DartsGameState extends State<DartsGame> {
  static const String gameId = 'game_title_darts';

  // --- STYLE ---
  // Getter: Nutze die übergebene Farbe, oder Fallback auf Dart-Grün
  Color get primaryColor => widget.themeColor ?? const Color(0xFF00B894);

  final Color bgColor = const Color(0xFF222629);
  final Color surfaceColor = const Color(0xFF30363B);
  final Color errorColor = const Color(0xFFEB6B6B);

  // Sprache: immer live vom globalen App-Status gelesen (reaktiv auf Sprachwechsel)
  String get _currentLang => appLocaleNotifier.value.languageCode;

  // --- STATE ---
  bool _gameStarted = false;
  List<DartPlayer> _players = [];
  int _startScore = 501; // Default
  int _currentPlayerIndex = 0;
  int _bestOf = 1; // Best-of-Legs Match-Format (1, 3, 5, 7)
  bool _doubleOutEnabled = true; // Standard-Regel: Checkout muss ein Doppel sein

  int get _legsToWin => (_bestOf / 2).ceil();

  // Input Controller für das Custom Keypad
  String _currentInput = "";

  final TextEditingController _nameController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
      _startScore = saved['startScore'] as int? ?? _startScore;
      _currentPlayerIndex = saved['currentPlayerIndex'] as int? ?? 0;
      _bestOf = saved['bestOf'] as int? ?? _bestOf;
      _doubleOutEnabled = saved['doubleOutEnabled'] as bool? ?? _doubleOutEnabled;
      _currentInput = saved['currentInput'] as String? ?? "";
      _players = ((saved['players'] as List<dynamic>?) ?? [])
          .map((p) => DartPlayer.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
    });
  }

  void _persist() {
    GamePersistence.save(gameId, {
      'gameStarted': _gameStarted,
      'startScore': _startScore,
      'currentPlayerIndex': _currentPlayerIndex,
      'bestOf': _bestOf,
      'doubleOutEnabled': _doubleOutEnabled,
      'currentInput': _currentInput,
      'players': _players.map((p) => p.toJson()).toList(),
    });
  }

  // --- ÜBERSETZUNG ---
  String _t(String key) {
    const Map<String, Map<String, String>> dictionary = {
      'de': {
        'title': 'Darts X01', 'rules_title': 'Darts X01 Regeln', 'ok': 'VERSTANDEN',
        'r_goal_title': 'ZIEL', 'r_goal_text': 'Erreiche exakt 0 Punkte.',
        'r_flow_title': 'ABLAUF', 'r_flow_text': 'Jeder wirft 3 Pfeile. Die Summe wird abgezogen.',
        'r_bust_title': 'BUST (ÜBERWORFEN)', 'r_bust_text': 'Wirfst du mehr Punkte als du Rest hast (oder bleibt genau 1 übrig), verfällt der Wurf. Du bleibst auf dem Punktestand vor dem Wurf.',
        'r_double_title': 'DOUBLE-OUT', 'r_double_text': 'Bei aktivierter Double-Out Regel musst du bestätigen, dass dein letzter Pfeil ein Doppelfeld (oder Bull) getroffen hat, um das Leg zu gewinnen.',
        'r_format_title': 'MATCH-FORMAT', 'r_format_text': 'Wähle "Best of X Legs" - wer zuerst die Mehrheit der Legs gewinnt, gewinnt das Match.',
        'r_checkout_title': 'CHECKOUT-VORSCHLÄGE', 'r_checkout_text': 'Bei einem Restwert bis 170 zeigt die App einen möglichen Ausgang mit den wenigsten Pfeilen an.',
        'add_players_needed': 'Bitte Spieler hinzufügen!', 'add_hint': 'Spieler Name', 'max_players_err': 'Maximal 8 Spieler!',
        'game_mode': 'SPIEL-MODUS', 'match_format': 'MATCH-FORMAT', 'one_leg': '1 Leg',
        'double_out': 'Double-Out', 'double_out_desc': 'Checkout muss auf ein Doppel/Bull enden',
        'start_btn': 'GAME ON!', 'throw_hint': 'Wurf eingeben...', 'checkout_label': 'CHECKOUT',
        'legs_label': 'Legs', 'stats': 'Stats',
        'max_score_err': 'Maximal 180 Punkte möglich!', 'bust_msg': 'Überworfen! Zurück auf',
        'checkout_confirm_title': 'Checkout bestätigen', 'checkout_confirm_msg': 'Wurde der letzte Pfeil auf ein Doppel (oder Bull) geworfen?',
        'no': 'NEIN', 'yes': 'JA',
        'wins_match': 'GEWINNT DAS MATCH!', 'wins_leg': 'GEWINNT DAS LEG!',
        'leg_status': 'Leg-Stand', 'new_leg_q': 'Neues Leg starten?',
        'new_round': 'NEUE RUNDE', 'rematch': 'REVANCHE', 'finish': 'BEENDEN',
        'stat_avg': 'AVG (3 DARTS)', 'stat_legs': 'LEGS', 'stat_checkout': 'BESTER CHECKOUT', 'stat_darts': 'PFEILE',
      },
      'en': {
        'title': 'Darts X01', 'rules_title': 'Darts X01 Rules', 'ok': 'GOT IT',
        'r_goal_title': 'GOAL', 'r_goal_text': 'Reach exactly 0 points.',
        'r_flow_title': 'FLOW', 'r_flow_text': 'Each player throws 3 darts. The sum is subtracted.',
        'r_bust_title': 'BUST', 'r_bust_text': 'If you score more than your remaining points (or exactly 1 is left), the throw is voided. You stay on the score you had before the throw.',
        'r_double_title': 'DOUBLE-OUT', 'r_double_text': 'With Double-Out enabled, you must confirm your last dart hit a double (or bull) to win the leg.',
        'r_format_title': 'MATCH FORMAT', 'r_format_text': 'Pick "Best of X Legs" - whoever wins the majority of legs first wins the match.',
        'r_checkout_title': 'CHECKOUT SUGGESTIONS', 'r_checkout_text': 'For a remaining score up to 170 the app shows a possible finish using the fewest darts.',
        'add_players_needed': 'Please add players!', 'add_hint': 'Player Name', 'max_players_err': 'Max 8 players!',
        'game_mode': 'GAME MODE', 'match_format': 'MATCH FORMAT', 'one_leg': '1 Leg',
        'double_out': 'Double-Out', 'double_out_desc': 'Checkout must land on a double/bull',
        'start_btn': 'GAME ON!', 'throw_hint': 'Enter throw...', 'checkout_label': 'CHECKOUT',
        'legs_label': 'Legs', 'stats': 'Stats',
        'max_score_err': 'Maximum 180 points possible!', 'bust_msg': 'Bust! Back to',
        'checkout_confirm_title': 'Confirm Checkout', 'checkout_confirm_msg': 'Did the last dart hit a double (or bull)?',
        'no': 'NO', 'yes': 'YES',
        'wins_match': 'WINS THE MATCH!', 'wins_leg': 'WINS THE LEG!',
        'leg_status': 'Leg score', 'new_leg_q': 'Start new leg?',
        'new_round': 'NEW LEG', 'rematch': 'REMATCH', 'finish': 'QUIT',
        'stat_avg': 'AVG (3 DARTS)', 'stat_legs': 'LEGS', 'stat_checkout': 'BEST CHECKOUT', 'stat_darts': 'DARTS',
      },
      'fr': {
        'title': 'Darts X01', 'rules_title': 'Règles Darts X01', 'ok': 'COMPRIS',
        'r_goal_title': 'OBJECTIF', 'r_goal_text': 'Atteignez exactement 0 point.',
        'r_flow_title': 'DÉROULEMENT', 'r_flow_text': 'Chaque joueur lance 3 fléchettes. La somme est soustraite.',
        'r_bust_title': 'BUST (RATÉ)', 'r_bust_text': "Si vous marquez plus de points qu'il ne vous en reste (ou s'il en reste exactement 1), le lancer est annulé. Vous restez au score d'avant le lancer.",
        'r_double_title': 'DOUBLE-OUT', 'r_double_text': 'Avec la règle Double-Out activée, vous devez confirmer que votre dernière fléchette a touché un double (ou le bull) pour gagner la manche.',
        'r_format_title': 'FORMAT DU MATCH', 'r_format_text': 'Choisissez "Best of X Manches" - le premier à remporter la majorité des manches gagne le match.',
        'r_checkout_title': 'SUGGESTIONS DE FINISH', 'r_checkout_text': "Pour un score restant jusqu'à 170, l'appli affiche un finish possible avec le moins de fléchettes.",
        'add_players_needed': 'Veuillez ajouter des joueurs !', 'add_hint': 'Nom du joueur', 'max_players_err': 'Maximum 8 joueurs !',
        'game_mode': 'MODE DE JEU', 'match_format': 'FORMAT DU MATCH', 'one_leg': '1 Manche',
        'double_out': 'Double-Out', 'double_out_desc': 'Le finish doit se faire sur un double/bull',
        'start_btn': 'GAME ON !', 'throw_hint': 'Entrer le lancer...', 'checkout_label': 'FINISH',
        'legs_label': 'Manches', 'stats': 'Stats',
        'max_score_err': 'Maximum 180 points possible !', 'bust_msg': 'Raté ! Retour à',
        'checkout_confirm_title': 'Confirmer le finish', 'checkout_confirm_msg': 'La dernière fléchette a-t-elle touché un double (ou le bull) ?',
        'no': 'NON', 'yes': 'OUI',
        'wins_match': 'REMPORTE LE MATCH !', 'wins_leg': 'REMPORTE LA MANCHE !',
        'leg_status': 'Score des manches', 'new_leg_q': 'Démarrer une nouvelle manche ?',
        'new_round': 'NOUVELLE MANCHE', 'rematch': 'REVANCHE', 'finish': 'QUITTER',
        'stat_avg': 'MOY. (3 FLÉCH.)', 'stat_legs': 'MANCHES', 'stat_checkout': 'MEILLEUR FINISH', 'stat_darts': 'FLÉCHETTES',
      },
      'it': {
        'title': 'Darts X01', 'rules_title': 'Regole Darts X01', 'ok': 'CAPITO',
        'r_goal_title': 'OBIETTIVO', 'r_goal_text': 'Raggiungi esattamente 0 punti.',
        'r_flow_title': 'SVOLGIMENTO', 'r_flow_text': 'Ogni giocatore lancia 3 freccette. La somma viene sottratta.',
        'r_bust_title': 'BUST (SFORATO)', 'r_bust_text': "Se totalizzi più punti di quelli rimasti (o ne resta esattamente 1), il tiro viene annullato. Resti al punteggio precedente al tiro.",
        'r_double_title': 'DOUBLE-OUT', 'r_double_text': "Con la regola Double-Out attiva, devi confermare che l'ultima freccetta ha colpito un doppio (o il bull) per vincere il leg.",
        'r_format_title': 'FORMATO PARTITA', 'r_format_text': 'Scegli "Best of X Leg" - chi vince per primo la maggioranza dei leg vince la partita.',
        'r_checkout_title': 'SUGGERIMENTI CHECKOUT', 'r_checkout_text': "Per un punteggio residuo fino a 170 l'app mostra una possibile chiusura con il minor numero di freccette.",
        'add_players_needed': 'Aggiungi dei giocatori!', 'add_hint': 'Nome giocatore', 'max_players_err': 'Massimo 8 giocatori!',
        'game_mode': 'MODALITÀ DI GIOCO', 'match_format': 'FORMATO PARTITA', 'one_leg': '1 Leg',
        'double_out': 'Double-Out', 'double_out_desc': 'Il checkout deve concludersi su un doppio/bull',
        'start_btn': 'GAME ON!', 'throw_hint': 'Inserisci il tiro...', 'checkout_label': 'CHECKOUT',
        'legs_label': 'Leg', 'stats': 'Stats',
        'max_score_err': 'Massimo 180 punti possibili!', 'bust_msg': 'Sforato! Torni a',
        'checkout_confirm_title': 'Conferma checkout', 'checkout_confirm_msg': "L'ultima freccetta ha colpito un doppio (o il bull)?",
        'no': 'NO', 'yes': 'SÌ',
        'wins_match': 'VINCE LA PARTITA!', 'wins_leg': 'VINCE IL LEG!',
        'leg_status': 'Punteggio leg', 'new_leg_q': 'Iniziare un nuovo leg?',
        'new_round': 'NUOVO LEG', 'rematch': 'RIVINCITA', 'finish': 'ESCI',
        'stat_avg': 'MEDIA (3 FRECCE)', 'stat_legs': 'LEG', 'stat_checkout': 'MIGLIOR CHECKOUT', 'stat_darts': 'FRECCETTE',
      },
      'es': {
        'title': 'Darts X01', 'rules_title': 'Reglas de Darts X01', 'ok': 'ENTENDIDO',
        'r_goal_title': 'OBJETIVO', 'r_goal_text': 'Llega exactamente a 0 puntos.',
        'r_flow_title': 'DESARROLLO', 'r_flow_text': 'Cada jugador lanza 3 dardos. La suma se resta.',
        'r_bust_title': 'BUST (PASADO)', 'r_bust_text': 'Si anotas más puntos de los que te quedan (o queda exactamente 1), el lanzamiento se anula. Te quedas con el puntaje anterior al lanzamiento.',
        'r_double_title': 'DOUBLE-OUT', 'r_double_text': 'Con la regla Double-Out activada, debes confirmar que tu último dardo dio en un doble (o el bull) para ganar la manga.',
        'r_format_title': 'FORMATO DEL PARTIDO', 'r_format_text': 'Elige "Mejor de X Mangas" - quien gane primero la mayoría de mangas gana el partido.',
        'r_checkout_title': 'SUGERENCIAS DE CIERRE', 'r_checkout_text': 'Para un puntaje restante de hasta 170, la app muestra un posible cierre con la menor cantidad de dardos.',
        'add_players_needed': '¡Agrega jugadores!', 'add_hint': 'Nombre del jugador', 'max_players_err': '¡Máximo 8 jugadores!',
        'game_mode': 'MODO DE JUEGO', 'match_format': 'FORMATO DEL PARTIDO', 'one_leg': '1 Manga',
        'double_out': 'Double-Out', 'double_out_desc': 'El cierre debe caer en un doble/bull',
        'start_btn': '¡A JUGAR!', 'throw_hint': 'Ingresa el lanzamiento...', 'checkout_label': 'CIERRE',
        'legs_label': 'Mangas', 'stats': 'Stats',
        'max_score_err': '¡Máximo 180 puntos posibles!', 'bust_msg': '¡Pasado! Vuelve a',
        'checkout_confirm_title': 'Confirmar cierre', 'checkout_confirm_msg': '¿El último dardo dio en un doble (o el bull)?',
        'no': 'NO', 'yes': 'SÍ',
        'wins_match': '¡GANA EL PARTIDO!', 'wins_leg': '¡GANA LA MANGA!',
        'leg_status': 'Resultado de mangas', 'new_leg_q': '¿Iniciar nueva manga?',
        'new_round': 'NUEVA MANGA', 'rematch': 'REVANCHA', 'finish': 'SALIR',
        'stat_avg': 'PROM. (3 DARDOS)', 'stat_legs': 'MANGAS', 'stat_checkout': 'MEJOR CIERRE', 'stat_darts': 'DARDOS',
      },
      'pt': {
        'title': 'Darts X01', 'rules_title': 'Regras do Darts X01', 'ok': 'ENTENDIDO',
        'r_goal_title': 'OBJETIVO', 'r_goal_text': 'Chegue a exatamente 0 pontos.',
        'r_flow_title': 'DESENVOLVIMENTO', 'r_flow_text': 'Cada jogador lança 3 dardos. A soma é subtraída.',
        'r_bust_title': 'BUST (ESTOURO)', 'r_bust_text': 'Se você marcar mais pontos do que resta (ou restar exatamente 1), o lançamento é anulado. Você permanece com a pontuação anterior ao lançamento.',
        'r_double_title': 'DOUBLE-OUT', 'r_double_text': 'Com a regra Double-Out ativada, você deve confirmar que o último dardo acertou um duplo (ou o bull) para vencer o leg.',
        'r_format_title': 'FORMATO DA PARTIDA', 'r_format_text': 'Escolha "Melhor de X Legs" - quem vencer a maioria dos legs primeiro vence a partida.',
        'r_checkout_title': 'SUGESTÕES DE FECHAMENTO', 'r_checkout_text': 'Para uma pontuação restante de até 170, o app mostra um possível fechamento com o menor número de dardos.',
        'add_players_needed': 'Adicione jogadores!', 'add_hint': 'Nome do jogador', 'max_players_err': 'Máximo de 8 jogadores!',
        'game_mode': 'MODO DE JOGO', 'match_format': 'FORMATO DA PARTIDA', 'one_leg': '1 Leg',
        'double_out': 'Double-Out', 'double_out_desc': 'O fechamento deve ser em um duplo/bull',
        'start_btn': 'GAME ON!', 'throw_hint': 'Digite o lançamento...', 'checkout_label': 'FECHAMENTO',
        'legs_label': 'Legs', 'stats': 'Stats',
        'max_score_err': 'Máximo de 180 pontos possíveis!', 'bust_msg': 'Estourou! Volta para',
        'checkout_confirm_title': 'Confirmar fechamento', 'checkout_confirm_msg': 'O último dardo acertou um duplo (ou o bull)?',
        'no': 'NÃO', 'yes': 'SIM',
        'wins_match': 'VENCE A PARTIDA!', 'wins_leg': 'VENCE O LEG!',
        'leg_status': 'Placar de legs', 'new_leg_q': 'Iniciar novo leg?',
        'new_round': 'NOVO LEG', 'rematch': 'REVANCHE', 'finish': 'SAIR',
        'stat_avg': 'MÉDIA (3 DARDOS)', 'stat_legs': 'LEGS', 'stat_checkout': 'MELHOR FECHAMENTO', 'stat_darts': 'DARDOS',
      },
      'nl': {
        'title': 'Darts X01', 'rules_title': 'Darts X01 Regels', 'ok': 'BEGREPEN',
        'r_goal_title': 'DOEL', 'r_goal_text': 'Bereik precies 0 punten.',
        'r_flow_title': 'VERLOOP', 'r_flow_text': 'Elke speler gooit 3 pijltjes. De som wordt afgetrokken.',
        'r_bust_title': 'BUST (OVERWORPEN)', 'r_bust_text': 'Gooi je meer punten dan je nog over hebt (of blijft er precies 1 over), dan vervalt de worp. Je blijft op de score van vóór de worp.',
        'r_double_title': 'DOUBLE-OUT', 'r_double_text': 'Bij ingeschakelde Double-Out regel moet je bevestigen dat je laatste pijltje een dubbel (of bull) raakte om de leg te winnen.',
        'r_format_title': 'WEDSTRIJDFORMAAT', 'r_format_text': 'Kies "Best of X Legs" - wie als eerste de meerderheid van de legs wint, wint de wedstrijd.',
        'r_checkout_title': 'CHECKOUT-SUGGESTIES', 'r_checkout_text': 'Bij een resterende score tot 170 toont de app een mogelijke finish met zo min mogelijk pijltjes.',
        'add_players_needed': 'Voeg spelers toe!', 'add_hint': 'Spelernaam', 'max_players_err': 'Maximaal 8 spelers!',
        'game_mode': 'SPELMODUS', 'match_format': 'WEDSTRIJDFORMAAT', 'one_leg': '1 Leg',
        'double_out': 'Double-Out', 'double_out_desc': 'Checkout moet eindigen op een dubbel/bull',
        'start_btn': 'GAME ON!', 'throw_hint': 'Worp invoeren...', 'checkout_label': 'CHECKOUT',
        'legs_label': 'Legs', 'stats': 'Stats',
        'max_score_err': 'Maximaal 180 punten mogelijk!', 'bust_msg': 'Overworpen! Terug naar',
        'checkout_confirm_title': 'Checkout bevestigen', 'checkout_confirm_msg': 'Raakte het laatste pijltje een dubbel (of bull)?',
        'no': 'NEE', 'yes': 'JA',
        'wins_match': 'WINT DE WEDSTRIJD!', 'wins_leg': 'WINT DE LEG!',
        'leg_status': 'Legstand', 'new_leg_q': 'Nieuwe leg starten?',
        'new_round': 'NIEUWE LEG', 'rematch': 'REVANCHE', 'finish': 'STOPPEN',
        'stat_avg': 'GEM. (3 PIJLEN)', 'stat_legs': 'LEGS', 'stat_checkout': 'BESTE CHECKOUT', 'stat_darts': 'PIJLEN',
      },
      'pl': {
        'title': 'Darts X01', 'rules_title': 'Zasady Darts X01', 'ok': 'ZROZUMIAŁEM',
        'r_goal_title': 'CEL', 'r_goal_text': 'Zdobądź dokładnie 0 punktów.',
        'r_flow_title': 'PRZEBIEG', 'r_flow_text': 'Każdy gracz rzuca 3 lotkami. Suma jest odejmowana.',
        'r_bust_title': 'BUST (PRZERZUT)', 'r_bust_text': 'Jeśli zdobędziesz więcej punktów niż pozostało (lub zostanie dokładnie 1), rzut jest nieważny. Zostajesz przy wyniku sprzed rzutu.',
        'r_double_title': 'DOUBLE-OUT', 'r_double_text': 'Przy włączonej zasadzie Double-Out musisz potwierdzić, że ostatnia lotka trafiła w podwójne pole (lub bull), aby wygrać leg.',
        'r_format_title': 'FORMAT MECZU', 'r_format_text': 'Wybierz "Best of X Legów" - kto pierwszy wygra większość legów, wygrywa mecz.',
        'r_checkout_title': 'PROPOZYCJE ZAKOŃCZENIA', 'r_checkout_text': 'Dla wyniku pozostałego do 170 aplikacja pokazuje możliwe zakończenie z jak najmniejszą liczbą lotek.',
        'add_players_needed': 'Dodaj graczy!', 'add_hint': 'Imię gracza', 'max_players_err': 'Maksymalnie 8 graczy!',
        'game_mode': 'TRYB GRY', 'match_format': 'FORMAT MECZU', 'one_leg': '1 Leg',
        'double_out': 'Double-Out', 'double_out_desc': 'Zakończenie musi paść na podwójnym polu/bullu',
        'start_btn': 'GAME ON!', 'throw_hint': 'Wpisz rzut...', 'checkout_label': 'ZAKOŃCZENIE',
        'legs_label': 'Legi', 'stats': 'Stats',
        'max_score_err': 'Maksymalnie 180 punktów możliwe!', 'bust_msg': 'Przerzut! Powrót do',
        'checkout_confirm_title': 'Potwierdź zakończenie', 'checkout_confirm_msg': 'Czy ostatnia lotka trafiła w podwójne pole (lub bulla)?',
        'no': 'NIE', 'yes': 'TAK',
        'wins_match': 'WYGRYWA MECZ!', 'wins_leg': 'WYGRYWA LEGA!',
        'leg_status': 'Stan legów', 'new_leg_q': 'Rozpocząć nowego lega?',
        'new_round': 'NOWY LEG', 'rematch': 'REWANŻ', 'finish': 'ZAKOŃCZ',
        'stat_avg': 'ŚREDNIA (3 LOTKI)', 'stat_legs': 'LEGI', 'stat_checkout': 'NAJLEPSZE ZAKOŃCZENIE', 'stat_darts': 'LOTKI',
      },
      'tr': {
        'title': 'Darts X01', 'rules_title': 'Darts X01 Kuralları', 'ok': 'ANLADIM',
        'r_goal_title': 'HEDEF', 'r_goal_text': 'Tam olarak 0 puana ulaş.',
        'r_flow_title': 'AKIŞ', 'r_flow_text': 'Her oyuncu 3 dart atar. Toplam puandan düşülür.',
        'r_bust_title': 'BUST (FAZLA ATIŞ)', 'r_bust_text': 'Kalan puanından fazla puan atarsan (ya da tam olarak 1 kalırsa) atış geçersiz sayılır. Atıştan önceki skorda kalırsın.',
        'r_double_title': 'DOUBLE-OUT', 'r_double_text': 'Double-Out kuralı aktifken, legi kazanmak için son dartının bir double (veya bull) vurduğunu onaylaman gerekir.',
        'r_format_title': 'MAÇ FORMATI', 'r_format_text': '"Best of X Leg" seç - leglerin çoğunluğunu önce kazanan maçı kazanır.',
        'r_checkout_title': 'ÇIKIŞ ÖNERİLERİ', 'r_checkout_text': '170\'e kadar kalan skorlar için uygulama, en az dart ile mümkün bir çıkışı gösterir.',
        'add_players_needed': 'Lütfen oyuncu ekleyin!', 'add_hint': 'Oyuncu Adı', 'max_players_err': 'En fazla 8 oyuncu!',
        'game_mode': 'OYUN MODU', 'match_format': 'MAÇ FORMATI', 'one_leg': '1 Leg',
        'double_out': 'Double-Out', 'double_out_desc': 'Çıkış bir double/bull ile bitmeli',
        'start_btn': 'GAME ON!', 'throw_hint': 'Atışı girin...', 'checkout_label': 'ÇIKIŞ',
        'legs_label': 'Legler', 'stats': 'Stats',
        'max_score_err': 'En fazla 180 puan mümkün!', 'bust_msg': 'Fazla attın! Şuraya dön:',
        'checkout_confirm_title': 'Çıkışı onayla', 'checkout_confirm_msg': 'Son dart bir double (veya bull) mü vurdu?',
        'no': 'HAYIR', 'yes': 'EVET',
        'wins_match': 'MAÇI KAZANDI!', 'wins_leg': 'LEGİ KAZANDI!',
        'leg_status': 'Leg skoru', 'new_leg_q': 'Yeni leg başlatılsın mı?',
        'new_round': 'YENİ LEG', 'rematch': 'RÖVANŞ', 'finish': 'BİTİR',
        'stat_avg': 'ORT. (3 DART)', 'stat_legs': 'LEGLER', 'stat_checkout': 'EN İYİ ÇIKIŞ', 'stat_darts': 'DARTLAR',
      },
      'id': {
        'title': 'Darts X01', 'rules_title': 'Aturan Darts X01', 'ok': 'MENGERTI',
        'r_goal_title': 'TUJUAN', 'r_goal_text': 'Capai tepat 0 poin.',
        'r_flow_title': 'ALUR', 'r_flow_text': 'Setiap pemain melempar 3 anak panah. Jumlahnya dikurangi.',
        'r_bust_title': 'BUST (GAGAL)', 'r_bust_text': 'Jika skor Anda melebihi sisa poin (atau tersisa tepat 1), lemparan dibatalkan. Anda tetap pada skor sebelum lemparan.',
        'r_double_title': 'DOUBLE-OUT', 'r_double_text': 'Dengan aturan Double-Out aktif, Anda harus mengonfirmasi bahwa anak panah terakhir mengenai double (atau bull) untuk memenangkan leg.',
        'r_format_title': 'FORMAT PERTANDINGAN', 'r_format_text': 'Pilih "Best of X Leg" - yang pertama memenangkan mayoritas leg memenangkan pertandingan.',
        'r_checkout_title': 'SARAN CHECKOUT', 'r_checkout_text': 'Untuk sisa skor hingga 170, aplikasi menampilkan kemungkinan penyelesaian dengan anak panah paling sedikit.',
        'add_players_needed': 'Silakan tambahkan pemain!', 'add_hint': 'Nama Pemain', 'max_players_err': 'Maksimal 8 pemain!',
        'game_mode': 'MODE PERMAINAN', 'match_format': 'FORMAT PERTANDINGAN', 'one_leg': '1 Leg',
        'double_out': 'Double-Out', 'double_out_desc': 'Checkout harus berakhir pada double/bull',
        'start_btn': 'GAME ON!', 'throw_hint': 'Masukkan lemparan...', 'checkout_label': 'CHECKOUT',
        'legs_label': 'Leg', 'stats': 'Stats',
        'max_score_err': 'Maksimal 180 poin dimungkinkan!', 'bust_msg': 'Gagal! Kembali ke',
        'checkout_confirm_title': 'Konfirmasi checkout', 'checkout_confirm_msg': 'Apakah anak panah terakhir mengenai double (atau bull)?',
        'no': 'TIDAK', 'yes': 'YA',
        'wins_match': 'MEMENANGKAN PERTANDINGAN!', 'wins_leg': 'MEMENANGKAN LEG!',
        'leg_status': 'Skor leg', 'new_leg_q': 'Mulai leg baru?',
        'new_round': 'LEG BARU', 'rematch': 'TANDING ULANG', 'finish': 'SELESAI',
        'stat_avg': 'RATA2 (3 PANAH)', 'stat_legs': 'LEG', 'stat_checkout': 'CHECKOUT TERBAIK', 'stat_darts': 'ANAK PANAH',
      },
      'sv': {
        'title': 'Darts X01', 'rules_title': 'Darts X01-regler', 'ok': 'FÖRSTÅTT',
        'r_goal_title': 'MÅL', 'r_goal_text': 'Nå exakt 0 poäng.',
        'r_flow_title': 'FÖRLOPP', 'r_flow_text': 'Varje spelare kastar 3 pilar. Summan dras av.',
        'r_bust_title': 'BUST (ÖVERKASTAD)', 'r_bust_text': 'Om du får fler poäng än du har kvar (eller exakt 1 återstår) ogiltigförklaras kastet. Du stannar på poängen från före kastet.',
        'r_double_title': 'DOUBLE-OUT', 'r_double_text': 'Med Double-Out aktiverat måste du bekräfta att din sista pil träffade en dubbel (eller bull) för att vinna legen.',
        'r_format_title': 'MATCHFORMAT', 'r_format_text': 'Välj "Best of X Legs" - den som först vinner majoriteten av legsen vinner matchen.',
        'r_checkout_title': 'CHECKOUT-FÖRSLAG', 'r_checkout_text': 'Vid en återstående poäng upp till 170 visar appen ett möjligt avslut med så få pilar som möjligt.',
        'add_players_needed': 'Lägg till spelare!', 'add_hint': 'Spelarnamn', 'max_players_err': 'Max 8 spelare!',
        'game_mode': 'SPELLÄGE', 'match_format': 'MATCHFORMAT', 'one_leg': '1 Leg',
        'double_out': 'Double-Out', 'double_out_desc': 'Checkout måste avslutas på en dubbel/bull',
        'start_btn': 'GAME ON!', 'throw_hint': 'Ange kast...', 'checkout_label': 'CHECKOUT',
        'legs_label': 'Legs', 'stats': 'Stats',
        'max_score_err': 'Max 180 poäng möjligt!', 'bust_msg': 'Överkastad! Tillbaka till',
        'checkout_confirm_title': 'Bekräfta checkout', 'checkout_confirm_msg': 'Träffade den sista pilen en dubbel (eller bull)?',
        'no': 'NEJ', 'yes': 'JA',
        'wins_match': 'VINNER MATCHEN!', 'wins_leg': 'VINNER LEGEN!',
        'leg_status': 'Legställning', 'new_leg_q': 'Starta ny leg?',
        'new_round': 'NY LEG', 'rematch': 'REVANSCH', 'finish': 'AVSLUTA',
        'stat_avg': 'SNITT (3 PILAR)', 'stat_legs': 'LEGS', 'stat_checkout': 'BÄSTA CHECKOUT', 'stat_darts': 'PILAR',
      },
      'hr': {
        'title': 'Darts X01', 'rules_title': 'Pravila Darts X01', 'ok': 'RAZUMIJEM',
        'r_goal_title': 'CILJ', 'r_goal_text': 'Dosegni točno 0 bodova.',
        'r_flow_title': 'TIJEK', 'r_flow_text': 'Svaki igrač baca 3 strelice. Zbroj se oduzima.',
        'r_bust_title': 'BUST (PREBAČAJ)', 'r_bust_text': 'Ako osvojiš više bodova nego što ti je ostalo (ili ostane točno 1), bacanje se poništava. Ostaješ na rezultatu prije bacanja.',
        'r_double_title': 'DOUBLE-OUT', 'r_double_text': 'Uz uključeno pravilo Double-Out moraš potvrditi da je zadnja strelica pogodila duplo polje (ili bull) da bi pobijedio u legu.',
        'r_format_title': 'FORMAT MEČA', 'r_format_text': 'Odaberi "Best of X Legova" - tko prvi osvoji većinu legova pobjeđuje u meču.',
        'r_checkout_title': 'PRIJEDLOZI ZAVRŠETKA', 'r_checkout_text': 'Za preostali rezultat do 170 aplikacija prikazuje mogući završetak s najmanje strelica.',
        'add_players_needed': 'Molimo dodaj igrače!', 'add_hint': 'Ime igrača', 'max_players_err': 'Maksimalno 8 igrača!',
        'game_mode': 'NAČIN IGRE', 'match_format': 'FORMAT MEČA', 'one_leg': '1 Leg',
        'double_out': 'Double-Out', 'double_out_desc': 'Završetak mora biti na duplom polju/bullu',
        'start_btn': 'GAME ON!', 'throw_hint': 'Unesi bacanje...', 'checkout_label': 'ZAVRŠETAK',
        'legs_label': 'Legovi', 'stats': 'Stats',
        'max_score_err': 'Maksimalno 180 bodova moguće!', 'bust_msg': 'Prebačaj! Povratak na',
        'checkout_confirm_title': 'Potvrdi završetak', 'checkout_confirm_msg': 'Je li zadnja strelica pogodila duplo polje (ili bull)?',
        'no': 'NE', 'yes': 'DA',
        'wins_match': 'POBJEĐUJE U MEČU!', 'wins_leg': 'POBJEĐUJE U LEGU!',
        'leg_status': 'Rezultat legova', 'new_leg_q': 'Započeti novi leg?',
        'new_round': 'NOVI LEG', 'rematch': 'UZVRAT', 'finish': 'ZAVRŠI',
        'stat_avg': 'PROSJEK (3 STRELICE)', 'stat_legs': 'LEGOVI', 'stat_checkout': 'NAJBOLJI ZAVRŠETAK', 'stat_darts': 'STRELICE',
      },
      'ru': {
        'title': 'Дартс X01', 'rules_title': 'Правила Дартс X01', 'ok': 'ПОНЯТНО',
        'r_goal_title': 'ЦЕЛЬ', 'r_goal_text': 'Набрать ровно 0 очков.',
        'r_flow_title': 'ХОД ИГРЫ', 'r_flow_text': 'Каждый игрок бросает 3 дротика. Сумма вычитается.',
        'r_bust_title': 'BUST (ПЕРЕБОР)', 'r_bust_text': 'Если вы наберёте больше очков, чем осталось (или останется ровно 1), бросок аннулируется. Вы остаётесь на счёте до броска.',
        'r_double_title': 'DOUBLE-OUT', 'r_double_text': 'При включённом правиле Double-Out нужно подтвердить, что последний дротик попал в дубль (или булл), чтобы выиграть лег.',
        'r_format_title': 'ФОРМАТ МАТЧА', 'r_format_text': 'Выберите "Best of X Легов" - кто первым выиграет большинство легов, побеждает в матче.',
        'r_checkout_title': 'ПОДСКАЗКИ ВЫХОДА', 'r_checkout_text': 'Для оставшегося счёта до 170 приложение показывает возможный выход с наименьшим числом дротиков.',
        'add_players_needed': 'Пожалуйста, добавьте игроков!', 'add_hint': 'Имя игрока', 'max_players_err': 'Максимум 8 игроков!',
        'game_mode': 'РЕЖИМ ИГРЫ', 'match_format': 'ФОРМАТ МАТЧА', 'one_leg': '1 Лег',
        'double_out': 'Double-Out', 'double_out_desc': 'Выход должен закончиться дублем/буллом',
        'start_btn': 'GAME ON!', 'throw_hint': 'Введите бросок...', 'checkout_label': 'ВЫХОД',
        'legs_label': 'Леги', 'stats': 'Stats',
        'max_score_err': 'Максимум 180 очков возможно!', 'bust_msg': 'Перебор! Назад к',
        'checkout_confirm_title': 'Подтвердите выход', 'checkout_confirm_msg': 'Последний дротик попал в дубль (или булл)?',
        'no': 'НЕТ', 'yes': 'ДА',
        'wins_match': 'ВЫИГРЫВАЕТ МАТЧ!', 'wins_leg': 'ВЫИГРЫВАЕТ ЛЕГ!',
        'leg_status': 'Счёт по легам', 'new_leg_q': 'Начать новый лег?',
        'new_round': 'НОВЫЙ ЛЕГ', 'rematch': 'РЕВАНШ', 'finish': 'ЗАВЕРШИТЬ',
        'stat_avg': 'СРЕДНЕЕ (3 ДРОТИКА)', 'stat_legs': 'ЛЕГИ', 'stat_checkout': 'ЛУЧШИЙ ВЫХОД', 'stat_darts': 'ДРОТИКИ',
      },
      'ja': {
        'title': 'ダーツ X01', 'rules_title': 'ダーツ X01 ルール', 'ok': '了解',
        'r_goal_title': '目標', 'r_goal_text': 'ちょうど0点にする。',
        'r_flow_title': '流れ', 'r_flow_text': '各プレイヤーは3本のダーツを投げます。合計が引かれます。',
        'r_bust_title': 'バスト（投げ過ぎ）', 'r_bust_text': '残り点数より多く得点した場合（またはちょうど1が残る場合）、そのスローは無効になります。スロー前のスコアのままになります。',
        'r_double_title': 'ダブルアウト', 'r_double_text': 'ダブルアウトが有効な場合、レグに勝つには最後のダーツがダブル（またはブル）に当たったことを確認する必要があります。',
        'r_format_title': 'マッチ形式', 'r_format_text': '「ベストオブXレグ」を選択 - 先にレグの過半数を獲得した方がマッチに勝ちます。',
        'r_checkout_title': 'チェックアウト提案', 'r_checkout_text': '残り点数が170以下の場合、アプリは最少本数で決められるフィニッシュ例を表示します。',
        'add_players_needed': 'プレイヤーを追加してください！', 'add_hint': 'プレイヤー名', 'max_players_err': '最大8人まで！',
        'game_mode': 'ゲームモード', 'match_format': 'マッチ形式', 'one_leg': '1レグ',
        'double_out': 'ダブルアウト', 'double_out_desc': 'チェックアウトはダブル/ブルで終える必要があります',
        'start_btn': 'GAME ON!', 'throw_hint': 'スローを入力...', 'checkout_label': 'チェックアウト',
        'legs_label': 'レグ', 'stats': '統計',
        'max_score_err': '最大180点まで可能です！', 'bust_msg': 'バスト！戻ります：',
        'checkout_confirm_title': 'チェックアウトの確認', 'checkout_confirm_msg': '最後のダーツはダブル（またはブル）に当たりましたか？',
        'no': 'いいえ', 'yes': 'はい',
        'wins_match': 'マッチ勝利！', 'wins_leg': 'レグ勝利！',
        'leg_status': 'レグスコア', 'new_leg_q': '新しいレグを開始しますか？',
        'new_round': '新しいレグ', 'rematch': '再戦', 'finish': '終了',
        'stat_avg': '平均（3本）', 'stat_legs': 'レグ', 'stat_checkout': 'ベストチェックアウト', 'stat_darts': 'ダーツ数',
      },
      'ko': {
        'title': '다트 X01', 'rules_title': '다트 X01 규칙', 'ok': '확인',
        'r_goal_title': '목표', 'r_goal_text': '정확히 0점에 도달하세요.',
        'r_flow_title': '진행 방식', 'r_flow_text': '각 플레이어는 다트 3개를 던집니다. 합계가 차감됩니다.',
        'r_bust_title': '버스트(오버스로우)', 'r_bust_text': '남은 점수보다 많이 득점하거나 정확히 1점이 남으면 해당 투척은 무효가 됩니다. 투척 전 점수로 유지됩니다.',
        'r_double_title': '더블 아웃', 'r_double_text': '더블 아웃 규칙이 켜져 있으면, 레그에서 승리하려면 마지막 다트가 더블(또는 불)에 맞았는지 확인해야 합니다.',
        'r_format_title': '경기 형식', 'r_format_text': '"베스트 오브 X 레그"를 선택하세요 - 먼저 레그의 과반수를 이긴 사람이 경기에서 승리합니다.',
        'r_checkout_title': '체크아웃 제안', 'r_checkout_text': '남은 점수가 170 이하일 때 앱이 최소 다트 수로 마무리할 수 있는 방법을 보여줍니다.',
        'add_players_needed': '플레이어를 추가하세요!', 'add_hint': '플레이어 이름', 'max_players_err': '최대 8명까지!',
        'game_mode': '게임 모드', 'match_format': '경기 형식', 'one_leg': '1 레그',
        'double_out': '더블 아웃', 'double_out_desc': '체크아웃은 더블/불로 끝나야 합니다',
        'start_btn': 'GAME ON!', 'throw_hint': '투척 입력...', 'checkout_label': '체크아웃',
        'legs_label': '레그', 'stats': '통계',
        'max_score_err': '최대 180점까지 가능합니다!', 'bust_msg': '버스트! 되돌아갑니다:',
        'checkout_confirm_title': '체크아웃 확인', 'checkout_confirm_msg': '마지막 다트가 더블(또는 불)에 맞았나요?',
        'no': '아니요', 'yes': '예',
        'wins_match': '경기 승리!', 'wins_leg': '레그 승리!',
        'leg_status': '레그 스코어', 'new_leg_q': '새 레그를 시작할까요?',
        'new_round': '새 레그', 'rematch': '재대결', 'finish': '종료',
        'stat_avg': '평균 (3다트)', 'stat_legs': '레그', 'stat_checkout': '최고 체크아웃', 'stat_darts': '다트 수',
      },
      'zh': {
        'title': '飞镖 X01', 'rules_title': '飞镖 X01 规则', 'ok': '明白了',
        'r_goal_title': '目标', 'r_goal_text': '正好达到0分。',
        'r_flow_title': '流程', 'r_flow_text': '每位玩家投掷3支飞镖，总和从分数中扣除。',
        'r_bust_title': '爆分（超出）', 'r_bust_text': '如果得分超过剩余分数（或剩余正好为1），该轮投掷无效，分数保持投掷前的状态。',
        'r_double_title': '双倍结束', 'r_double_text': '启用双倍结束规则后，你必须确认最后一支飞镖命中双倍区（或红心）才能赢得该局。',
        'r_format_title': '比赛格式', 'r_format_text': '选择"X局N胜制" - 先赢得多数局的一方获胜。',
        'r_checkout_title': '结束建议', 'r_checkout_text': '当剩余分数不超过170时，应用会显示用最少飞镖数完成的可能方案。',
        'add_players_needed': '请添加玩家！', 'add_hint': '玩家姓名', 'max_players_err': '最多8名玩家！',
        'game_mode': '游戏模式', 'match_format': '比赛格式', 'one_leg': '1局',
        'double_out': '双倍结束', 'double_out_desc': '结束必须命中双倍区/红心',
        'start_btn': '开始游戏！', 'throw_hint': '输入投掷...', 'checkout_label': '结束',
        'legs_label': '局数', 'stats': '统计',
        'max_score_err': '最多可投180分！', 'bust_msg': '爆分！回到',
        'checkout_confirm_title': '确认结束', 'checkout_confirm_msg': '最后一支飞镖是否命中双倍区（或红心）？',
        'no': '否', 'yes': '是',
        'wins_match': '赢得比赛！', 'wins_leg': '赢得该局！',
        'leg_status': '局分', 'new_leg_q': '开始新的一局？',
        'new_round': '新的一局', 'rematch': '再来一局', 'finish': '结束',
        'stat_avg': '平均分（3镖）', 'stat_legs': '局数', 'stat_checkout': '最佳结束', 'stat_darts': '飞镖数',
      },
      'hi': {
        'title': 'डार्ट्स X01', 'rules_title': 'डार्ट्स X01 नियम', 'ok': 'समझ गया',
        'r_goal_title': 'लक्ष्य', 'r_goal_text': 'ठीक 0 अंक तक पहुंचें।',
        'r_flow_title': 'प्रक्रिया', 'r_flow_text': 'हर खिलाड़ी 3 डार्ट्स फेंकता है। योग घटाया जाता है।',
        'r_bust_title': 'बस्ट (अधिक अंक)', 'r_bust_text': 'यदि आप शेष अंकों से अधिक अंक बनाते हैं (या ठीक 1 बचता है), तो थ्रो रद्द हो जाता है। आप थ्रो से पहले वाले स्कोर पर रहते हैं।',
        'r_double_title': 'डबल-आउट', 'r_double_text': 'डबल-आउट नियम सक्रिय होने पर, लेग जीतने के लिए आपको पुष्टि करनी होगी कि आपका आखिरी डार्ट डबल (या बुल) पर लगा।',
        'r_format_title': 'मैच फॉर्मेट', 'r_format_text': '"बेस्ट ऑफ X लेग्स" चुनें - जो पहले अधिकांश लेग जीतता है वह मैच जीतता है।',
        'r_checkout_title': 'चेकआउट सुझाव', 'r_checkout_text': '170 तक के शेष स्कोर के लिए ऐप सबसे कम डार्ट्स के साथ संभव फिनिश दिखाता है।',
        'add_players_needed': 'कृपया खिलाड़ी जोड़ें!', 'add_hint': 'खिलाड़ी का नाम', 'max_players_err': 'अधिकतम 8 खिलाड़ी!',
        'game_mode': 'गेम मोड', 'match_format': 'मैच फॉर्मेट', 'one_leg': '1 लेग',
        'double_out': 'डबल-आउट', 'double_out_desc': 'चेकआउट डबल/बुल पर समाप्त होना चाहिए',
        'start_btn': 'GAME ON!', 'throw_hint': 'थ्रो दर्ज करें...', 'checkout_label': 'चेकआउट',
        'legs_label': 'लेग्स', 'stats': 'आंकड़े',
        'max_score_err': 'अधिकतम 180 अंक संभव!', 'bust_msg': 'बस्ट! वापस जाएं:',
        'checkout_confirm_title': 'चेकआउट की पुष्टि करें', 'checkout_confirm_msg': 'क्या आखिरी डार्ट डबल (या बुल) पर लगा?',
        'no': 'नहीं', 'yes': 'हां',
        'wins_match': 'मैच जीता!', 'wins_leg': 'लेग जीता!',
        'leg_status': 'लेग स्कोर', 'new_leg_q': 'नया लेग शुरू करें?',
        'new_round': 'नया लेग', 'rematch': 'रीमैच', 'finish': 'समाप्त करें',
        'stat_avg': 'औसत (3 डार्ट्स)', 'stat_legs': 'लेग्स', 'stat_checkout': 'सर्वश्रेष्ठ चेकआउट', 'stat_darts': 'डार्ट्स',
      },
      'bn': {
        'title': 'ডার্টস X01', 'rules_title': 'ডার্টস X01 নিয়ম', 'ok': 'বুঝেছি',
        'r_goal_title': 'লক্ষ্য', 'r_goal_text': 'ঠিক ০ পয়েন্টে পৌঁছান।',
        'r_flow_title': 'প্রক্রিয়া', 'r_flow_text': 'প্রতিটি খেলোয়াড় ৩টি ডার্ট নিক্ষেপ করে। যোগফল বিয়োগ করা হয়।',
        'r_bust_title': 'বাস্ট (অতিরিক্ত)', 'r_bust_text': 'যদি আপনি অবশিষ্ট পয়েন্টের চেয়ে বেশি স্কোর করেন (অথবা ঠিক ১ অবশিষ্ট থাকে), তাহলে থ্রোটি বাতিল হয়ে যায়। আপনি থ্রোর আগের স্কোরে থাকবেন।',
        'r_double_title': 'ডাবল-আউট', 'r_double_text': 'ডাবল-আউট নিয়ম চালু থাকলে, লেগ জিততে আপনাকে নিশ্চিত করতে হবে যে আপনার শেষ ডার্টটি ডাবল (বা বুল) এ লেগেছে।',
        'r_format_title': 'ম্যাচ ফরম্যাট', 'r_format_text': '"বেস্ট অফ X লেগ" বেছে নিন - যে প্রথমে অধিকাংশ লেগ জেতে সে ম্যাচ জেতে।',
        'r_checkout_title': 'চেকআউট পরামর্শ', 'r_checkout_text': '১৭০ পর্যন্ত অবশিষ্ট স্কোরের জন্য অ্যাপ সবচেয়ে কম ডার্টে সম্ভাব্য সমাপ্তি দেখায়।',
        'add_players_needed': 'অনুগ্রহ করে খেলোয়াড় যোগ করুন!', 'add_hint': 'খেলোয়াড়ের নাম', 'max_players_err': 'সর্বোচ্চ ৮ জন খেলোয়াড়!',
        'game_mode': 'গেম মোড', 'match_format': 'ম্যাচ ফরম্যাট', 'one_leg': '১ লেগ',
        'double_out': 'ডাবল-আউট', 'double_out_desc': 'চেকআউট অবশ্যই ডাবল/বুলে শেষ হতে হবে',
        'start_btn': 'GAME ON!', 'throw_hint': 'থ্রো লিখুন...', 'checkout_label': 'চেকআউট',
        'legs_label': 'লেগ', 'stats': 'পরিসংখ্যান',
        'max_score_err': 'সর্বোচ্চ ১৮০ পয়েন্ট সম্ভব!', 'bust_msg': 'বাস্ট! ফিরে যান:',
        'checkout_confirm_title': 'চেকআউট নিশ্চিত করুন', 'checkout_confirm_msg': 'শেষ ডার্টটি কি ডাবল (বা বুল) এ লেগেছে?',
        'no': 'না', 'yes': 'হ্যাঁ',
        'wins_match': 'ম্যাচ জিতেছে!', 'wins_leg': 'লেগ জিতেছে!',
        'leg_status': 'লেগ স্কোর', 'new_leg_q': 'নতুন লেগ শুরু করবেন?',
        'new_round': 'নতুন লেগ', 'rematch': 'রিম্যাচ', 'finish': 'শেষ করুন',
        'stat_avg': 'গড় (৩ ডার্ট)', 'stat_legs': 'লেগ', 'stat_checkout': 'সেরা চেকআউট', 'stat_darts': 'ডার্ট',
      },
    };

    if (dictionary.containsKey(_currentLang) && dictionary[_currentLang]!.containsKey(key)) {
      return dictionary[_currentLang]![key]!;
    }
    return dictionary['en']![key] ?? key;
  }

  // --- LOGIK: SETUP ---

  void _addPlayer() {
    if (_nameController.text.trim().isNotEmpty) {
      if (_players.length >= 8) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('max_players_err'))));
        return;
      }
      setState(() {
        _players.add(DartPlayer(name: _nameController.text.trim(), startScore: _startScore));
        _nameController.clear();
      });
      _persist();
    }
  }

  void _startGame() {
    FocusScope.of(context).unfocus(); // Tastatur weg
    if (_players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('add_players_needed'))));
      return;
    }
    // Scores initialisieren falls Modus geändert wurde
    for (var p in _players) {
      p.currentScore = _startScore;
      p.history.clear();
      p.legsWon = 0;
      p.dartsThrown = 0;
      p.totalScored = 0;
      p.bestCheckout = 0;
    }
    setState(() {
      _gameStarted = true;
      _currentPlayerIndex = 0;
      _currentInput = "";
    });
    _persist();
  }

  void _showStats() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DartsStatsSheet(
        players: _players,
        primaryColor: primaryColor,
        surfaceColor: surfaceColor,
        titleLabel: _t('stats'),
        avgLabel: _t('stat_avg'),
        legsLabel: _t('stat_legs'),
        checkoutLabel: _t('stat_checkout'),
        dartsLabel: _t('stat_darts'),
      ),
    );
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
            Flexible(child: Text(_t('rules_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_t('r_goal_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(_t('r_goal_text'), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              Text(_t('r_flow_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(_t('r_flow_text'), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              Text(_t('r_bust_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(_t('r_bust_text'), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              Text(_t('r_double_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(_t('r_double_text'), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              Text(_t('r_format_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(_t('r_format_text'), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              Text(_t('r_checkout_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(_t('r_checkout_text'), style: const TextStyle(color: Colors.white70)),
            ],
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

  // --- LOGIK: GAMEPLAY ---

  void _onKeypadTap(String value) {
    if (value == "OK") {
      _submitScore();
    } else if (value == "DEL") {
      if (_currentInput.isNotEmpty) {
        setState(() {
          _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        });
        _persist();
      }
    } else {
      // Zahlen eingeben (max 3 Stellen, da 180 das Maximum ist)
      if (_currentInput.length < 3) {
        setState(() {
          _currentInput += value;
        });
        _persist();
      }
    }
  }

  Future<void> _submitScore() async {
    if (_currentInput.isEmpty) return;
    int scoreThrown = int.tryParse(_currentInput) ?? 0;

    // Validierung: Man kann nicht mehr als 180 werfen
    if (scoreThrown > 180) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: errorColor, content: Text(_t('max_score_err'))));
      setState(() => _currentInput = "");
      return;
    }

    DartPlayer player = _players[_currentPlayerIndex];
    int scoreBefore = player.currentScore;
    int newScore = player.currentScore - scoreThrown;

    bool isBust = newScore < 0 || newScore == 1;

    // Bei aktivem Double-Out: Checkout muss bestätigt werden (letzter Pfeil = Doppel/Bull)
    if (!isBust && newScore == 0 && _doubleOutEnabled) {
      bool? finishedOnDouble = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: primaryColor)),
          title: Text(_t('checkout_confirm_title'), style: const TextStyle(color: Colors.white)),
          content: Text(_t('checkout_confirm_msg'), style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(_t('no'), style: const TextStyle(color: Colors.grey))),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(_t('yes'), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))),
          ],
        ),
      );
      if (finishedOnDouble != true) {
        isBust = true;
        newScore = scoreBefore; // Wurf zählt nicht, Bust
      }
    }

    if (!mounted) return;

    setState(() {
      // Darts gezählt (auch bei Bust, wie im echten Spiel)
      player.dartsThrown += 3;

      if (newScore == 0 && !isBust) {
        // GEWONNEN!
        player.currentScore = 0;
        player.totalScored += scoreThrown;
        if (scoreThrown > player.bestCheckout) player.bestCheckout = scoreThrown;
      } else if (isBust) {
        // BUST! Score bleibt unverändert.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: errorColor,
          content: Text("${_t('bust_msg')} $scoreBefore"),
          duration: const Duration(seconds: 1),
        ));
      } else {
        // Gültiger Wurf
        player.currentScore = newScore;
        player.totalScored += scoreThrown;
      }

      // Input leeren & Nächster Spieler
      _currentInput = "";
      if (!(newScore == 0 && !isBust)) {
        _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
      }
    });
    _persist();

    if (newScore == 0 && !isBust) {
      _showWinnerDialog(player);
    }
  }

  void _showWinnerDialog(DartPlayer winner) {
    bool matchWon = winner.legsWon + 1 >= _legsToWin;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: primaryColor, width: 3)),
        title: Column(
          children: [
            const Icon(Icons.emoji_events, size: 60, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              "${winner.name} ${matchWon ? _t('wins_match') : _t('wins_leg')}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          matchWon
              ? "${_t('leg_status')}: ${winner.legsWon + 1}"
              : "${_t('leg_status')}: ${winner.legsWon + 1} / $_legsToWin\n\n${_t('new_leg_q')}",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          if (!matchWon)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  // Reset für neues Leg (gleiche Spieler)
                  winner.legsWon++;
                  for (var p in _players) {
                    p.currentScore = _startScore;
                  }
                  _currentPlayerIndex = 0;
                });
                _persist();
              },
              child: Text(_t('new_round'), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
          if (matchWon)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  winner.legsWon++;
                  for (var p in _players) {
                    p.legsWon = 0;
                    p.currentScore = _startScore;
                    p.dartsThrown = 0;
                    p.totalScored = 0;
                    p.bestCheckout = 0;
                  }
                  _currentPlayerIndex = 0;
                });
                _persist();
              },
              child: Text(_t('rematch'), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _gameStarted = false; // Zurück zum Setup
                _players.clear();
              });
              GamePersistence.clear(gameId);
            },
            child: Text(_t('finish'), style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(_t('title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: primaryColor,
        actions: [
          if (_gameStarted)
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: _showStats,
              tooltip: _t('stats'),
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showRules,
          )
        ],
      ),
      body: SafeArea(
        child: _gameStarted ? _buildGameScreen() : _buildSetupScreen(),
      ),
    );
  }

  // SCREEN 1: SETUP
  Widget _buildSetupScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.track_changes, size: 80, color: primaryColor),
          const SizedBox(height: 20),
          Text(_t('game_mode'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [301, 501, 701].map((score) {
              bool isSelected = _startScore == score;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ChoiceChip(
                  label: Text("$score", style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                  selected: isSelected,
                  selectedColor: primaryColor,
                  backgroundColor: surfaceColor,
                  checkmarkColor: Colors.black,
                  onSelected: (val) {
                    setState(() => _startScore = score);
                    _persist();
                  },
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 25),
          Text(_t('match_format'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [1, 3, 5, 7].map((bo) {
              bool isSelected = _bestOf == bo;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ChoiceChip(
                  label: Text(bo == 1 ? _t('one_leg') : "Bo$bo", style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                  selected: isSelected,
                  selectedColor: primaryColor,
                  backgroundColor: surfaceColor,
                  checkmarkColor: Colors.black,
                  onSelected: (val) {
                    setState(() => _bestOf = bo);
                    _persist();
                  },
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: primaryColor,
              title: Text(_t('double_out'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(_t('double_out_desc'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              value: _doubleOutEnabled,
              onChanged: (val) {
                setState(() => _doubleOutEnabled = val);
                _persist();
              },
            ),
          ),

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
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
                  ),
                  onSubmitted: (_) => _addPlayer(),
                ),
              ),
              IconButton(onPressed: _addPlayer, icon: Icon(Icons.add_circle, color: primaryColor, size: 40)),
            ],
          ),
          const SizedBox(height: 20),
          // Spieler Liste Vorschau
          if (_players.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _players.length,
                itemBuilder: (context, index) => Card(
                  color: surfaceColor,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.black26, child: Text("${index+1}", style: const TextStyle(color: Colors.white))),
                    title: Text(_players[index].name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    trailing: IconButton(
                      icon: Icon(Icons.close, color: errorColor),
                      onPressed: () {
                        setState(() => _players.removeAt(index));
                        _persist();
                      },
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black),
              child: Text(_t('start_btn'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
          ),
        ],
      ),
    );
  }

  // SCREEN 2: GAME
  Widget _buildGameScreen() {
    return Column(
      children: [
        // --- SCOREBOARD ---
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(10),
            itemCount: _players.length,
            itemBuilder: (context, index) {
              final p = _players[index];
              final isTurn = index == _currentPlayerIndex;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isTurn ? primaryColor.withAlpha(40) : surfaceColor,
                  borderRadius: BorderRadius.circular(15),
                  border: isTurn ? Border.all(color: primaryColor, width: 2) : Border.all(color: Colors.transparent, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: TextStyle(color: isTurn ? primaryColor : Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        if(p.legsWon > 0)
                          Text("${_t('legs_label')}: ${p.legsWon}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    Text(
                        "${p.currentScore}",
                        style: TextStyle(
                            color: isTurn ? Colors.white : Colors.white54,
                            fontSize: 32,
                            fontWeight: FontWeight.w900
                        )
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // --- CHECKOUT VORSCHLAG ---
        if (_currentInput.isEmpty) _buildCheckoutHint(),

        // --- INPUT DISPLAY ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          color: Colors.black26,
          child: Center(
            child: Text(
              _currentInput.isEmpty ? _t('throw_hint') : _currentInput,
              style: TextStyle(
                  color: _currentInput.isEmpty ? Colors.white24 : primaryColor,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2
              ),
            ),
          ),
        ),

        // --- CUSTOM KEYPAD ---
        Container(
          color: surfaceColor,
          padding: const EdgeInsets.only(bottom: 10, top: 10),
          child: Column(
            children: [
              _buildKeypadRow(["1", "2", "3"]),
              _buildKeypadRow(["4", "5", "6"]),
              _buildKeypadRow(["7", "8", "9"]),
              _buildKeypadRow(["DEL", "0", "OK"]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutHint() {
    DartPlayer player = _players[_currentPlayerIndex];
    List<String>? suggestion = CheckoutHelper.suggest(player.currentScore);
    if (suggestion == null) return const SizedBox(height: 0);

    return Container(
      width: double.infinity,
      color: primaryColor.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          "${_t('checkout_label')}: ${suggestion.join(' → ')}",
          style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((key) {
          bool isAction = key == "DEL" || key == "OK";
          return SizedBox(
            width: 100, // Feste Breite für Tasten
            height: 60,
            child: ElevatedButton(
              onPressed: () => _onKeypadTap(key),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAction ? (key == "OK" ? primaryColor : Colors.grey.shade800) : bgColor,
                foregroundColor: isAction && key == "OK" ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: isAction
                  ? Icon(key == "DEL" ? Icons.backspace : Icons.check, size: 24)
                  : Text(key, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
