import 'package:flutter/material.dart';

// --- DATENSTRUKTUREN ---

class YazzeePlayer {
  String name;
  Map<String, int?> scores; // null = noch nicht gespielt

  YazzeePlayer({required this.name}) : scores = {};

  // --- BERECHNUNGEN ---

  // Summe oben (1er bis 6er)
  int get upperSum {
    int sum = 0;
    for (var key in ['1er', '2er', '3er', '4er', '5er', '6er']) {
      sum += (scores[key] ?? 0);
    }
    return sum;
  }

  // Bonus (35 Pkt wenn oben >= 63)
  int get bonus => upperSum >= 63 ? 35 : 0;

  // Summe unten
  int get lowerSum {
    int sum = 0;
    for (var key in ['3er Pasch', '4er Pasch', 'Full House', 'Kl. Straße', 'Gr. Straße', 'Yahtzee', 'Chance']) {
      sum += (scores[key] ?? 0);
    }
    return sum;
  }

  // Gesamtsumme
  int get grandTotal => upperSum + bonus + lowerSum;
}

// Kategorien Definitionen
final List<String> categories = [
  // Oben
  '1er', '2er', '3er', '4er', '5er', '6er',
  'SUMME OBEN', // Berechnet
  'BONUS',      // Berechnet
  // Unten
  '3er Pasch', '4er Pasch', 'Full House', 'Kl. Straße', 'Gr. Straße', 'Yahtzee', 'Chance',
  'GESAMT'      // Berechnet
];

class YazzeeGame extends StatefulWidget {
  const YazzeeGame({super.key});

  @override
  State<YazzeeGame> createState() => _YazzeeGameState();
}

class _YazzeeGameState extends State<YazzeeGame> {
  // --- FARBEN & STYLE ---
  final Color primaryColor = const Color(0xFF4CBF98); // Diesmal Grün als Hauptfarbe
  final Color secondaryColor = const Color(0xFFEBCB63); // Gelb für Akzente
  final Color bgColor = const Color(0xFF222629);
  final Color surfaceColor = const Color(0xFF30363B);
  final Color cardColor = const Color(0xFF3A4146);
  final Color errorColor = const Color(0xFFEB6B6B);
  final Color successColor = const Color(0xFF4CBF98);

  // --- STATE ---
  bool _gameStarted = false;
  List<YazzeePlayer> _players = [];
  final TextEditingController _nameController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // --- SETUP ---

  void _addPlayer() {
    if (_nameController.text.trim().isNotEmpty) {
      if (_players.length >= 6) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Maximal 6 Spieler!")));
        return;
      }
      setState(() {
        _players.add(YazzeePlayer(name: _nameController.text.trim()));
        _nameController.clear();
      });
    }
  }

  void _startGame() {
    FocusScope.of(context).unfocus();
    if (_players.length < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mindestens 1 Spieler!")));
      return;
    }
    setState(() {
      _gameStarted = true;
    });
  }

  void _resetGame() {
    setState(() {
      _gameStarted = false;
      _players.clear();
    });
  }

  // --- LOGIK: SCORE EINTAGEN ---

  void _openScoreInput(YazzeePlayer player, String category) {
    // Berechnete Felder sind nicht editierbar
    if (['SUMME OBEN', 'BONUS', 'GESAMT'].contains(category)) return;

    TextEditingController scoreCtrl = TextEditingController();

    // Standard-Vorschläge für feste Werte
    int? suggestion;
    if (category == 'Full House') suggestion = 25;
    if (category == 'Kl. Straße') suggestion = 30;
    if (category == 'Gr. Straße') suggestion = 40;
    if (category == 'Yahtzee') suggestion = 50;

    if (suggestion != null) {
      scoreCtrl.text = suggestion.toString();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: primaryColor)),
        title: Text("$category für ${player.name}", style: TextStyle(color: primaryColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: scoreCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "0",
                hintStyle: TextStyle(color: Colors.white24),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _quickBtn("Streichen (0)", "0", scoreCtrl, color: errorColor),
                if (suggestion != null)
                  _quickBtn("Standard ($suggestion)", "$suggestion", scoreCtrl, color: secondaryColor),
              ],
            )
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ABBRECHEN", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black),
            onPressed: () {
              setState(() {
                int? val = int.tryParse(scoreCtrl.text);
                if (val != null) {
                  player.scores[category] = val;
                }
              });
              Navigator.pop(context);
            },
            child: const Text("SPEICHERN"),
          )
        ],
      ),
    );
  }

  Widget _quickBtn(String label, String val, TextEditingController ctrl, {Color? color}) {
    return TextButton(
      onPressed: () => ctrl.text = val,
      child: Text(label, style: TextStyle(color: color ?? Colors.white70)),
    );
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text("Yazzee Score"),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: primaryColor,
          actions: [
            if (_gameStarted)
              IconButton(icon: const Icon(Icons.refresh), onPressed: _resetGame, tooltip: "Neues Spiel"),
          ],
        ),
        body: SafeArea(
          child: _gameStarted ? _buildScoreTable() : _buildSetup(),
        ),
      ),
    );
  }

  // 1. SETUP SCREEN (Wiederverwendet)
  Widget _buildSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Icon(Icons.casino, size: 80, color: primaryColor), // Würfel Icon
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

  // 2. SCORE TABLE (Identisches Layout wie FtN, aber für Kategorien)
  Widget _buildScoreTable() {
    const double headerWidth = 100.0; // Breiter für Kategorienamen
    const double minCardWidth = 70.0;
    const double rowHeight = 60.0;
    const double headerHeight = 70.0;

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
                      // A) LINKE SPALTE (KATEGORIEN)
                      Column(
                        children: [
                          Container(width: headerWidth, height: headerHeight, color: bgColor), // Leeres Eck
                          ...categories.map((cat) {
                            bool isCalculated = ['SUMME OBEN', 'BONUS', 'GESAMT'].contains(cat);
                            return Container(
                              width: headerWidth,
                              height: rowHeight,
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                padding: const EdgeInsets.only(left: 8),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: isCalculated ? Colors.black26 : surfaceColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: isCalculated ? Border.all(color: Colors.white10) : null,
                                ),
                                child: Text(cat,
                                    style: TextStyle(
                                        color: isCalculated ? secondaryColor : Colors.white,
                                        fontWeight: isCalculated ? FontWeight.w900 : FontWeight.bold,
                                        fontSize: isCalculated ? 11 : 12
                                    )
                                ),
                              ),
                            );
                          }),
                        ],
                      ),

                      // B) RECHTER BEREICH (SPIELER & PUNKTE)
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
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          p.name,
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        Text(
                                            "${p.grandTotal}",
                                            style: TextStyle(color: secondaryColor, fontSize: 16, fontWeight: FontWeight.bold)
                                        )
                                      ],
                                    ),
                                  ),
                                )).toList(),
                              ),

                              // 2. DATA ROWS
                              ...categories.map((cat) {
                                bool isCalculated = ['SUMME OBEN', 'BONUS', 'GESAMT'].contains(cat);

                                return Row(
                                  children: _players.map((p) {
                                    String display = "";
                                    Color textColor = Colors.white;
                                    Color cellBg = cardColor;
                                    bool hasValue = false;

                                    if (cat == 'SUMME OBEN') {
                                      display = "${p.upperSum}";
                                      textColor = Colors.grey;
                                      cellBg = Colors.transparent;
                                    } else if (cat == 'BONUS') {
                                      display = "${p.bonus}";
                                      textColor = p.bonus > 0 ? successColor : Colors.grey;
                                      cellBg = Colors.transparent;
                                    } else if (cat == 'GESAMT') {
                                      display = "${p.grandTotal}";
                                      textColor = secondaryColor;
                                      cellBg = Colors.black45;
                                    } else {
                                      // Normale Eingabefelder
                                      int? score = p.scores[cat];
                                      if (score != null) {
                                        display = "$score";
                                        hasValue = true;
                                        if (score == 0) {
                                          textColor = errorColor; // Gestrichen
                                          cellBg = errorColor.withOpacity(0.1);
                                        } else {
                                          textColor = primaryColor;
                                          cellBg = primaryColor.withOpacity(0.1);
                                        }
                                      } else {
                                        display = "-";
                                        textColor = Colors.white12;
                                      }
                                    }

                                    return InkWell(
                                      onTap: () => _openScoreInput(p, cat),
                                      child: Container(
                                        width: cardWidth,
                                        height: rowHeight,
                                        padding: const EdgeInsets.all(4),
                                        child: Container(
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: cellBg,
                                            borderRadius: BorderRadius.circular(8),
                                            border: isCalculated ? Border.all(color: Colors.white10) : (hasValue ? Border.all(color: textColor.withOpacity(0.3)) : null),
                                          ),
                                          child: Text(
                                              display,
                                              style: TextStyle(
                                                  color: textColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: isCalculated ? 16 : 18
                                              )
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
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
}