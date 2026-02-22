import 'package:flutter/material.dart';

class TenThousandGame extends StatelessWidget {
  const TenThousandGame({super.key});

  @override
  Widget build(BuildContext context) {
    // Farbe für 10.000 (Ein schönes Orange)
    final Color gameColor = const Color(0xFFFF9F43);

    return Scaffold(
      backgroundColor: const Color(0xFF222629),
      appBar: AppBar(
        title: const Text("10'000 (Farkle)"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: gameColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.grain, size: 100, color: gameColor), // Icon sieht aus wie Würfelaugen
              const SizedBox(height: 20),
              const Text(
                "10'000",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                "FARKLE / MACKE",
                style: TextStyle(color: gameColor, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 4),
              ),
              const SizedBox(height: 10),
              Text(
                "Coming Soon...",
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Feature Preview
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF30363B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gameColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    _buildFeatureRow(Icons.calculate, "Automatischer Rechner"),
                    const Divider(color: Colors.white10),
                    _buildFeatureRow(Icons.local_fire_department, "Farkle Erkennung"),
                    const Divider(color: Colors.white10),
                    _buildFeatureRow(Icons.emoji_events, "Ziel: 10'000 Punkte"),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              const Text(
                "Benötigt: 6 normale Würfel",
                style: TextStyle(color: Colors.grey),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 15),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}