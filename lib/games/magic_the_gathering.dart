import 'package:flutter/material.dart';

class MagicTheGatheringGame extends StatefulWidget {
  const MagicTheGatheringGame({super.key});

  @override
  State<MagicTheGatheringGame> createState() => _MagicTheGatheringGameState();
}

class _MagicTheGatheringGameState extends State<MagicTheGatheringGame> {
  // MTG Defaults
  int playerCount = 2;
  int startLife = 20; // Standard MTG
  List<int> playerLives = [];

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      playerLives = List.filled(playerCount, startLife);
    });
  }

  void _updateLife(int index, int amount) {
    setState(() {
      playerLives[index] += amount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF222629),
      appBar: AppBar(
        title: const Text("Magic: The Gathering"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF9B59B6), // Lila
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetGame),
        ],
      ),
      body: Column(
        children: [
          // MTG Mode Switcher
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _modeButton("Standard (20)", 20),
                const SizedBox(width: 10),
                _modeButton("Commander (40)", 40),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: playerCount > 2 ? 2 : 1, // Bei MTG meist 1vs1
                childAspectRatio: playerCount > 2 ? 1.0 : 1.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: playerCount,
              itemBuilder: (context, index) {
                // Bei Magic ist Spieler 2 oft "oben" und rotiert, hier erstmal einfach
                return _MtgCard(
                  name: "Planeswalker ${index + 1}",
                  life: playerLives[index],
                  onChanged: (val) => _updateLife(index, val),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton(String text, int life) {
    bool isSelected = startLife == life;
    return ElevatedButton(
      onPressed: () => setState(() { startLife = life; _resetGame(); }),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF9B59B6) : const Color(0xFF30363B),
        foregroundColor: isSelected ? Colors.white : Colors.grey,
      ),
      child: Text(text),
    );
  }
}

class _MtgCard extends StatelessWidget {
  final String name;
  final int life;
  final Function(int) onChanged;

  const _MtgCard({required this.name, required this.life, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2533), // Dunkles Lila
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF9B59B6), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(name, style: const TextStyle(color: Color(0xFF9B59B6), fontWeight: FontWeight.bold)),
          Text("$life", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 60)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _btn("-5", () => onChanged(-5)), // Großer Schaden
              const SizedBox(width: 10),
              _btn("-1", () => onChanged(-1)),
              const SizedBox(width: 20),
              _btn("+1", () => onChanged(1)),
              const SizedBox(width: 10),
              _btn("+5", () => onChanged(5)), // Lebensgain
            ],
          )
        ],
      ),
    );
  }

  Widget _btn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}