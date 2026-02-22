import 'package:flutter/material.dart';

class PokemonTCGGame extends StatefulWidget {
  const PokemonTCGGame({super.key});

  @override
  State<PokemonTCGGame> createState() => _PokemonTCGGameState();
}

class _PokemonTCGGameState extends State<PokemonTCGGame> {
  // Bei Pokemon zählen wir Preiskarten (meist 6).
  // Ziel: 0 Preiskarten übrig.
  int startPrizes = 6;
  List<int> playerPrizes = [6, 6]; // Standard 1vs1

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF222629),
      appBar: AppBar(
        title: const Text("Pokémon TCG"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFFEBCB63), // Pokemon Gelb
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => playerPrizes = [startPrizes, startPrizes]),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(10.0),
            child: Text("Verbleibende Preiskarten", style: TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gegner (Oben, evtl. gedreht für Face-to-Face)
                RotatedBox(
                  quarterTurns: 2,
                  child: _PokemonCard(
                    name: "Gegner",
                    count: playerPrizes[1],
                    color: const Color(0xFFEB6B6B), // Rot
                    onChanged: (val) => setState(() {
                      playerPrizes[1] = (playerPrizes[1] + val).clamp(0, 6);
                    }),
                  ),
                ),

                // Trennlinie
                const Divider(color: Colors.white24),

                // Eigener Spieler (Unten)
                _PokemonCard(
                  name: "Du",
                  count: playerPrizes[0],
                  color: const Color(0xFF5E9CE5), // Blau
                  onChanged: (val) => setState(() {
                    playerPrizes[0] = (playerPrizes[0] + val).clamp(0, 6);
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PokemonCard extends StatelessWidget {
  final String name;
  final int count;
  final Color color;
  final Function(int) onChanged;

  const _PokemonCard({required this.name, required this.count, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Wenn 0 erreicht ist, hat man gewonnen!
    bool isWinner = count == 0;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isWinner ? const Color(0xFFEBCB63).withOpacity(0.2) : const Color(0xFF30363B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isWinner ? const Color(0xFFEBCB63) : color, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isWinner ? "GEWONNEN!" : name,
              style: TextStyle(color: isWinner ? const Color(0xFFEBCB63) : Colors.white, fontWeight: FontWeight.bold, fontSize: 24)
          ),
          const SizedBox(height: 10),
          // Pokeball-Style Anzeige für Preiskarten
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              // Zeige gefüllte Bälle für vorhandene Preiskarten
              bool hasCard = index < count;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.catching_pokemon,
                  color: hasCard ? color : Colors.grey.withOpacity(0.3),
                  size: 30,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => onChanged(1), // Karte zurücklegen (Strafe)
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black26),
                child: const Text("+1"),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: count > 0 ? () => onChanged(-1) : null, // Preis nehmen
                style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black),
                child: const Text("PREIS NEHMEN"),
              ),
            ],
          )
        ],
      ),
    );
  }
}