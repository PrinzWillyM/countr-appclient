import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- DATENSTRUKTUREN ---

class Player {
  String name;
  int totalScore;

  Player({required this.name, this.totalScore = 0});
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
}

// --- WIDGET ---

class FuckTheNeighborGame extends StatefulWidget {
  final Color? themeColor;

  const FuckTheNeighborGame({super.key, this.themeColor});

  @override
  State<FuckTheNeighborGame> createState() => _FuckTheNeighborGameState();
}

class _FuckTheNeighborGameState extends State<FuckTheNeighborGame> {
  // --- FARBEN & STYLE ---
  Color get primaryColor => widget.themeColor ?? const Color(0xFFEBCB63); // Brand Yellow
  final Color bgColor = const Color(0xFF222629);
  final Color surfaceColor = const Color(0xFF30363B);
  final Color cardColor = const Color(0xFF3A4146);
  final Color errorColor = const Color(0xFFEB6B6B);
  final Color successColor = const Color(0xFF4CBF98);

  // --- STATE ---
  String _currentLang = 'en';
  bool _gameStarted = false;
  bool _gameFinished = false;
  List<Player> _players = [];
  List<RoundData> _rounds = [];

  final TextEditingController _nameController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Für vertikales Scrollen

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentLang = prefs.getString('language_code') ?? 'de';
      });
    }
  }

  // --- ÜBERSETZUNG ---
  String _t(String key) {
    const Map<String, Map<String, String>> dictionary = {
      'de': {
        'title': 'Fuck the Neighbor', 'add_hint': 'Spieler Name', 'add_err': 'Maximal 9 Spieler!', 'add_err_min': 'Mindestens 3 Spieler!',
        'start': 'SPIEL STARTEN', 'rules': 'Spielanleitung', 'ok': 'VERSTANDEN',
        'round': 'R', 'score_board': 'Score Board', 'winner': 'GEWINNER', 'penalty': 'Strafpunkte',
        'rematch': 'REVANCHE (Rotation)', 'new_game': 'Neues Spiel (Setup)',
        'phase1': 'ANSAGEN MACHEN', 'phase2': 'STICHE VERTEILEN',
        'starts': 'Fängt an', 'bid_info': 'Ansage', 'forbidden': 'Nicht',
        'tricks_left': 'Noch zu verteilen: ', 'btn_p1': 'WEITER ZU DEN STICHEN', 'btn_p2': 'RUNDE ABSCHLIESSEN', 'btn_err': 'STICHE AUFGEHEN LASSEN',
        'err_dealer': 'GEBER-REGEL: Summe darf nicht aufgehen!',
        'r_overview': 'ÜBERSICHT', 'r_players': '3 bis 9 Personen', 'r_material': 'Jasskarten (36 Stück)', 'r_goal': '0 Punkte erreichen. (Differenz = Strafpunkte)',
        'r_flow': 'ABLAUF', 'r_s1': 'Karten verteilen (R1 = Max, dann -1).', 'r_s2': 'Ansagen machen.', 'r_s3': 'Spielen (Höchste Karte sticht).', 'r_s4': 'Abrechnung (|Ansage - Stich|).',
        'r_rules': 'REGELN', 'r_dealer': 'Geber-Regel', 'r_dealer_txt': 'Summe Ansagen ≠ Anzahl Karten!', 'r_block': 'Blockieren', 'r_block_txt': 'Gleiche höchste Karten blockieren sich.', 'r_final': 'Finale', 'r_final_txt': 'Letzte Karte an die Stirn (Blind)!'
      },
      'en': {
        'title': 'Fuck the Neighbor', 'add_hint': 'Player Name', 'add_err': 'Max 9 players!', 'add_err_min': 'Min 3 players!',
        'start': 'START GAME', 'rules': 'How to Play', 'ok': 'GOT IT',
        'round': 'R', 'score_board': 'Score Board', 'winner': 'WINNER', 'penalty': 'Penalty Points',
        'rematch': 'REMATCH (Rotate)', 'new_game': 'New Game (Setup)',
        'phase1': 'MAKE BIDS', 'phase2': 'ENTER TRICKS',
        'starts': 'Starts', 'bid_info': 'Bid', 'forbidden': 'Not',
        'tricks_left': 'Remaining tricks: ', 'btn_p1': 'CONTINUE TO TRICKS', 'btn_p2': 'FINISH ROUND', 'btn_err': 'TRICKS MUST MATCH',
        'err_dealer': 'DEALER RULE: Sum of bids cannot equal cards!',
        'r_overview': 'OVERVIEW', 'r_players': '3 to 9 players', 'r_material': '36 Cards', 'r_goal': 'Reach 0 points. (Difference = Penalty)',
        'r_flow': 'FLOW', 'r_s1': 'Deal cards (R1 = Max, then -1).', 'r_s2': 'Make bids.', 'r_s3': 'Play (Highest card wins trick).', 'r_s4': 'Score (|Bid - Tricks|).',
        'r_rules': 'RULES', 'r_dealer': 'Dealer Rule', 'r_dealer_txt': 'Sum of bids ≠ Card count!', 'r_block': 'Blocking', 'r_block_txt': 'Equal highest cards block each other.', 'r_final': 'Finale', 'r_final_txt': 'Last card on forehead (Blind)!'
      },
      // Kurzversionen für den Rest (Fallback auf Englisch bei fehlenden Keys im Code unten)
      'fr': { 'title': 'Fuck the Neighbor', 'add_hint': 'Nom', 'start': 'DÉMARRER', 'rules': 'Règles', 'ok': 'COMPRIS', 'winner': 'VAINQUEUR', 'rematch': 'REVANCHE', 'phase1': 'ANNONCES', 'phase2': 'PLIS', 'starts': 'Commence', 'bid_info': 'Annonce', 'btn_p1': 'SUIVANT', 'btn_p2': 'TERMINER' },
      'it': { 'title': 'Fuck the Neighbor', 'add_hint': 'Nome', 'start': 'AVVIA', 'rules': 'Regole', 'ok': 'CAPITO', 'winner': 'VINCITORE', 'rematch': 'RIVINCITA', 'phase1': 'DICHIARAZIONI', 'phase2': 'PRESE', 'starts': 'Inizia', 'bid_info': 'Dichiar.', 'btn_p1': 'AVANTI', 'btn_p2': 'FINE' },
      'es': { 'title': 'Fuck the Neighbor', 'add_hint': 'Nombre', 'start': 'INICIAR', 'rules': 'Reglas', 'ok': 'ENTENDIDO', 'winner': 'GANADOR', 'rematch': 'REVANCHA', 'phase1': 'APUESTAS', 'phase2': 'BAZAS', 'starts': 'Empieza', 'bid_info': 'Apuesta', 'btn_p1': 'SIGUIENTE', 'btn_p2': 'TERMINAR' },
      'pt': { 'title': 'Fuck the Neighbor', 'add_hint': 'Nome', 'start': 'INICIAR', 'rules': 'Regras', 'ok': 'ENTENDIDO', 'winner': 'VENCEDOR', 'rematch': 'REVANCHE', 'phase1': 'APOSTAS', 'phase2': 'VAZAS', 'starts': 'Começa', 'bid_info': 'Aposta', 'btn_p1': 'PRÓXIMO', 'btn_p2': 'TERMINAR' },
      'nl': { 'title': 'Fuck the Neighbor', 'add_hint': 'Naam', 'start': 'STARTEN', 'rules': 'Regels', 'ok': 'BEGREPEN', 'winner': 'WINNAAR', 'rematch': 'REVANCHE', 'phase1': 'BIEDEN', 'phase2': 'SLAGEN', 'starts': 'Begint', 'bid_info': 'Bod', 'btn_p1': 'VERDER', 'btn_p2': 'AFRONDEN' },
      'pl': { 'title': 'Fuck the Neighbor', 'add_hint': 'Imię', 'start': 'START', 'rules': 'Zasady', 'ok': 'ZROZUMIAŁEM', 'winner': 'ZWYCIĘZCA', 'rematch': 'REWANŻ', 'phase1': 'LICYTACJA', 'phase2': 'LEWY', 'starts': 'Zaczyna', 'bid_info': 'Dekl.', 'btn_p1': 'DALEJ', 'btn_p2': 'ZAKOŃCZ' },
      'tr': { 'title': 'Fuck the Neighbor', 'add_hint': 'İsim', 'start': 'BAŞLAT', 'rules': 'Kurallar', 'ok': 'ANLADIM', 'winner': 'KAZANAN', 'rematch': 'RÖVANŞ', 'phase1': 'TAHMİNLER', 'phase2': 'ELLER', 'starts': 'Başlar', 'bid_info': 'Tahmin', 'btn_p1': 'İLERİ', 'btn_p2': 'BİTİR' },
      'id': { 'title': 'Fuck the Neighbor', 'add_hint': 'Nama', 'start': 'MULAI', 'rules': 'Aturan', 'ok': 'MENGERTI', 'winner': 'PEMENANG', 'rematch': 'TANDING ULANG', 'phase1': 'TEBAKAN', 'phase2': 'TRIK', 'starts': 'Mulai', 'bid_info': 'Tebakan', 'btn_p1': 'LANJUT', 'btn_p2': 'SELESAI' },
      'sv': { 'title': 'Fuck the Neighbor', 'add_hint': 'Namn', 'start': 'STARTA', 'rules': 'Regler', 'ok': 'FÖRSTÅTT', 'winner': 'VINNARE', 'rematch': 'REVANSCH', 'phase1': 'BUD', 'phase2': 'STICK', 'starts': 'Börjar', 'bid_info': 'Bud', 'btn_p1': 'NÄSTA', 'btn_p2': 'AVSLUTA' },
      'hr': { 'title': 'Fuck the Neighbor', 'add_hint': 'Ime', 'start': 'POKRENI', 'rules': 'Pravila', 'ok': 'RAZUMIJEM', 'winner': 'POBJEDNIK', 'rematch': 'UZVRAT', 'phase1': 'NAJAVE', 'phase2': 'ŠTIHOVI', 'starts': 'Počinje', 'bid_info': 'Najava', 'btn_p1': 'DALJE', 'btn_p2': 'ZAVRŠI' },
      'ru': { 'title': 'Fuck the Neighbor', 'add_hint': 'Имя', 'start': 'НАЧАТЬ', 'rules': 'Правила', 'ok': 'ПОНЯТНО', 'winner': 'ПОБЕДИТЕЛЬ', 'rematch': 'РЕВАНШ', 'phase1': 'СТАВКИ', 'phase2': 'ВЗЯТКИ', 'starts': 'Начинает', 'bid_info': 'Ставка', 'btn_p1': 'ДАЛЕЕ', 'btn_p2': 'ЗАВЕРШИТЬ' },
      'ja': { 'title': 'Fuck the Neighbor', 'add_hint': '名前', 'start': '開始', 'rules': 'ルール', 'ok': '了解', 'winner': '勝者', 'rematch': '再戦', 'phase1': '予想', 'phase2': 'トリック', 'starts': '最初', 'bid_info': '予想', 'btn_p1': '次へ', 'btn_p2': '完了' },
      'ko': { 'title': 'Fuck the Neighbor', 'add_hint': '이름', 'start': '시작', 'rules': '규칙', 'ok': '확인', 'winner': '승자', 'rematch': '재대결', 'phase1': '예측', 'phase2': '트릭', 'starts': '시작', 'bid_info': '예측', 'btn_p1': '다음', 'btn_p2': '완료' },
      'zh': { 'title': 'Fuck the Neighbor', 'add_hint': '名字', 'start': '开始', 'rules': '规则', 'ok': '明白了', 'winner': '赢家', 'rematch': '重赛', 'phase1': '预测', 'phase2': '赢墩', 'starts': '开始', 'bid_info': '预测', 'btn_p1': '下一步', 'btn_p2': '完成' },
      'hi': { 'title': 'Fuck the Neighbor', 'add_hint': 'नाम', 'start': 'शुरू', 'rules': 'नियम', 'ok': 'समझ गया', 'winner': 'विजेता', 'rematch': 'रीमैच', 'phase1': 'भविष्यवाणी', 'phase2': 'ट्रिक्स', 'starts': 'शुरू', 'bid_info': 'बोली', 'btn_p1': 'अगला', 'btn_p2': 'समाप्त' },
      'bn': { 'title': 'Fuck the Neighbor', 'add_hint': 'নাম', 'start': 'শুরু', 'rules': 'নিয়ম', 'ok': 'বুঝেছি', 'winner': 'বিজয়ী', 'rematch': 'রিম্যাচ', 'phase1': 'ভবিষ্যদ্বাণী', 'phase2': 'ট্রিকস', 'starts': 'শুরু', 'bid_info': 'ডাক', 'btn_p1': 'পরবর্তী', 'btn_p2': 'শেষ' },
      'ar': { 'title': 'Fuck the Neighbor', 'add_hint': 'الاسم', 'start': 'بدء', 'rules': 'قواعد', 'ok': 'فهمت', 'winner': 'الفائز', 'rematch': 'إعادة', 'phase1': 'توقع', 'phase2': 'حيل', 'starts': 'يبدأ', 'bid_info': 'توقع', 'btn_p1': 'التالي', 'btn_p2': 'إنهاء' },
    };

    if (dictionary.containsKey(_currentLang) && dictionary[_currentLang]!.containsKey(key)) {
      return dictionary[_currentLang]![key]!;
    }
    return dictionary['en']![key] ?? key;
  }

  // --- LOGIK: SETUP ---

  void _addPlayer() {
    if (_nameController.text.trim().isNotEmpty) {
      if (_players.length >= 9) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('add_err'))));
        return;
      }
      setState(() {
        _players.add(Player(name: _nameController.text.trim()));
        _nameController.clear();
      });
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
                _buildRuleItem(Icons.groups, "Spieler", _t('r_players')),
                _buildRuleItem(Icons.style, "Material", _t('r_material')),
                _buildRuleItem(Icons.emoji_events, "Ziel", _t('r_goal')),

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
  }

  void _setupRounds() {
    int maxCards = 36 ~/ _players.length;
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
      ),
    );
  }

  void _finishRound(int roundIndex) {
    setState(() {
      RoundData round = _rounds[roundIndex];
      for (var player in _players) {
        int bid = round.bids[player.name]!;
        int trick = round.tricks[player.name]!;
        int points = (bid - trick).abs();
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
                  trailing: IconButton(icon: Icon(Icons.delete, color: errorColor), onPressed: () => setState(() => _players.removeAt(index))),
                ),
              ),
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

  // SCREEN 2: SCORE TABLE (Responsive Cards mit Hybrid Layout)
  Widget _buildScoreTable() {
    const double headerWidth = 60.0;
    const double minCardWidth = 75.0;
    const double rowHeight = 70.0;
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
                                child: Column(
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
                                    if(round.isCompleted)
                                      Icon(Icons.check, size: 12, color: successColor)
                                  ],
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
                  onPressed: () => setState(() {
                    _gameFinished = false;
                    _gameStarted = false;
                    _players.clear();
                  }),
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

  const _RoundInputSheet({
    required this.round,
    required this.players,
    required this.primaryColor,
    required this.errorColor,
    required this.successColor,
    required this.cardColor,
    required this.onRoundCompleted,
    required this.langDict,
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

          const SizedBox(height: 20),

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
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(color: widget.primaryColor.withOpacity(0.2), shape: BoxShape.circle),
                                    child: Text(
                                        "${widget.round.bids[player.name]}",
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