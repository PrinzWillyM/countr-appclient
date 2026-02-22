import 'package:flutter/material.dart';

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
  const FuckTheNeighborGame({super.key});

  @override
  State<FuckTheNeighborGame> createState() => _FuckTheNeighborGameState();
}

class _FuckTheNeighborGameState extends State<FuckTheNeighborGame> {
  // --- FARBEN & STYLE ---
  final Color primaryColor = const Color(0xFFEBCB63); // Gelb
  final Color bgColor = const Color(0xFF222629);
  final Color surfaceColor = const Color(0xFF30363B);
  final Color cardColor = const Color(0xFF3A4146);
  final Color errorColor = const Color(0xFFEB6B6B);
  final Color successColor = const Color(0xFF4CBF98);

  // --- STATE ---
  bool _gameStarted = false;
  bool _gameFinished = false;
  List<Player> _players = [];
  List<RoundData> _rounds = [];

  final TextEditingController _nameController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Für vertikales Scrollen

  // --- LOGIK: SETUP ---

  void _addPlayer() {
    if (_nameController.text.trim().isNotEmpty) {
      if (_players.length >= 9) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Maximal 9 Spieler!")));
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
            const Flexible(child: Text("Spielanleitung", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRuleHeader("ÜBERSICHT"),
                _buildRuleItem(Icons.groups, "Spieler", "3 bis 9 Personen"),
                _buildRuleItem(Icons.style, "Material", "Jasskarten (36 Stück)"),
                _buildRuleItem(Icons.emoji_events, "Ziel", "0 Punkte erreichen. (Differenz = Strafpunkte)"),

                const SizedBox(height: 15),
                _buildRuleHeader("ABLAUF"),
                _buildRuleStep("1", "Karten verteilen (R1 = Max, dann -1)."),
                _buildRuleStep("2", "Ansagen machen."),
                _buildRuleStep("3", "Spielen (Höchste Karte sticht)."),
                _buildRuleStep("4", "Abrechnung (|Ansage - Stich|)."),

                const SizedBox(height: 15),
                _buildRuleHeader("REGELN"),
                _buildRuleSpecial("Geber-Regel", "Summe Ansagen ≠ Anzahl Karten!"),
                _buildRuleSpecial("Blockieren", "Gleiche höchste Karten blockieren sich."),
                _buildRuleSpecial("Finale", "Letzte Karte an die Stirn (Blind)!"),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("VERSTANDEN", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mindestens 3 Spieler!")));
      return;
    }
    _setupRounds();
  }

  void _rematch() {
    setState(() {
      // 1. Scores zurücksetzen
      for (var p in _players) {
        p.totalScore = 0;
      }

      // 2. Spieler rotieren (Erster wird Letzter)
      if (_players.length > 1) {
        Player first = _players.removeAt(0);
        _players.add(first);
      }

      // 3. Spiel neu starten
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
        dealerIndex: i % _players.length,
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
          title: Text(_gameStarted ? "Score Board" : "Fuck the Neighbor"),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: primaryColor,
          actions: [
            IconButton(icon: const Icon(Icons.help_outline), onPressed: _showRules, tooltip: "Anleitung"),
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
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _showRules,
            icon: const Icon(Icons.menu_book),
            label: const Text("SPIELANLEITUNG"),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Spieler Name",
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                  ),
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
              child: const Text("SPIEL STARTEN", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // SCREEN 2: SCORE TABLE (Responsive Cards mit Hybrid Layout)
  Widget _buildScoreTable() {
    // --- KONFIGURATION ---
    const double headerWidth = 60.0; // Linke Spalte
    const double minCardWidth = 75.0; // Mindestbreite Karte
    const double rowHeight = 70.0;    // Höhe einer Zeile (Card + Margin)
    const double headerHeight = 80.0; // Höhe Kopfzeile

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        // Padding abziehen (10 links + 10 rechts = 20)
        final double widthForContent = availableWidth - headerWidth - 20;

        // 1. Berechnen: Brauchen wir Scrollen?
        double totalNeeded = _players.length * minCardWidth;
        bool needsScroll = totalNeeded > widthForContent;

        // 2. Spaltenbreite festlegen
        double cardWidth;
        if (needsScroll) {
          cardWidth = minCardWidth; // Scroll-Modus
        } else {
          cardWidth = widthForContent / _players.length; // Stretch-Modus
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Column(
            children: [
              Expanded(
                // Vertikales Scrollen (Ganze Tabelle)
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  controller: _scrollController,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // A) LINKE SPALTE (FIXIERT)
                      Column(
                        children: [
                          Container(
                            width: headerWidth,
                            height: headerHeight,
                            alignment: Alignment.center,
                            child: Icon(Icons.grid_view, color: Colors.white12, size: 24),
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
                                    Text("R${round.roundNumber}",
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

                      // B) RECHTER BEREICH (Horizontal Scrollbar bei Bedarf)
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

                              // 2. DATA ROWS (Die eigentlichen Spiel-Karten)
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

                                        content = "$bid / $trick";
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
    sorted.sort((a, b) => a.totalScore.compareTo(b.totalScore));

    int bestScore = sorted.first.totalScore;
    List<Player> winners = sorted.where((p) => p.totalScore == bestScore).toList();
    String winnerNames = winners.map((p) => p.name).join(" & ");
    String winnerText = winners.length > 1 ? "GEWINNER" : "GEWINNER";

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, size: 80, color: primaryColor),
              const SizedBox(height: 20),
              Text(winnerText, style: TextStyle(color: Colors.white.withOpacity(0.6), letterSpacing: 2)),
              const SizedBox(height: 5),
              Text(
                  winnerNames,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 5),
              Text("$bestScore Strafpunkte", style: TextStyle(color: primaryColor, fontSize: 20)),
              const SizedBox(height: 30),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final player = sorted[index];

                  // Visuelle Rangberechnung
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
                  child: const Text("REVANCHE (Rotation)", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                  onPressed: () => setState(() {
                    _gameFinished = false;
                    _gameStarted = false;
                    _players.clear();
                  }),
                  child: const Text("Neues Spiel (Setup)", style: TextStyle(color: Colors.grey))
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

  const _RoundInputSheet({
    required this.round,
    required this.players,
    required this.primaryColor,
    required this.errorColor,
    required this.successColor,
    required this.cardColor,
    required this.onRoundCompleted,
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
        content: const Text("GEBER-REGEL: Summe darf nicht aufgehen!"),
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
                      isPhase2 ? "STICHE VERTEILEN" : "ANSAGEN MACHEN",
                      style: TextStyle(color: widget.primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text("Runde ${widget.round.roundNumber} (${widget.round.cardCount} Karten)", style: const TextStyle(color: Colors.grey)),
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
                            Text(player.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            if (forbidden != null)
                              Text("Nicht $forbidden!", style: TextStyle(color: widget.errorColor, fontSize: 12)),
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
                  const Text("Noch zu verteilen: ", style: TextStyle(color: Colors.grey, fontSize: 16)),
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
                    ? (_remainingTricks == 0 ? "RUNDE ABSCHLIESSEN" : "STICHE AUFGEHEN LASSEN")
                    : "WEITER ZU DEN STICHEN",
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