import 'package:flutter/material.dart';

// --- DATEN-MODELLE ---
class DartPlayer {
  String name;
  int currentScore;
  int legsWon;
  List<int> history;

  // startScore wird direkt an currentScore übergeben
  DartPlayer({required this.name, required int startScore})
      : currentScore = startScore,
        legsWon = 0,
        history = [];
}

class DartsGame extends StatefulWidget {
  // Hier nehmen wir die Farbe aus der Main.dart entgegen
  final Color? themeColor;

  const DartsGame({super.key, this.themeColor});

  @override
  State<DartsGame> createState() => _DartsGameState();
}

class _DartsGameState extends State<DartsGame> {
  // --- STYLE ---
  // Getter: Nutze die übergebene Farbe, oder Fallback auf Dart-Grün
  Color get primaryColor => widget.themeColor ?? const Color(0xFF00B894);

  final Color bgColor = const Color(0xFF222629);
  final Color surfaceColor = const Color(0xFF30363B);
  final Color errorColor = const Color(0xFFEB6B6B);

  // --- STATE ---
  bool _gameStarted = false;
  List<DartPlayer> _players = [];
  int _startScore = 501; // Default
  int _currentPlayerIndex = 0;

  // Input Controller für das Custom Keypad
  String _currentInput = "";

  final TextEditingController _nameController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // --- LOGIK: SETUP ---

  void _addPlayer() {
    if (_nameController.text.trim().isNotEmpty) {
      setState(() {
        _players.add(DartPlayer(name: _nameController.text.trim(), startScore: _startScore));
        _nameController.clear();
      });
    }
  }

  void _startGame() {
    FocusScope.of(context).unfocus(); // Tastatur weg
    if (_players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bitte Spieler hinzufügen!")));
      return;
    }
    // Scores initialisieren falls Modus geändert wurde
    for (var p in _players) {
      p.currentScore = _startScore;
      p.history.clear();
    }
    setState(() {
      _gameStarted = true;
      _currentPlayerIndex = 0;
      _currentInput = "";
    });
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
            const Text("Darts X01 Regeln", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ZIEL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("Erreiche exakt 0 Punkte.", style: TextStyle(color: Colors.white70)),
              SizedBox(height: 10),
              Text("ABLAUF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("Jeder wirft 3 Pfeile. Die Summe wird abgezogen.", style: TextStyle(color: Colors.white70)),
              SizedBox(height: 10),
              Text("BUST (ÜBERWORFEN)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("Wirfst du mehr Punkte als du Rest hast, verfällt der Wurf. Du bleibst auf dem Punktestand vor dem Wurf.", style: TextStyle(color: Colors.white70)),
            ],
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

  // --- LOGIK: GAMEPLAY ---

  void _onKeypadTap(String value) {
    if (value == "OK") {
      _submitScore();
    } else if (value == "DEL") {
      if (_currentInput.isNotEmpty) {
        setState(() {
          _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        });
      }
    } else {
      // Zahlen eingeben (max 3 Stellen, da 180 das Maximum ist)
      if (_currentInput.length < 3) {
        setState(() {
          _currentInput += value;
        });
      }
    }
  }

  void _submitScore() {
    if (_currentInput.isEmpty) return;
    int scoreThrown = int.tryParse(_currentInput) ?? 0;

    // Validierung: Man kann nicht mehr als 180 werfen
    if (scoreThrown > 180) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: errorColor, content: const Text("Maximal 180 Punkte möglich!")));
      setState(() => _currentInput = "");
      return;
    }

    setState(() {
      DartPlayer player = _players[_currentPlayerIndex];

      // History speichern für Bust-Logik
      int scoreBefore = player.currentScore;

      int newScore = player.currentScore - scoreThrown;

      if (newScore == 0) {
        // GEWONNEN!
        player.currentScore = 0;
        _showWinnerDialog(player);
      } else if (newScore < 0 || newScore == 1) { // 1 Rest ist bei Double-Out auch Bust, wir machen hier einfache Regel: < 0
        // BUST!
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: errorColor,
          content: Text("Überworfen! Zurück auf $scoreBefore"),
          duration: const Duration(seconds: 1),
        ));
        // Score bleibt unverändert (bzw. wird nicht geupdated, da wir ihn nur lokal berechnet haben)
      } else {
        // Gültiger Wurf
        player.currentScore = newScore;
      }

      // Input leeren & Nächster Spieler
      _currentInput = "";
      if (newScore != 0) { // Nur wechseln wenn keiner gewonnen hat
        _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
      }
    });
  }

  void _showWinnerDialog(DartPlayer winner) {
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
            Text("${winner.name} GEWINNT!", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text("Neues Leg starten?", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        actions: [
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
            },
            child: Text("NEUE RUNDE", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _gameStarted = false; // Zurück zum Setup
                _players.clear();
              });
            },
            child: const Text("BEENDEN", style: TextStyle(color: Colors.grey)),
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
        title: const Text("Darts X01"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: primaryColor,
        actions: [
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
          const Text("SPIEL-MODUS", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                  onSelected: (val) => setState(() => _startScore = score),
                ),
              );
            }).toList(),
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
                      onPressed: () => setState(() => _players.removeAt(index)),
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
              child: const Text("GAME ON!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
                          Text("Legs: ${p.legsWon}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
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

        // --- INPUT DISPLAY ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          color: Colors.black26,
          child: Center(
            child: Text(
              _currentInput.isEmpty ? "Wurf eingeben..." : _currentInput,
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