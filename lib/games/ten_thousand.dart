import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';

enum TenKInputMode { dice, manual }

// --- SCORING ENGINE ---
class FarkleResult {
  final int points;
  final int usedCount;
  bool get isFarkle => usedCount == 0;
  FarkleResult(this.points, this.usedCount);
}

class FarkleScorer {
  static FarkleResult score(List<int> dice) {
    List<int> counts = List.filled(7, 0); // Index 1-6
    for (var d in dice) {
      counts[d]++;
    }

    // Sonderfälle bei 6 gewürfelten Steinen
    if (dice.length == 6) {
      if (counts.sublist(1).every((c) => c == 1)) {
        return FarkleResult(1500, 6); // Straße 1-6
      }
      int pairCount = counts.sublist(1).where((c) => c == 2).length;
      if (pairCount == 3) {
        return FarkleResult(1500, 6); // Drei Paare
      }
    }

    int points = 0;
    int used = 0;

    for (int value = 1; value <= 6; value++) {
      if (counts[value] >= 3) {
        int base = value == 1 ? 1000 : value * 100;
        int extra = counts[value] - 3;
        points += base * (1 << extra); // Verdoppelt je zusätzlichem Stein
        used += counts[value];
        counts[value] = 0;
      }
    }

    // Übrige einzelne 1er und 5er
    points += counts[1] * 100;
    used += counts[1];
    points += counts[5] * 50;
    used += counts[5];

    return FarkleResult(points, used);
  }
}

// --- SPIELER MODELL ---
class TenKPlayer {
  String name;
  int grandTotal = 0;
  bool isOnBoard = false; // Hat schon mind. 1x den Minimum-Score gebankt

  TenKPlayer(this.name);
}

class TenThousandGame extends StatefulWidget {
  final Color? themeColor;
  const TenThousandGame({super.key, this.themeColor});

  @override
  State<TenThousandGame> createState() => _TenThousandGameState();
}

class _TenThousandGameState extends State<TenThousandGame> {
  // --- STYLE ---
  Color get primaryColor => widget.themeColor ?? const Color(0xFFFF9F43);
  final Color bgColor = const Color(0xFF222629);
  final Color surfaceColor = const Color(0xFF30363B);
  final Color errorColor = const Color(0xFFEB6B6B);
  final Color successColor = const Color(0xFF4CBF98);

  static const int minToOpen = 300;

  // --- STATE ---
  // Sprache: immer live vom globalen App-Status gelesen (reaktiv auf Sprachwechsel)
  String get _currentLang => appLocaleNotifier.value.languageCode;
  bool _gameStarted = false;
  bool _gameFinished = false;
  List<TenKPlayer> _players = [];
  int _targetScore = 10000;
  TenKInputMode _inputMode = TenKInputMode.dice;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _manualInputController = TextEditingController();

  // Runden-/Zug-State
  int _currentPlayerIndex = 0;
  int _turnTotal = 0;
  bool _finalRoundTriggered = false;
  int? _finalRoundTriggerIndex;
  int _turnsLeftInFinalRound = 0;

  // Würfel-Modus State
  List<int> _currentRoll = [];
  int _diceToRoll = 6;
  bool _hasRolledThisTurn = false;
  bool _bustedThisRoll = false;
  final Random _rng = Random();

  // --- ÜBERSETZUNG ---
  String _t(String key) {
    const Map<String, Map<String, String>> dictionary = {
      'de': {
        'title': "10'000 (Farkle)", 'add_hint': 'Spieler Name', 'add_err_min': 'Mindestens 2 Spieler!', 'max_players_err': 'Maximal 8 Spieler!',
        'start': 'SPIEL STARTEN', 'rules': 'Anleitung', 'ok': 'VERSTANDEN',
        'target': 'Zielpunktzahl', 'input_mode': 'Eingabe-Modus', 'mode_dice': 'Würfel', 'mode_manual': 'Manuell',
        'roll': 'WÜRFELN', 'roll_again': 'NOCHMAL WÜRFELN', 'bank': 'BANKEN', 'farkle': 'FARKLE!',
        'end_turn': 'ZUG BEENDEN', 'turn_total': 'Zug-Punkte', 'total': 'Gesamt', 'add_score': 'Punkte hinzufügen',
        'add': 'HINZUFÜGEN', 'need_min': 'Benötigt mind. $minToOpen zum Start',
        'hot_dice': 'HOT DICE! Alle Würfel erneut nutzbar', 'farkle_msg': 'Kein Punkt getroffen - Zug-Punkte verloren!',
        'final_round': 'LETZTE RUNDE!', 'winner': 'GEWINNER', 'game_over': 'Spiel beendet', 'new_game_btn': 'Neues Spiel',
        'current_turn': 'Am Zug', 'rules_text': "Baue 6 Würfel-Kombos oder tippe deine Punkte manuell ein.\n\n• 1er = 100, 5er = 50\n• Dreiling = Wert×100 (1er-Dreiling = 1000), jeder weitere gleiche Würfel verdoppelt.\n• Straße (1-6) oder 3 Paare = 1500.\n• Kein Punkt = FARKLE, Zug-Punkte weg.\n• Alle 6 Würfel gepunktet = Hot Dice, nochmal alle 6 würfeln.\n• Erster Bank-Wurf braucht mind. $minToOpen Punkte.\n• Erreicht ein Spieler das Ziel, spielen alle anderen noch einmal - dann gewinnt der höchste Gesamtwert.",
      },
      'en': {
        'title': "10'000 (Farkle)", 'add_hint': 'Player Name', 'add_err_min': 'Min 2 players!', 'max_players_err': 'Max 8 players!',
        'start': 'START GAME', 'rules': 'How to Play', 'ok': 'GOT IT',
        'target': 'Target Score', 'input_mode': 'Input Mode', 'mode_dice': 'Dice', 'mode_manual': 'Manual',
        'roll': 'ROLL', 'roll_again': 'ROLL AGAIN', 'bank': 'BANK', 'farkle': 'FARKLE!',
        'end_turn': 'END TURN', 'turn_total': 'Turn Points', 'total': 'Total', 'add_score': 'Add Score',
        'add': 'ADD', 'need_min': 'Needs $minToOpen+ to open',
        'hot_dice': 'HOT DICE! All 6 dice available again', 'farkle_msg': 'No scoring dice - turn points lost!',
        'final_round': 'FINAL ROUND!', 'winner': 'WINNER', 'game_over': 'Game Over', 'new_game_btn': 'New Game',
        'current_turn': "It's your turn", 'rules_text': "Roll 6 dice for combos, or type your points manually.\n\n• 1s = 100, 5s = 50\n• Three of a kind = value×100 (three 1s = 1000), each extra matching die doubles it.\n• Straight (1-6) or three pairs = 1500.\n• No scoring dice = FARKLE, turn points lost.\n• All 6 dice scored = Hot Dice, roll all 6 again.\n• First bank needs $minToOpen+ points.\n• Once a player hits the target, everyone else gets one more turn - highest total wins.",
      },
      'fr': {
        'title': "10'000 (Farkle)", 'add_hint': 'Nom du joueur', 'add_err_min': 'Min. 2 joueurs !', 'max_players_err': 'Max. 8 joueurs !',
        'start': 'DÉMARRER', 'rules': 'Règles', 'ok': 'COMPRIS',
        'target': 'Score cible', 'input_mode': 'Mode de saisie', 'mode_dice': 'Dés', 'mode_manual': 'Manuel',
        'roll': 'LANCER', 'roll_again': 'RELANCER', 'bank': 'ENCAISSER', 'farkle': 'FARKLE !',
        'end_turn': 'FIN DU TOUR', 'turn_total': 'Points du tour', 'total': 'Total', 'add_score': 'Ajouter des points',
        'add': 'AJOUTER', 'need_min': 'Nécessite $minToOpen+ points pour ouvrir',
        'hot_dice': 'DÉS CHAUDS ! Les 6 dés sont à nouveau disponibles', 'farkle_msg': 'Aucun dé ne marque - points du tour perdus !',
        'final_round': 'DERNIER TOUR !', 'winner': 'VAINQUEUR', 'game_over': 'Partie terminée', 'new_game_btn': 'Nouvelle partie',
        'current_turn': "C'est ton tour", 'rules_text': "Lancez 6 dés pour former des combinaisons, ou entrez vos points manuellement.\n\n• Les 1 valent 100, les 5 valent 50\n• Un brelan = valeur×100 (trois 1 = 1000), chaque dé supplémentaire identique double la valeur.\n• Suite (1-6) ou trois paires = 1500.\n• Aucun dé ne marque = FARKLE, points du tour perdus.\n• Les 6 dés ont marqué = Dés Chauds, relancez les 6 dés.\n• Le premier encaissement nécessite $minToOpen+ points.\n• Dès qu'un joueur atteint l'objectif, tous les autres ont un dernier tour - le total le plus élevé gagne.",
      },
      'it': {
        'title': "10'000 (Farkle)", 'add_hint': 'Nome giocatore', 'add_err_min': 'Min. 2 giocatori!', 'max_players_err': 'Max. 8 giocatori!',
        'start': 'INIZIA PARTITA', 'rules': 'Regole', 'ok': 'CAPITO',
        'target': 'Punteggio Obiettivo', 'input_mode': 'Modalità Input', 'mode_dice': 'Dadi', 'mode_manual': 'Manuale',
        'roll': 'LANCIA', 'roll_again': 'LANCIA ANCORA', 'bank': 'INCASSA', 'farkle': 'FARKLE!',
        'end_turn': 'FINE TURNO', 'turn_total': 'Punti del Turno', 'total': 'Totale', 'add_score': 'Aggiungi Punti',
        'add': 'AGGIUNGI', 'need_min': 'Servono almeno $minToOpen punti per aprire',
        'hot_dice': 'HOT DICE! Tutti e 6 i dadi disponibili di nuovo', 'farkle_msg': 'Nessun dado valido - punti del turno persi!',
        'final_round': 'ULTIMO TURNO!', 'winner': 'VINCITORE', 'game_over': 'Partita Terminata', 'new_game_btn': 'Nuova Partita',
        'current_turn': 'Tocca a te', 'rules_text': "Lancia 6 dadi per creare combinazioni, oppure inserisci i punti manualmente.\n\n• 1 = 100, 5 = 50\n• Tris = valore×100 (tris di 1 = 1000), ogni dado uguale aggiuntivo raddoppia il valore.\n• Scala (1-6) o tre coppie = 1500.\n• Nessun dado valido = FARKLE, punti del turno persi.\n• Tutti e 6 i dadi hanno segnato = Hot Dice, rilancia tutti e 6 i dadi.\n• Il primo incasso richiede almeno $minToOpen punti.\n• Quando un giocatore raggiunge l'obiettivo, tutti gli altri hanno un ultimo turno - vince il totale più alto.",
      },
      'es': {
        'title': "10'000 (Farkle)", 'add_hint': 'Nombre del Jugador', 'add_err_min': '¡Mín. 2 jugadores!', 'max_players_err': '¡Máx. 8 jugadores!',
        'start': 'INICIAR PARTIDA', 'rules': 'Reglas', 'ok': 'ENTENDIDO',
        'target': 'Puntuación Objetivo', 'input_mode': 'Modo de Entrada', 'mode_dice': 'Dados', 'mode_manual': 'Manual',
        'roll': 'TIRAR', 'roll_again': 'TIRAR DE NUEVO', 'bank': 'GUARDAR', 'farkle': '¡FARKLE!',
        'end_turn': 'FIN DEL TURNO', 'turn_total': 'Puntos del Turno', 'total': 'Total', 'add_score': 'Añadir Puntos',
        'add': 'AÑADIR', 'need_min': 'Necesitas $minToOpen+ puntos para abrir',
        'hot_dice': '¡DADOS CALIENTES! Los 6 dados disponibles de nuevo', 'farkle_msg': '¡Ningún dado puntúa - puntos del turno perdidos!',
        'final_round': '¡ÚLTIMA RONDA!', 'winner': 'GANADOR', 'game_over': 'Partida Terminada', 'new_game_btn': 'Nueva Partida',
        'current_turn': 'Es tu turno', 'rules_text': 'Tira 6 dados para formar combinaciones, o introduce tus puntos manualmente.\n\n• 1 = 100, 5 = 50\n• Trío = valor×100 (trío de 1 = 1000), cada dado igual adicional lo duplica.\n• Escalera (1-6) o tres pares = 1500.\n• Ningún dado puntúa = FARKLE, puntos del turno perdidos.\n• Los 6 dados puntuaron = Dados Calientes, vuelve a tirar los 6 dados.\n• El primer guardado necesita $minToOpen+ puntos.\n• En cuanto un jugador alcanza el objetivo, todos los demás tienen un último turno - gana el total más alto.',
      },
      'pt': {
        'title': "10'000 (Farkle)", 'add_hint': 'Nome do Jogador', 'add_err_min': 'Mín. 2 jogadores!', 'max_players_err': 'Máx. 8 jogadores!',
        'start': 'INICIAR JOGO', 'rules': 'Regras', 'ok': 'ENTENDIDO',
        'target': 'Pontuação Alvo', 'input_mode': 'Modo de Entrada', 'mode_dice': 'Dados', 'mode_manual': 'Manual',
        'roll': 'LANÇAR', 'roll_again': 'LANÇAR NOVAMENTE', 'bank': 'GUARDAR', 'farkle': 'FARKLE!',
        'end_turn': 'FIM DO TURNO', 'turn_total': 'Pontos do Turno', 'total': 'Total', 'add_score': 'Adicionar Pontos',
        'add': 'ADICIONAR', 'need_min': 'Precisa de $minToOpen+ pontos para abrir',
        'hot_dice': 'HOT DICE! Todos os 6 dados disponíveis novamente', 'farkle_msg': 'Nenhum dado pontuou - pontos do turno perdidos!',
        'final_round': 'ÚLTIMA RODADA!', 'winner': 'VENCEDOR', 'game_over': 'Jogo Terminado', 'new_game_btn': 'Novo Jogo',
        'current_turn': 'É a sua vez', 'rules_text': 'Lance 6 dados para formar combinações, ou digite seus pontos manualmente.\n\n• 1 = 100, 5 = 50\n• Trinca = valor×100 (trinca de 1 = 1000), cada dado igual adicional dobra o valor.\n• Sequência (1-6) ou três pares = 1500.\n• Nenhum dado pontua = FARKLE, pontos do turno perdidos.\n• Todos os 6 dados pontuaram = Hot Dice, lance os 6 dados novamente.\n• O primeiro depósito precisa de $minToOpen+ pontos.\n• Assim que um jogador atinge a meta, todos os outros têm mais um turno - o maior total vence.',
      },
      'nl': {
        'title': "10'000 (Farkle)", 'add_hint': 'Spelernaam', 'add_err_min': 'Min. 2 spelers!', 'max_players_err': 'Max. 8 spelers!',
        'start': 'SPEL STARTEN', 'rules': 'Instructies', 'ok': 'BEGREPEN',
        'target': 'Doelscore', 'input_mode': 'Invoermodus', 'mode_dice': 'Dobbelstenen', 'mode_manual': 'Handmatig',
        'roll': 'GOOIEN', 'roll_again': 'OPNIEUW GOOIEN', 'bank': 'VERZILVEREN', 'farkle': 'FARKLE!',
        'end_turn': 'BEURT BEËINDIGEN', 'turn_total': 'Beurtpunten', 'total': 'Totaal', 'add_score': 'Punten Toevoegen',
        'add': 'TOEVOEGEN', 'need_min': 'Vereist $minToOpen+ punten om te openen',
        'hot_dice': 'HOT DICE! Alle 6 dobbelstenen weer beschikbaar', 'farkle_msg': 'Geen scorende dobbelsteen - beurtpunten verloren!',
        'final_round': 'LAATSTE RONDE!', 'winner': 'WINNAAR', 'game_over': 'Spel Voorbij', 'new_game_btn': 'Nieuw Spel',
        'current_turn': 'Jij bent aan de beurt', 'rules_text': "Gooi met 6 dobbelstenen voor combinaties, of voer je punten handmatig in.\n\n• 1'en = 100, 5'en = 50\n• Drie gelijk = waarde×100 (drie 1'en = 1000), elke extra gelijke dobbelsteen verdubbelt de waarde.\n• Straat (1-6) of drie paren = 1500.\n• Geen scorende dobbelsteen = FARKLE, beurtpunten verloren.\n• Alle 6 dobbelstenen gescoord = Hot Dice, gooi alle 6 opnieuw.\n• De eerste verzilvering vereist $minToOpen+ punten.\n• Zodra een speler het doel bereikt, krijgt iedereen nog één beurt - het hoogste totaal wint.",
      },
      'pl': {
        'title': "10'000 (Farkle)", 'add_hint': 'Imię gracza', 'add_err_min': 'Min. 2 graczy!', 'max_players_err': 'Maks. 8 graczy!',
        'start': 'ROZPOCZNIJ GRĘ', 'rules': 'Zasady', 'ok': 'ZROZUMIAŁEM',
        'target': 'Wynik docelowy', 'input_mode': 'Tryb wprowadzania', 'mode_dice': 'Kości', 'mode_manual': 'Ręczny',
        'roll': 'RZUĆ', 'roll_again': 'RZUĆ PONOWNIE', 'bank': 'ZACHOWAJ', 'farkle': 'FARKLE!',
        'end_turn': 'ZAKOŃCZ TURĘ', 'turn_total': 'Punkty tury', 'total': 'Razem', 'add_score': 'Dodaj punkty',
        'add': 'DODAJ', 'need_min': 'Wymaga $minToOpen+ punktów do otwarcia',
        'hot_dice': 'GORĄCE KOŚCI! Wszystkie 6 kości znów dostępne', 'farkle_msg': 'Żadna kość nie punktuje - punkty tury stracone!',
        'final_round': 'OSTATNIA TURA!', 'winner': 'ZWYCIĘZCA', 'game_over': 'Koniec gry', 'new_game_btn': 'Nowa gra',
        'current_turn': 'Twoja kolej', 'rules_text': 'Rzuć 6 kośćmi, aby uzyskać kombinacje, lub wpisz punkty ręcznie.\n\n• 1 = 100, 5 = 50\n• Trójka = wartość×100 (trójka jedynek = 1000), każda dodatkowa taka sama kość podwaja wartość.\n• Strit (1-6) lub trzy pary = 1500.\n• Żadna kość nie punktuje = FARKLE, punkty tury stracone.\n• Wszystkie 6 kości punktuje = Gorące Kości, rzuć ponownie wszystkimi 6.\n• Pierwsze zachowanie wymaga $minToOpen+ punktów.\n• Gdy gracz osiągnie cel, wszyscy inni mają jeszcze jedną turę - wygrywa najwyższy wynik.',
      },
      'tr': {
        'title': "10'000 (Farkle)", 'add_hint': 'Oyuncu Adı', 'add_err_min': 'En az 2 oyuncu!', 'max_players_err': 'En fazla 8 oyuncu!',
        'start': 'OYUNU BAŞLAT', 'rules': 'Kurallar', 'ok': 'ANLADIM',
        'target': 'Hedef Skor', 'input_mode': 'Giriş Modu', 'mode_dice': 'Zar', 'mode_manual': 'Manuel',
        'roll': 'ZAR AT', 'roll_again': 'TEKRAR AT', 'bank': 'BİRİKTİR', 'farkle': 'FARKLE!',
        'end_turn': 'TURU BİTİR', 'turn_total': 'Tur Puanı', 'total': 'Toplam', 'add_score': 'Puan Ekle',
        'add': 'EKLE', 'need_min': 'Açmak için en az $minToOpen puan gerekir',
        'hot_dice': 'HOT DICE! Tüm 6 zar tekrar kullanılabilir', 'farkle_msg': 'Puan getiren zar yok - tur puanları kayboldu!',
        'final_round': 'SON TUR!', 'winner': 'KAZANAN', 'game_over': 'Oyun Bitti', 'new_game_btn': 'Yeni Oyun',
        'current_turn': 'Sıra sende', 'rules_text': "Kombinasyonlar için 6 zar at, ya da puanlarını manuel olarak gir.\n\n• 1'ler = 100, 5'ler = 50\n• Üçlü = değer×100 (üç tane 1 = 1000), her ek eş zar değeri ikiye katlar.\n• Düz (1-6) veya üç çift = 1500.\n• Puan getiren zar yok = FARKLE, tur puanları kaybedilir.\n• Tüm 6 zar puan getirdi = Hot Dice, 6 zarı tekrar at.\n• İlk biriktirme için en az $minToOpen puan gerekir.\n• Bir oyuncu hedefe ulaştığında, diğer herkes bir tur daha oynar - en yüksek toplam kazanır.",
      },
      'id': {
        'title': "10'000 (Farkle)", 'add_hint': 'Nama Pemain', 'add_err_min': 'Min. 2 pemain!', 'max_players_err': 'Maks. 8 pemain!',
        'start': 'MULAI PERMAINAN', 'rules': 'Cara Bermain', 'ok': 'MENGERTI',
        'target': 'Skor Target', 'input_mode': 'Mode Input', 'mode_dice': 'Dadu', 'mode_manual': 'Manual',
        'roll': 'LEMPAR', 'roll_again': 'LEMPAR LAGI', 'bank': 'SIMPAN', 'farkle': 'FARKLE!',
        'end_turn': 'AKHIRI GILIRAN', 'turn_total': 'Poin Giliran', 'total': 'Total', 'add_score': 'Tambah Skor',
        'add': 'TAMBAH', 'need_min': 'Butuh $minToOpen+ poin untuk membuka',
        'hot_dice': 'HOT DICE! Semua 6 dadu tersedia lagi', 'farkle_msg': 'Tidak ada dadu yang mencetak poin - poin giliran hilang!',
        'final_round': 'RONDE TERAKHIR!', 'winner': 'PEMENANG', 'game_over': 'Permainan Selesai', 'new_game_btn': 'Permainan Baru',
        'current_turn': 'Giliranmu', 'rules_text': 'Lempar 6 dadu untuk kombinasi, atau ketik poin Anda secara manual.\n\n• 1 = 100, 5 = 50\n• Tiga sama = nilai×100 (tiga 1 = 1000), setiap dadu sama tambahan menggandakan nilai.\n• Straight (1-6) atau tiga pasang = 1500.\n• Tidak ada dadu yang mencetak poin = FARKLE, poin giliran hilang.\n• Semua 6 dadu mencetak poin = Hot Dice, lempar lagi ke-6 dadu.\n• Simpan pertama membutuhkan $minToOpen+ poin.\n• Begitu pemain mencapai target, semua pemain lain mendapat satu giliran lagi - total tertinggi menang.',
      },
      'sv': {
        'title': "10'000 (Farkle)", 'add_hint': 'Spelarnamn', 'add_err_min': 'Min. 2 spelare!', 'max_players_err': 'Max. 8 spelare!',
        'start': 'STARTA SPEL', 'rules': 'Regler', 'ok': 'FÖRSTÅTT',
        'target': 'Målpoäng', 'input_mode': 'Inmatningsläge', 'mode_dice': 'Tärningar', 'mode_manual': 'Manuellt',
        'roll': 'KASTA', 'roll_again': 'KASTA IGEN', 'bank': 'SPARA', 'farkle': 'FARKLE!',
        'end_turn': 'AVSLUTA TUR', 'turn_total': 'Turpoäng', 'total': 'Totalt', 'add_score': 'Lägg till poäng',
        'add': 'LÄGG TILL', 'need_min': 'Kräver $minToOpen+ poäng för att öppna',
        'hot_dice': 'HOT DICE! Alla 6 tärningar tillgängliga igen', 'farkle_msg': 'Ingen poänggivande tärning - turpoäng förlorade!',
        'final_round': 'SISTA RUNDAN!', 'winner': 'VINNARE', 'game_over': 'Spelet Slut', 'new_game_btn': 'Nytt Spel',
        'current_turn': 'Din tur', 'rules_text': 'Kasta 6 tärningar för kombinationer, eller skriv in dina poäng manuellt.\n\n• Ettor = 100, femmor = 50\n• Triss = värde×100 (triss av ettor = 1000), varje extra matchande tärning dubblar värdet.\n• Stege (1-6) eller tre par = 1500.\n• Ingen poänggivande tärning = FARKLE, turpoäng förlorade.\n• Alla 6 tärningar gav poäng = Hot Dice, kasta alla 6 igen.\n• Första sparandet kräver $minToOpen+ poäng.\n• När en spelare når målet får alla andra en sista tur - högsta totalen vinner.',
      },
      'hr': {
        'title': "10'000 (Farkle)", 'add_hint': 'Ime igrača', 'add_err_min': 'Min. 2 igrača!', 'max_players_err': 'Maks. 8 igrača!',
        'start': 'POKRENI IGRU', 'rules': 'Upute', 'ok': 'RAZUMIJEM',
        'target': 'Ciljani rezultat', 'input_mode': 'Način unosa', 'mode_dice': 'Kockice', 'mode_manual': 'Ručno',
        'roll': 'BACI', 'roll_again': 'BACI PONOVO', 'bank': 'SPREMI', 'farkle': 'FARKLE!',
        'end_turn': 'ZAVRŠI POTEZ', 'turn_total': 'Bodovi poteza', 'total': 'Ukupno', 'add_score': 'Dodaj bodove',
        'add': 'DODAJ', 'need_min': 'Potrebno $minToOpen+ bodova za otvaranje',
        'hot_dice': 'HOT DICE! Svih 6 kockica opet dostupno', 'farkle_msg': 'Nijedna kockica ne boduje - bodovi poteza izgubljeni!',
        'final_round': 'ZADNJA RUNDA!', 'winner': 'POBJEDNIK', 'game_over': 'Igra Završena', 'new_game_btn': 'Nova Igra',
        'current_turn': 'Ti si na potezu', 'rules_text': 'Baci 6 kockica za kombinacije, ili ručno upiši svoje bodove.\n\n• Jedinice = 100, petice = 50\n• Tris = vrijednost×100 (tris jedinica = 1000), svaka dodatna ista kockica udvostručuje vrijednost.\n• Niz (1-6) ili tri para = 1500.\n• Nijedna kockica ne boduje = FARKLE, bodovi poteza izgubljeni.\n• Svih 6 kockica je bodovalo = Hot Dice, baci svih 6 ponovno.\n• Prvo spremanje zahtijeva $minToOpen+ bodova.\n• Čim igrač dosegne cilj, svi ostali imaju još jedan potez - najviši ukupni rezultat pobjeđuje.',
      },
      'ru': {
        'title': "10'000 (Farkle)", 'add_hint': 'Имя игрока', 'add_err_min': 'Мин. 2 игрока!', 'max_players_err': 'Макс. 8 игроков!',
        'start': 'НАЧАТЬ ИГРУ', 'rules': 'Правила', 'ok': 'ПОНЯТНО',
        'target': 'Целевой счёт', 'input_mode': 'Режим ввода', 'mode_dice': 'Кубики', 'mode_manual': 'Вручную',
        'roll': 'БРОСИТЬ', 'roll_again': 'БРОСИТЬ ЕЩЁ', 'bank': 'СОХРАНИТЬ', 'farkle': 'FARKLE!',
        'end_turn': 'ЗАВЕРШИТЬ ХОД', 'turn_total': 'Очки хода', 'total': 'Всего', 'add_score': 'Добавить очки',
        'add': 'ДОБАВИТЬ', 'need_min': 'Требуется от $minToOpen очков, чтобы открыть счёт',
        'hot_dice': 'HOT DICE! Все 6 кубиков снова доступны', 'farkle_msg': 'Ни один кубик не сыграл - очки хода потеряны!',
        'final_round': 'ПОСЛЕДНИЙ РАУНД!', 'winner': 'ПОБЕДИТЕЛЬ', 'game_over': 'Игра окончена', 'new_game_btn': 'Новая игра',
        'current_turn': 'Ваш ход', 'rules_text': 'Бросайте 6 кубиков ради комбинаций или вводите очки вручную.\n\n• Единицы = 100, пятёрки = 50\n• Тройка = значение×100 (тройка единиц = 1000), каждый дополнительный такой же кубик удваивает значение.\n• Стрит (1-6) или три пары = 1500.\n• Ни один кубик не сыграл = FARKLE, очки хода потеряны.\n• Все 6 кубиков сыграли = Hot Dice, бросайте все 6 кубиков снова.\n• Для первого сохранения нужно от $minToOpen очков.\n• Как только игрок достигает цели, все остальные получают ещё один ход - побеждает наивысшая сумма.',
      },
      'ja': {
        'title': "10'000 (Farkle)", 'add_hint': 'プレイヤー名', 'add_err_min': '最低2人必要！', 'max_players_err': '最大8人まで！',
        'start': 'ゲーム開始', 'rules': '遊び方', 'ok': '了解',
        'target': '目標スコア', 'input_mode': '入力モード', 'mode_dice': 'サイコロ', 'mode_manual': '手動',
        'roll': '振る', 'roll_again': 'もう一度振る', 'bank': '確定', 'farkle': 'ファークル！',
        'end_turn': 'ターン終了', 'turn_total': 'ターン得点', 'total': '合計', 'add_score': '得点を追加',
        'add': '追加', 'need_min': '確定するには$minToOpen点以上必要',
        'hot_dice': 'ホットダイス！ 6個のサイコロが再び使用可能', 'farkle_msg': '得点なし - ターン得点を失いました！',
        'final_round': '最終ラウンド！', 'winner': '勝者', 'game_over': 'ゲーム終了', 'new_game_btn': '新しいゲーム',
        'current_turn': 'あなたの番です', 'rules_text': '6個のサイコロで役を作るか、得点を手動で入力してください。\n\n• 1 = 100点、5 = 50点\n• スリーカード = 値×100（1のスリーカードは1000点）、同じ目が追加されるごとに倍になります。\n• ストレート（1-6）または3組のペア = 1500点。\n• 得点なし = ファークル、ターン得点を失います。\n• 6個すべてが得点 = ホットダイス、6個すべてを振り直せます。\n• 最初の確定には$minToOpen点以上必要です。\n• 誰かが目標に到達すると、他の全員がもう1回ターンを行います - 合計が最も高い人が勝ちです。',
      },
      'ko': {
        'title': "10'000 (Farkle)", 'add_hint': '플레이어 이름', 'add_err_min': '최소 2명 필요!', 'max_players_err': '최대 8명!',
        'start': '게임 시작', 'rules': '규칙', 'ok': '확인',
        'target': '목표 점수', 'input_mode': '입력 모드', 'mode_dice': '주사위', 'mode_manual': '수동',
        'roll': '굴리기', 'roll_again': '다시 굴리기', 'bank': '저장', 'farkle': '파클!',
        'end_turn': '턴 종료', 'turn_total': '턴 점수', 'total': '합계', 'add_score': '점수 추가',
        'add': '추가', 'need_min': '저장하려면 최소 $minToOpen점 필요',
        'hot_dice': '핫 다이스! 6개 주사위 다시 사용 가능', 'farkle_msg': '득점한 주사위 없음 - 턴 점수를 잃었습니다!',
        'final_round': '마지막 라운드!', 'winner': '승자', 'game_over': '게임 종료', 'new_game_btn': '새 게임',
        'current_turn': '당신의 차례입니다', 'rules_text': '6개의 주사위를 굴려 조합을 만들거나 점수를 수동으로 입력하세요.\n\n• 1 = 100점, 5 = 50점\n• 트리플 = 값×100 (1의 트리플은 1000점), 추가되는 같은 주사위마다 값이 두 배가 됩니다.\n• 스트레이트 (1-6) 또는 3쌍 = 1500점.\n• 득점한 주사위 없음 = 파클, 턴 점수를 잃습니다.\n• 6개 모두 득점 = 핫 다이스, 6개를 모두 다시 굴릴 수 있습니다.\n• 첫 저장에는 최소 $minToOpen점이 필요합니다.\n• 한 플레이어가 목표에 도달하면 다른 모든 플레이어가 마지막 턴을 갖습니다 - 총점이 가장 높은 사람이 승리합니다.',
      },
      'zh': {
        'title': "10'000 (Farkle)", 'add_hint': '玩家姓名', 'add_err_min': '至少需要2名玩家！', 'max_players_err': '最多8名玩家！',
        'start': '开始游戏', 'rules': '规则', 'ok': '明白了',
        'target': '目标分数', 'input_mode': '输入模式', 'mode_dice': '骰子', 'mode_manual': '手动',
        'roll': '掷骰子', 'roll_again': '再次掷骰子', 'bank': '入账', 'farkle': 'FARKLE！',
        'end_turn': '结束回合', 'turn_total': '本回合得分', 'total': '总分', 'add_score': '添加分数',
        'add': '添加', 'need_min': '入账需要至少$minToOpen分',
        'hot_dice': 'HOT DICE！ 6个骰子可再次使用', 'farkle_msg': '没有骰子得分 - 本回合得分作废！',
        'final_round': '最后一轮！', 'winner': '获胜者', 'game_over': '游戏结束', 'new_game_btn': '新游戏',
        'current_turn': '轮到你了', 'rules_text': '掷6个骰子组合得分，或手动输入你的分数。\n\n• 1点=100分，5点=50分\n• 三个相同=点数×100（三个1=1000分），每多一个相同骰子分数翻倍。\n• 顺子(1-6)或三对=1500分。\n• 没有骰子得分=FARKLE，本回合得分作废。\n• 6个骰子全部得分=HOT DICE，可以重新掷全部6个骰子。\n• 首次入账需要至少$minToOpen分。\n• 一旦有玩家达到目标分数，其他所有玩家都可以再进行一轮 - 总分最高者获胜。',
      },
      'hi': {
        'title': "10'000 (Farkle)", 'add_hint': 'खिलाड़ी का नाम', 'add_err_min': 'कम से कम 2 खिलाड़ी चाहिए!', 'max_players_err': 'अधिकतम 8 खिलाड़ी!',
        'start': 'खेल शुरू करें', 'rules': 'नियम', 'ok': 'समझ गया',
        'target': 'लक्ष्य स्कोर', 'input_mode': 'इनपुट मोड', 'mode_dice': 'पासा', 'mode_manual': 'मैनुअल',
        'roll': 'रोल करें', 'roll_again': 'फिर से रोल करें', 'bank': 'बैंक करें', 'farkle': 'फार्कल!',
        'end_turn': 'बारी समाप्त करें', 'turn_total': 'बारी के अंक', 'total': 'कुल', 'add_score': 'स्कोर जोड़ें',
        'add': 'जोड़ें', 'need_min': 'बैंक करने के लिए कम से कम $minToOpen अंक चाहिए',
        'hot_dice': 'हॉट डाइस! सभी 6 पासे फिर से उपलब्ध', 'farkle_msg': 'कोई अंक नहीं मिला - बारी के अंक खो गए!',
        'final_round': 'अंतिम दौर!', 'winner': 'विजेता', 'game_over': 'खेल समाप्त', 'new_game_btn': 'नया खेल',
        'current_turn': 'आपकी बारी है', 'rules_text': '6 पासे रोल करके कॉम्बो बनाएं, या अपने अंक मैन्युअल रूप से दर्ज करें।\n\n• 1 = 100, 5 = 50\n• तीन समान = मान×100 (तीन 1 = 1000), हर अतिरिक्त समान पासा मान को दोगुना कर देता है।\n• स्ट्रेट (1-6) या तीन जोड़े = 1500।\n• कोई अंक नहीं मिला = फार्कल, बारी के अंक खो जाते हैं।\n• सभी 6 पासों ने अंक दिए = हॉट डाइस, सभी 6 पासे फिर से रोल करें।\n• पहले बैंक करने के लिए कम से कम $minToOpen अंक चाहिए।\n• जैसे ही कोई खिलाड़ी लक्ष्य तक पहुंचता है, बाकी सभी को एक और बारी मिलती है - सबसे अधिक कुल अंक वाला जीतता है।',
      },
      'bn': {
        'title': "10'000 (Farkle)", 'add_hint': 'খেলোয়াড়ের নাম', 'add_err_min': 'কমপক্ষে ২ জন খেলোয়াড় প্রয়োজন!', 'max_players_err': 'সর্বোচ্চ ৮ জন খেলোয়াড়!',
        'start': 'খেলা শুরু করুন', 'rules': 'নিয়মাবলী', 'ok': 'বুঝেছি',
        'target': 'লক্ষ্য স্কোর', 'input_mode': 'ইনপুট মোড', 'mode_dice': 'পাশা', 'mode_manual': 'ম্যানুয়াল',
        'roll': 'রোল করুন', 'roll_again': 'আবার রোল করুন', 'bank': 'জমা করুন', 'farkle': 'ফার্কল!',
        'end_turn': 'পালা শেষ করুন', 'turn_total': 'পালার পয়েন্ট', 'total': 'মোট', 'add_score': 'স্কোর যোগ করুন',
        'add': 'যোগ করুন', 'need_min': 'জমা করতে কমপক্ষে $minToOpen পয়েন্ট প্রয়োজন',
        'hot_dice': 'হট ডাইস! সবগুলো ৬টি পাশা আবার ব্যবহারযোগ্য', 'farkle_msg': 'কোনো পাশায় পয়েন্ট নেই - পালার পয়েন্ট হারিয়ে গেছে!',
        'final_round': 'শেষ রাউন্ড!', 'winner': 'বিজয়ী', 'game_over': 'খেলা শেষ', 'new_game_btn': 'নতুন খেলা',
        'current_turn': 'আপনার পালা', 'rules_text': 'কম্বোর জন্য ৬টি পাশা রোল করুন, অথবা ম্যানুয়ালি আপনার পয়েন্ট লিখুন।\n\n• ১ = ১০০, ৫ = ৫০\n• তিনটি একই = মান×১০০ (তিনটি ১ = ১০০০), প্রতিটি অতিরিক্ত একই পাশা মান দ্বিগুণ করে।\n• স্ট্রেট (১-৬) অথবা তিন জোড়া = ১৫০০।\n• কোনো পাশায় পয়েন্ট নেই = ফার্কল, পালার পয়েন্ট হারিয়ে যায়।\n• সবগুলো ৬টি পাশায় পয়েন্ট পাওয়া গেছে = হট ডাইস, আবার সবগুলো ৬টি পাশা রোল করুন।\n• প্রথম জমা করতে কমপক্ষে $minToOpen পয়েন্ট প্রয়োজন।\n• কোনো খেলোয়াড় লক্ষ্যে পৌঁছালে, বাকি সবাই আরেকটি পালা পায় - সর্বোচ্চ মোট স্কোরধারী জয়ী হয়।',
      },
      'ar': {
        'title': "10'000 (Farkle)", 'add_hint': 'اسم اللاعب', 'add_err_min': 'الحد الأدنى لاعبان!', 'max_players_err': 'الحد الأقصى 8 لاعبين!',
        'start': 'بدء اللعبة', 'rules': 'القواعد', 'ok': 'فهمت',
        'target': 'النتيجة المستهدفة', 'input_mode': 'وضع الإدخال', 'mode_dice': 'النرد', 'mode_manual': 'يدوي',
        'roll': 'ارمِ النرد', 'roll_again': 'ارمِ مرة أخرى', 'bank': 'احفظ النقاط', 'farkle': 'فاركل!',
        'end_turn': 'إنهاء الدور', 'turn_total': 'نقاط الدور', 'total': 'الإجمالي', 'add_score': 'إضافة نقاط',
        'add': 'إضافة', 'need_min': 'يتطلب $minToOpen+ نقطة لفتح الحساب',
        'hot_dice': 'هوت دايس! جميع النرد الستة متاحة مجدداً', 'farkle_msg': 'لا يوجد نرد مسجل للنقاط - نقاط الدور ضاعت!',
        'final_round': 'الجولة الأخيرة!', 'winner': 'الفائز', 'game_over': 'انتهت اللعبة', 'new_game_btn': 'لعبة جديدة',
        'current_turn': 'دورك الآن', 'rules_text': 'ارمِ 6 قطع نرد لتكوين تركيبات، أو أدخل نقاطك يدوياً.\n\n• الرقم 1 = 100، الرقم 5 = 50\n• ثلاثة متطابقة = القيمة×100 (ثلاثة آحاد = 1000)، كل نرد إضافي مطابق يضاعف القيمة.\n• تتابع (1-6) أو ثلاثة أزواج = 1500.\n• لا يوجد نرد مسجل للنقاط = فاركل، تضيع نقاط الدور.\n• سجلت جميع النرد الستة نقاطاً = هوت دايس، ارمِ النرد الستة مجدداً.\n• يتطلب أول حفظ للنقاط $minToOpen+ نقطة.\n• بمجرد وصول أحد اللاعبين إلى الهدف، يحصل جميع اللاعبين الآخرين على دور أخير - يفوز صاحب أعلى مجموع.',
      },
    };

    if (dictionary.containsKey(_currentLang) && dictionary[_currentLang]!.containsKey(key)) {
      return dictionary[_currentLang]![key]!;
    }
    return dictionary['en']![key] ?? key;
  }

  // --- SETUP ---

  void _addPlayer() {
    if (_nameController.text.trim().isNotEmpty) {
      if (_players.length >= 8) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('max_players_err'))));
        return;
      }
      setState(() {
        _players.add(TenKPlayer(_nameController.text.trim()));
        _nameController.clear();
      });
    }
  }

  void _startGame() {
    FocusScope.of(context).unfocus();
    if (_players.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('add_err_min'))));
      return;
    }
    setState(() {
      for (var p in _players) {
        p.grandTotal = 0;
        p.isOnBoard = false;
      }
      _gameStarted = true;
      _gameFinished = false;
      _currentPlayerIndex = 0;
      _finalRoundTriggered = false;
      _finalRoundTriggerIndex = null;
      _turnsLeftInFinalRound = 0;
      _resetTurn();
    });
  }

  void _resetGame() {
    setState(() {
      _gameStarted = false;
      _gameFinished = false;
      _players.clear();
    });
  }

  void _resetTurn() {
    _turnTotal = 0;
    _currentRoll = [];
    _diceToRoll = 6;
    _hasRolledThisTurn = false;
    _bustedThisRoll = false;
    _manualInputController.clear();
  }

  // --- ZUG-LOGIK (gemeinsam) ---

  void _farkleTurn() {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: errorColor,
      content: Text(_t('farkle_msg')),
      duration: const Duration(seconds: 2),
    ));
    _advanceTurn();
  }

  void _bankTurn() {
    TenKPlayer player = _players[_currentPlayerIndex];
    if (!player.isOnBoard && _turnTotal < minToOpen) return;

    HapticFeedback.mediumImpact();
    setState(() {
      player.grandTotal += _turnTotal;
      player.isOnBoard = true;

      if (!_finalRoundTriggered && player.grandTotal >= _targetScore) {
        _finalRoundTriggered = true;
        _finalRoundTriggerIndex = _currentPlayerIndex;
        _turnsLeftInFinalRound = _players.length - 1;
      }
    });
    _advanceTurn();
  }

  void _advanceTurn() {
    setState(() {
      if (_finalRoundTriggered && _currentPlayerIndex != _finalRoundTriggerIndex) {
        _turnsLeftInFinalRound--;
      }
      if (_finalRoundTriggered && _turnsLeftInFinalRound <= 0) {
        _gameFinished = true;
        return;
      }
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
      _resetTurn();
    });
  }

  // --- WÜRFEL-MODUS ---

  void _rollDice() {
    HapticFeedback.selectionClick();
    List<int> rolled = List.generate(_diceToRoll, (_) => _rng.nextInt(6) + 1);
    FarkleResult result = FarkleScorer.score(rolled);

    setState(() {
      _currentRoll = rolled;
      _hasRolledThisTurn = true;

      if (result.isFarkle) {
        _bustedThisRoll = true;
        return;
      }

      _bustedThisRoll = false;
      _turnTotal += result.points;
      int remaining = _diceToRoll - result.usedCount;
      _diceToRoll = remaining == 0 ? 6 : remaining;
    });

    if (result.isFarkle) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        _farkleTurn();
      });
    }
  }

  // --- MANUELLER MODUS ---

  void _addManualScore() {
    int? val = int.tryParse(_manualInputController.text);
    if (val == null || val <= 0) return;
    setState(() {
      _turnTotal += val;
      _manualInputController.clear();
    });
  }

  void _showRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: primaryColor)),
        title: Text(_t('rules'), style: TextStyle(color: primaryColor)),
        content: SingleChildScrollView(child: Text(_t('rules_text'), style: const TextStyle(color: Colors.white70, height: 1.5))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_t('ok'), style: TextStyle(color: primaryColor))),
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
            IconButton(icon: const Icon(Icons.refresh), onPressed: _resetGame),
          IconButton(icon: const Icon(Icons.help_outline), onPressed: _showRules),
        ],
      ),
      body: SafeArea(
        child: _gameFinished
            ? _buildGameOver()
            : (_gameStarted ? _buildGameScreen() : _buildSetupScreen()),
      ),
    );
  }

  // --- SETUP SCREEN ---
  Widget _buildSetupScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.casino, size: 80, color: primaryColor),
          const SizedBox(height: 20),

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
          const SizedBox(height: 15),
          if (_players.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _players.length,
                itemBuilder: (context, index) => Card(
                  color: surfaceColor,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.black26, child: Text("${index + 1}", style: const TextStyle(color: Colors.white))),
                    title: Text(_players[index].name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    trailing: IconButton(icon: Icon(Icons.close, color: errorColor), onPressed: () => setState(() => _players.removeAt(index))),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 25),
          Align(alignment: Alignment.centerLeft, child: Text(_t('target'), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14))),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [4000, 6000, 10000].map((val) {
              bool selected = _targetScore == val;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ChoiceChip(
                  label: Text("$val", style: TextStyle(color: selected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                  selected: selected,
                  selectedColor: primaryColor,
                  backgroundColor: surfaceColor,
                  onSelected: (_) => setState(() => _targetScore = val),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 25),
          Align(alignment: Alignment.centerLeft, child: Text(_t('input_mode'), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14))),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _modeChip(_t('mode_dice'), Icons.casino, TenKInputMode.dice)),
              const SizedBox(width: 10),
              Expanded(child: _modeChip(_t('mode_manual'), Icons.edit, TenKInputMode.manual)),
            ],
          ),

          const SizedBox(height: 30),
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

  Widget _modeChip(String label, IconData icon, TenKInputMode mode) {
    bool selected = _inputMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _inputMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? primaryColor : surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? primaryColor : Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? Colors.black : Colors.white70),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: selected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // --- GAME SCREEN ---
  Widget _buildGameScreen() {
    TenKPlayer current = _players[_currentPlayerIndex];

    return Column(
      children: [
        if (_finalRoundTriggered)
          Container(
            width: double.infinity,
            color: errorColor,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Center(child: Text(_t('final_round'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1))),
          ),

        // SCOREBOARD
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            itemCount: _players.length,
            itemBuilder: (context, index) {
              final p = _players[index];
              bool isTurn = index == _currentPlayerIndex;
              return Container(
                width: 130,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isTurn ? primaryColor.withOpacity(0.15) : surfaceColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isTurn ? primaryColor : Colors.white10, width: isTurn ? 2 : 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(p.name, style: TextStyle(color: isTurn ? primaryColor : Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text("${p.grandTotal}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
              );
            },
          ),
        ),

        Expanded(
          child: _inputMode == TenKInputMode.dice ? _buildDiceTurn(current) : _buildManualTurn(current),
        ),
      ],
    );
  }

  Widget _buildTurnHeader(TenKPlayer current) {
    return Column(
      children: [
        Text("${current.name} — ${_t('current_turn')}", style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text("$_turnTotal", style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900)),
        Text(_t('turn_total'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildBankButton(TenKPlayer current) {
    bool canBank = _turnTotal > 0 && (current.isOnBoard || _turnTotal >= minToOpen);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: canBank ? _bankTurn : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canBank ? successColor : Colors.grey.shade800,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: Text("${_t('bank')} ($_turnTotal)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        if (!current.isOnBoard && _turnTotal < minToOpen)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_t('need_min'), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ),
      ],
    );
  }

  // --- WÜRFEL-MODUS UI ---
  Widget _buildDiceTurn(TenKPlayer current) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTurnHeader(current),
          const SizedBox(height: 20),

          Expanded(
            child: Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _currentRoll.isEmpty
                    ? [Text(_t('roll'), style: TextStyle(color: Colors.grey.shade600, fontSize: 16))]
                    : _currentRoll.map((d) => _buildDieWidget(d)).toList(),
              ),
            ),
          ),

          if (_bustedThisRoll)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(_t('farkle'), style: TextStyle(color: errorColor, fontSize: 28, fontWeight: FontWeight.w900)),
            )
          else if (_hasRolledThisTurn && _diceToRoll == 6)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(_t('hot_dice'), style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),

          if (!_bustedThisRoll) ...[
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _rollDice,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: Text(_hasRolledThisTurn ? "${_t('roll_again')} ($_diceToRoll)" : "${_t('roll')} (6)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            if (_turnTotal > 0) ...[
              const SizedBox(height: 12),
              _buildBankButton(current),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDieWidget(int value) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
      ),
      child: Center(
        child: Text("$value", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- MANUELLER MODUS UI ---
  Widget _buildManualTurn(TenKPlayer current) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTurnHeader(current),
          const Spacer(),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualInputController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: _t('add_score'),
                    hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    filled: true,
                    fillColor: surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _addManualScore(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _addManualScore,
                style: IconButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.all(16)),
                icon: const Icon(Icons.add, color: Colors.black),
              ),
            ],
          ),

          const Spacer(),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 55,
                  child: OutlinedButton(
                    onPressed: _farkleTurn,
                    style: OutlinedButton.styleFrom(side: BorderSide(color: errorColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: Text(_t('farkle'), style: TextStyle(color: errorColor, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBankButton(current),
        ],
      ),
    );
  }

  // --- GAME OVER ---
  Widget _buildGameOver() {
    List<TenKPlayer> sorted = List.from(_players);
    sorted.sort((a, b) => b.grandTotal.compareTo(a.grandTotal));
    TenKPlayer winner = sorted.first;

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
              Text(winner.name, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text("${winner.grandTotal}", style: TextStyle(color: primaryColor, fontSize: 20)),
              const SizedBox(height: 30),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final player = sorted[index];
                  return Card(
                    color: surfaceColor,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: index == 0 ? primaryColor : Colors.grey.shade700,
                        foregroundColor: index == 0 ? Colors.black : Colors.white,
                        child: Text("${index + 1}."),
                      ),
                      title: Text(player.name, style: const TextStyle(color: Colors.white)),
                      trailing: Text("${player.grandTotal}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(backgroundColor: successColor),
                  child: const Text("REMATCH", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(onPressed: _resetGame, child: Text(_t('new_game_btn'), style: const TextStyle(color: Colors.grey))),
            ],
          ),
        ),
      ),
    );
  }
}
