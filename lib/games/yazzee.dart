import 'package:flutter/material.dart';
import '../main.dart';

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

  // Fertig, wenn alle ausfüllbaren Kategorien einen Wert haben
  bool get isComplete => fillableCategories.every((c) => scores.containsKey(c));
}

// Kategorien Definitionen (interne, sprachunabhängige Schlüssel)
final List<String> categories = [
  // Oben
  '1er', '2er', '3er', '4er', '5er', '6er',
  'SUMME OBEN', // Berechnet
  'BONUS',      // Berechnet
  // Unten
  '3er Pasch', '4er Pasch', 'Full House', 'Kl. Straße', 'Gr. Straße', 'Yahtzee', 'Chance',
  'GESAMT'      // Berechnet
];

// Kategorien, die tatsächlich vom Spieler ausgefüllt werden (ohne berechnete Felder)
final List<String> fillableCategories = categories.where(
        (c) => !['SUMME OBEN', 'BONUS', 'GESAMT'].contains(c)).toList();

// Übersetzungs-Schlüssel je interner Kategorie
const Map<String, String> _categoryTranslationKeys = {
  '1er': 'cat_1', '2er': 'cat_2', '3er': 'cat_3', '4er': 'cat_4', '5er': 'cat_5', '6er': 'cat_6',
  'SUMME OBEN': 'cat_upper_sum', 'BONUS': 'cat_bonus',
  '3er Pasch': 'cat_three_kind', '4er Pasch': 'cat_four_kind', 'Full House': 'cat_full_house',
  'Kl. Straße': 'cat_small_straight', 'Gr. Straße': 'cat_large_straight',
  'Yahtzee': 'cat_yahtzee', 'Chance': 'cat_chance', 'GESAMT': 'cat_total',
};

class YazzeeGame extends StatefulWidget {
  final Color? themeColor;
  const YazzeeGame({super.key, this.themeColor});

  @override
  State<YazzeeGame> createState() => _YazzeeGameState();
}

class _YazzeeGameState extends State<YazzeeGame> {
  // --- FARBEN & STYLE ---
  Color get primaryColor => widget.themeColor ?? const Color(0xFF4CBF98); // Diesmal Grün als Hauptfarbe
  final Color secondaryColor = const Color(0xFFEBCB63); // Gelb für Akzente
  final Color bgColor = const Color(0xFF222629);
  final Color surfaceColor = const Color(0xFF30363B);
  final Color cardColor = const Color(0xFF3A4146);
  final Color errorColor = const Color(0xFFEB6B6B);
  final Color successColor = const Color(0xFF4CBF98);

  // Sprache: immer live vom globalen App-Status gelesen (reaktiv auf Sprachwechsel)
  String get _currentLang => appLocaleNotifier.value.languageCode;

  // --- STATE ---
  bool _gameStarted = false;
  bool _gameFinished = false;
  int _currentPlayerIndex = 0;
  List<YazzeePlayer> _players = [];
  final TextEditingController _nameController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // --- ÜBERSETZUNG ---
  String _t(String key) {
    const Map<String, Map<String, String>> dictionary = {
      'de': {
        'title': 'Yazzee', 'new_game_tooltip': 'Neues Spiel', 'add_hint': 'Spieler Name',
        'max_players_err': 'Maximal 6 Spieler!', 'min_players_err': 'Mindestens 1 Spieler!',
        'start_btn': 'SPIEL STARTEN', 'cancel': 'ABBRECHEN', 'save': 'SPEICHERN',
        'strike': 'Streichen (0)', 'standard_prefix': 'Standard', 'for_player': 'für',
        'winner_label': 'SIEGER', 'points_label': 'Punkte', 'rematch': 'REVANCHE',
        'new_game_setup': 'Neues Spiel (Setup)', 'rules': 'Anleitung', 'ok': 'VERSTANDEN',
        'rules_text': 'Ein Würfel-Punkteblock für Yahtzee-artige Spiele (physische Würfel benötigt).\n\n'
            '• Jeder Spieler würfelt und trägt sein Ergebnis in eine passende Kategorie ein.\n'
            '• Oben (1er-6er): Summe der jeweiligen Augenzahl.\n'
            '• Bonus: 35 Punkte, wenn die Summe oben mindestens 63 beträgt.\n'
            '• Unten: 3er/4er Pasch (Augensumme aller Würfel), Full House (25), Kleine Straße (30), Große Straße (40), Yahtzee (50), Chance (Augensumme).\n'
            '• Eine Kategorie kann auch mit 0 gestrichen werden, wenn kein passender Wurf gelingt.\n'
            '• Das Spiel endet, sobald alle Spieler alle Kategorien ausgefüllt haben - die höchste Gesamtpunktzahl gewinnt.',
        'cat_1': '1er', 'cat_2': '2er', 'cat_3': '3er', 'cat_4': '4er', 'cat_5': '5er', 'cat_6': '6er',
        'cat_upper_sum': 'SUMME OBEN', 'cat_bonus': 'BONUS',
        'cat_three_kind': '3er Pasch', 'cat_four_kind': '4er Pasch', 'cat_full_house': 'Full House',
        'cat_small_straight': 'Kl. Straße', 'cat_large_straight': 'Gr. Straße',
        'cat_yahtzee': 'Yahtzee', 'cat_chance': 'Chance', 'cat_total': 'GESAMT',
      },
      'en': {
        'title': 'Yazzee', 'new_game_tooltip': 'New Game', 'add_hint': 'Player Name',
        'max_players_err': 'Max 6 players!', 'min_players_err': 'Need at least 1 player!',
        'start_btn': 'START GAME', 'cancel': 'CANCEL', 'save': 'SAVE',
        'strike': 'Strike (0)', 'standard_prefix': 'Standard', 'for_player': 'for',
        'winner_label': 'WINNER', 'points_label': 'Points', 'rematch': 'REMATCH',
        'new_game_setup': 'New Game (Setup)', 'rules': 'Rules', 'ok': 'GOT IT',
        'rules_text': 'A dice score pad for Yahtzee-style games (physical dice required).\n\n'
            '• Each player rolls and enters their result into a matching category.\n'
            '• Upper section (Ones-Sixes): sum of that die value.\n'
            '• Bonus: 35 points if the upper section totals at least 63.\n'
            '• Lower section: Three/Four of a Kind (sum of all dice), Full House (25), Small Straight (30), Large Straight (40), Yahtzee (50), Chance (sum of all dice).\n'
            '• A category can also be struck with 0 if no matching roll is achieved.\n'
            '• The game ends once every player has filled every category - the highest total wins.',
        'cat_1': 'Ones', 'cat_2': 'Twos', 'cat_3': 'Threes', 'cat_4': 'Fours', 'cat_5': 'Fives', 'cat_6': 'Sixes',
        'cat_upper_sum': 'UPPER SUM', 'cat_bonus': 'BONUS',
        'cat_three_kind': 'Three of a Kind', 'cat_four_kind': 'Four of a Kind', 'cat_full_house': 'Full House',
        'cat_small_straight': 'Sm. Straight', 'cat_large_straight': 'Lg. Straight',
        'cat_yahtzee': 'Yahtzee', 'cat_chance': 'Chance', 'cat_total': 'TOTAL',
      },
      'fr': {
        'title': 'Yazzee', 'new_game_tooltip': 'Nouvelle partie', 'add_hint': 'Nom du joueur',
        'max_players_err': 'Maximum 6 joueurs !', 'min_players_err': 'Il faut au moins 1 joueur !',
        'start_btn': 'DÉMARRER', 'cancel': 'ANNULER', 'save': 'ENREGISTRER',
        'strike': 'Biffer (0)', 'standard_prefix': 'Standard', 'for_player': 'pour',
        'winner_label': 'VAINQUEUR', 'points_label': 'Points', 'rematch': 'REVANCHE',
        'new_game_setup': 'Nouvelle partie (Configuration)', 'rules': 'Règles', 'ok': 'COMPRIS',
        'rules_text': 'Un carnet de scores pour les jeux de type Yahtzee (dés physiques requis).\n\n'
            '• Chaque joueur lance les dés et inscrit son résultat dans une catégorie correspondante.\n'
            '• Section supérieure (Uns-Six) : somme de cette valeur de dé.\n'
            '• Bonus : 35 points si la section supérieure totalise au moins 63.\n'
            '• Section inférieure : Brelan/Carré (somme de tous les dés), Full House (25), Petite suite (30), Grande suite (40), Yahtzee (50), Chance (somme de tous les dés).\n'
            '• Une catégorie peut aussi être biffée avec 0 si aucun résultat correspondant n\'est obtenu.\n'
            '• La partie se termine quand chaque joueur a rempli toutes les catégories - le plus haut total gagne.',
        'cat_1': 'Uns', 'cat_2': 'Deux', 'cat_3': 'Trois', 'cat_4': 'Quatre', 'cat_5': 'Cinq', 'cat_6': 'Six',
        'cat_upper_sum': 'SOMME SUP.', 'cat_bonus': 'BONUS',
        'cat_three_kind': 'Brelan', 'cat_four_kind': 'Carré', 'cat_full_house': 'Full House',
        'cat_small_straight': 'Petite suite', 'cat_large_straight': 'Grande suite',
        'cat_yahtzee': 'Yahtzee', 'cat_chance': 'Chance', 'cat_total': 'TOTAL',
      },
      'it': {
        'title': 'Yazzee', 'new_game_tooltip': 'Nuova partita', 'add_hint': 'Nome giocatore',
        'max_players_err': 'Massimo 6 giocatori!', 'min_players_err': 'Serve almeno 1 giocatore!',
        'start_btn': 'INIZIA PARTITA', 'cancel': 'ANNULLA', 'save': 'SALVA',
        'strike': 'Cancella (0)', 'standard_prefix': 'Standard', 'for_player': 'per',
        'winner_label': 'VINCITORE', 'points_label': 'Punti', 'rematch': 'RIVINCITA',
        'new_game_setup': 'Nuova partita (Configurazione)', 'rules': 'Regole', 'ok': 'CAPITO',
        'rules_text': 'Un blocco punteggio per giochi in stile Yahtzee (dadi fisici richiesti).\n\n'
            '• Ogni giocatore lancia i dadi e inserisce il risultato nella categoria corrispondente.\n'
            '• Sezione superiore (Uno-Sei): somma di quel valore del dado.\n'
            '• Bonus: 35 punti se la sezione superiore totalizza almeno 63.\n'
            '• Sezione inferiore: Tris/Poker (somma di tutti i dadi), Full House (25), Scala piccola (30), Scala grande (40), Yahtzee (50), Chance (somma di tutti i dadi).\n'
            '• Una categoria può anche essere cancellata con 0 se non si ottiene un tiro corrispondente.\n'
            '• La partita termina quando ogni giocatore ha completato tutte le categorie - vince il totale più alto.',
        'cat_1': 'Uno', 'cat_2': 'Due', 'cat_3': 'Tre', 'cat_4': 'Quattro', 'cat_5': 'Cinque', 'cat_6': 'Sei',
        'cat_upper_sum': 'SOMMA SUP.', 'cat_bonus': 'BONUS',
        'cat_three_kind': 'Tris', 'cat_four_kind': 'Poker', 'cat_full_house': 'Full House',
        'cat_small_straight': 'Scala piccola', 'cat_large_straight': 'Scala grande',
        'cat_yahtzee': 'Yahtzee', 'cat_chance': 'Chance', 'cat_total': 'TOTALE',
      },
      'es': {
        'title': 'Yazzee', 'new_game_tooltip': 'Nueva partida', 'add_hint': 'Nombre del jugador',
        'max_players_err': '¡Máximo 6 jugadores!', 'min_players_err': '¡Se necesita al menos 1 jugador!',
        'start_btn': 'INICIAR PARTIDA', 'cancel': 'CANCELAR', 'save': 'GUARDAR',
        'strike': 'Tachar (0)', 'standard_prefix': 'Estándar', 'for_player': 'para',
        'winner_label': 'GANADOR', 'points_label': 'Puntos', 'rematch': 'REVANCHA',
        'new_game_setup': 'Nueva partida (Configuración)', 'rules': 'Reglas', 'ok': 'ENTENDIDO',
        'rules_text': 'Una hoja de puntuación para juegos estilo Yahtzee (se requieren dados físicos).\n\n'
            '• Cada jugador tira los dados e introduce su resultado en la categoría correspondiente.\n'
            '• Sección superior (Unos-Seises): suma de ese valor del dado.\n'
            '• Bono: 35 puntos si la sección superior totaliza al menos 63.\n'
            '• Sección inferior: Trío/Póker (suma de todos los dados), Full House (25), Escalera pequeña (30), Escalera grande (40), Yahtzee (50), Chance (suma de todos los dados).\n'
            '• Una categoría también se puede tachar con 0 si no se logra una tirada válida.\n'
            '• La partida termina cuando todos los jugadores han completado todas las categorías - gana el total más alto.',
        'cat_1': 'Unos', 'cat_2': 'Doses', 'cat_3': 'Treses', 'cat_4': 'Cuatros', 'cat_5': 'Cincos', 'cat_6': 'Seises',
        'cat_upper_sum': 'SUMA SUP.', 'cat_bonus': 'BONUS',
        'cat_three_kind': 'Trío', 'cat_four_kind': 'Póker', 'cat_full_house': 'Full House',
        'cat_small_straight': 'Escalera pequeña', 'cat_large_straight': 'Escalera grande',
        'cat_yahtzee': 'Yahtzee', 'cat_chance': 'Chance', 'cat_total': 'TOTAL',
      },
      'pt': {
        'title': 'Yazzee', 'new_game_tooltip': 'Novo jogo', 'add_hint': 'Nome do jogador',
        'max_players_err': 'Máximo 6 jogadores!', 'min_players_err': 'É necessário pelo menos 1 jogador!',
        'start_btn': 'INICIAR JOGO', 'cancel': 'CANCELAR', 'save': 'SALVAR',
        'strike': 'Riscar (0)', 'standard_prefix': 'Padrão', 'for_player': 'para',
        'winner_label': 'VENCEDOR', 'points_label': 'Pontos', 'rematch': 'REVANCHE',
        'new_game_setup': 'Novo jogo (Configuração)', 'rules': 'Regras', 'ok': 'ENTENDIDO',
        'rules_text': 'Uma folha de pontuação para jogos estilo Yahtzee (dados físicos necessários).\n\n'
            '• Cada jogador rola os dados e insere o resultado na categoria correspondente.\n'
            '• Seção superior (Uns-Seises): soma desse valor do dado.\n'
            '• Bônus: 35 pontos se a seção superior totalizar pelo menos 63.\n'
            '• Seção inferior: Trinca/Quadra (soma de todos os dados), Full House (25), Sequência pequena (30), Sequência grande (40), Yahtzee (50), Chance (soma de todos os dados).\n'
            '• Uma categoria também pode ser riscada com 0 se nenhuma jogada correspondente for obtida.\n'
            '• O jogo termina quando todos os jogadores preencherem todas as categorias - o maior total vence.',
        'cat_1': 'Uns', 'cat_2': 'Doses', 'cat_3': 'Treses', 'cat_4': 'Quatros', 'cat_5': 'Cincos', 'cat_6': 'Seises',
        'cat_upper_sum': 'SOMA SUP.', 'cat_bonus': 'BÔNUS',
        'cat_three_kind': 'Trinca', 'cat_four_kind': 'Quadra', 'cat_full_house': 'Full House',
        'cat_small_straight': 'Sequência pequena', 'cat_large_straight': 'Sequência grande',
        'cat_yahtzee': 'Yahtzee', 'cat_chance': 'Chance', 'cat_total': 'TOTAL',
      },
      'nl': {
        'title': 'Yazzee', 'new_game_tooltip': 'Nieuw spel', 'add_hint': 'Spelernaam',
        'max_players_err': 'Maximaal 6 spelers!', 'min_players_err': 'Minimaal 1 speler nodig!',
        'start_btn': 'SPEL STARTEN', 'cancel': 'ANNULEREN', 'save': 'OPSLAAN',
        'strike': 'Doorhalen (0)', 'standard_prefix': 'Standaard', 'for_player': 'voor',
        'winner_label': 'WINNAAR', 'points_label': 'Punten', 'rematch': 'REVANCHE',
        'new_game_setup': 'Nieuw spel (Instellingen)', 'rules': 'Regels', 'ok': 'BEGREPEN',
        'rules_text': 'Een dobbelscoreblok voor Yahtzee-achtige spellen (fysieke dobbelstenen nodig).\n\n'
            '• Elke speler gooit en noteert zijn resultaat in een passende categorie.\n'
            '• Bovenste sectie (Enen-Zessen): som van die dobbelsteenwaarde.\n'
            '• Bonus: 35 punten als de bovenste sectie minstens 63 bedraagt.\n'
            '• Onderste sectie: Drie/Vier gelijk (som van alle dobbelstenen), Full House (25), Kleine straat (30), Grote straat (40), Yahtzee (50), Kans (som van alle dobbelstenen).\n'
            '• Een categorie kan ook met 0 worden doorgehaald als geen passende worp lukt.\n'
            '• Het spel eindigt zodra elke speler alle categorieën heeft ingevuld - de hoogste totaalscore wint.',
        'cat_1': 'Enen', 'cat_2': 'Tweeën', 'cat_3': 'Drieën', 'cat_4': 'Vieren', 'cat_5': 'Vijven', 'cat_6': 'Zessen',
        'cat_upper_sum': 'SOM BOVEN', 'cat_bonus': 'BONUS',
        'cat_three_kind': 'Drie gelijk', 'cat_four_kind': 'Vier gelijk', 'cat_full_house': 'Full House',
        'cat_small_straight': 'Kl. straat', 'cat_large_straight': 'Gr. straat',
        'cat_yahtzee': 'Yahtzee', 'cat_chance': 'Kans', 'cat_total': 'TOTAAL',
      },
      'pl': {
        'title': 'Yazzee', 'new_game_tooltip': 'Nowa gra', 'add_hint': 'Imię gracza',
        'max_players_err': 'Maksymalnie 6 graczy!', 'min_players_err': 'Potrzeba co najmniej 1 gracza!',
        'start_btn': 'ROZPOCZNIJ GRĘ', 'cancel': 'ANULUJ', 'save': 'ZAPISZ',
        'strike': 'Skreśl (0)', 'standard_prefix': 'Standard', 'for_player': 'dla',
        'winner_label': 'ZWYCIĘZCA', 'points_label': 'Punkty', 'rematch': 'REWANŻ',
        'new_game_setup': 'Nowa gra (Ustawienia)', 'rules': 'Zasady', 'ok': 'ZROZUMIAŁEM',
        'rules_text': 'Blok punktowy do gier w stylu Yahtzee (wymagane fizyczne kości).\n\n'
            '• Każdy gracz rzuca kośćmi i wpisuje wynik do odpowiedniej kategorii.\n'
            '• Sekcja górna (Jedynki-Szóstki): suma danej wartości kości.\n'
            '• Bonus: 35 punktów, jeśli suma górna wynosi co najmniej 63.\n'
            '• Sekcja dolna: Trójka/Kareta (suma wszystkich kości), Full House (25), Mały strit (30), Duży strit (40), Yahtzee (50), Szansa (suma wszystkich kości).\n'
            '• Kategorię można też skreślić z wynikiem 0, jeśli nie uda się odpowiedni rzut.\n'
            '• Gra kończy się, gdy każdy gracz wypełni wszystkie kategorie - wygrywa najwyższa suma.',
        'cat_1': 'Jedynki', 'cat_2': 'Dwójki', 'cat_3': 'Trójki', 'cat_4': 'Czwórki', 'cat_5': 'Piątki', 'cat_6': 'Szóstki',
        'cat_upper_sum': 'SUMA GÓRNA', 'cat_bonus': 'BONUS',
        'cat_three_kind': 'Trójka', 'cat_four_kind': 'Kareta', 'cat_full_house': 'Full House',
        'cat_small_straight': 'Mały strit', 'cat_large_straight': 'Duży strit',
        'cat_yahtzee': 'Yahtzee', 'cat_chance': 'Szansa', 'cat_total': 'SUMA',
      },
      'tr': {
        'title': 'Yazzee', 'new_game_tooltip': 'Yeni oyun', 'add_hint': 'Oyuncu adı',
        'max_players_err': 'En fazla 6 oyuncu!', 'min_players_err': 'En az 1 oyuncu gerekli!',
        'start_btn': 'OYUNU BAŞLAT', 'cancel': 'İPTAL', 'save': 'KAYDET',
        'strike': 'Çiz (0)', 'standard_prefix': 'Standart', 'for_player': 'için',
        'winner_label': 'KAZANAN', 'points_label': 'Puan', 'rematch': 'RÖVANŞ',
        'new_game_setup': 'Yeni oyun (Kurulum)', 'rules': 'Kurallar', 'ok': 'ANLADIM',
        'rules_text': 'Yahtzee tarzı oyunlar için bir zar skor kartı (fiziksel zar gerekir).\n\n'
            '• Her oyuncu zar atar ve sonucunu uygun kategoriye girer.\n'
            '• Üst bölüm (Birler-Altılar): o zar değerinin toplamı.\n'
            '• Bonus: Üst bölüm toplamı en az 63 ise 35 puan.\n'
            '• Alt bölüm: Üçlü/Dörtlü (tüm zarların toplamı), Full House (25), Küçük Kent (30), Büyük Kent (40), Yahtzee (50), Şans (tüm zarların toplamı).\n'
            '• Uygun bir atış tutmazsa bir kategori 0 ile de çizilebilir.\n'
            '• Oyun, her oyuncu tüm kategorileri doldurduğunda sona erer - en yüksek toplam kazanır.',
        'cat_1': 'Birler', 'cat_2': 'İkiler', 'cat_3': 'Üçler', 'cat_4': 'Dörtler', 'cat_5': 'Beşler', 'cat_6': 'Altılar',
        'cat_upper_sum': 'ÜST TOPLAM', 'cat_bonus': 'BONUS',
        'cat_three_kind': 'Üçlü', 'cat_four_kind': 'Dörtlü', 'cat_full_house': 'Full House',
        'cat_small_straight': 'Küçük Kent', 'cat_large_straight': 'Büyük Kent',
        'cat_yahtzee': 'Yahtzee', 'cat_chance': 'Şans', 'cat_total': 'TOPLAM',
      },
      'id': {
        'title': 'Yazzee', 'new_game_tooltip': 'Permainan baru', 'add_hint': 'Nama pemain',
        'max_players_err': 'Maksimal 6 pemain!', 'min_players_err': 'Minimal 1 pemain diperlukan!',
        'start_btn': 'MULAI PERMAINAN', 'cancel': 'BATAL', 'save': 'SIMPAN',
        'strike': 'Coret (0)', 'standard_prefix': 'Standar', 'for_player': 'untuk',
        'winner_label': 'PEMENANG', 'points_label': 'Poin', 'rematch': 'TANDING ULANG',
        'new_game_setup': 'Permainan baru (Pengaturan)', 'rules': 'Aturan', 'ok': 'MENGERTI',
        'rules_text': 'Kartu skor dadu untuk permainan bergaya Yahtzee (dibutuhkan dadu fisik).\n\n'
            '• Setiap pemain melempar dadu dan memasukkan hasilnya ke kategori yang sesuai.\n'
            '• Bagian atas (Satu-Enam): jumlah dari nilai dadu tersebut.\n'
            '• Bonus: 35 poin jika total bagian atas minimal 63.\n'
            '• Bagian bawah: Three/Four of a Kind (jumlah semua dadu), Full House (25), Straight Kecil (30), Straight Besar (40), Yahtzee (50), Chance (jumlah semua dadu).\n'
            '• Kategori juga bisa dicoret dengan 0 jika tidak mendapat lemparan yang sesuai.\n'
            '• Permainan berakhir setelah setiap pemain mengisi semua kategori - total tertinggi menang.',
        'cat_1': 'Satu', 'cat_2': 'Dua', 'cat_3': 'Tiga', 'cat_4': 'Empat', 'cat_5': 'Lima', 'cat_6': 'Enam',
        'cat_upper_sum': 'JUMLAH ATAS', 'cat_bonus': 'BONUS',
        'cat_three_kind': 'Three of a Kind', 'cat_four_kind': 'Four of a Kind', 'cat_full_house': 'Full House',
        'cat_small_straight': 'Straight Kecil', 'cat_large_straight': 'Straight Besar',
        'cat_yahtzee': 'Yahtzee', 'cat_chance': 'Chance', 'cat_total': 'TOTAL',
      },
      'sv': {
        'title': 'Yazzee', 'new_game_tooltip': 'Nytt spel', 'add_hint': 'Spelarnamn',
        'max_players_err': 'Max 6 spelare!', 'min_players_err': 'Minst 1 spelare krävs!',
        'start_btn': 'STARTA SPEL', 'cancel': 'AVBRYT', 'save': 'SPARA',
        'strike': 'Stryk (0)', 'standard_prefix': 'Standard', 'for_player': 'för',
        'winner_label': 'VINNARE', 'points_label': 'Poäng', 'rematch': 'REVANSCH',
        'new_game_setup': 'Nytt spel (Inställningar)', 'rules': 'Regler', 'ok': 'FÖRSTÅTT',
        'rules_text': 'Ett tärningsprotokoll för Yahtzee-liknande spel (fysiska tärningar krävs).\n\n'
            '• Varje spelare kastar och för in sitt resultat i en passande kategori.\n'
            '• Övre delen (Ettor-Sexor): summan av det tärningsvärdet.\n'
            '• Bonus: 35 poäng om övre delen uppgår till minst 63.\n'
            '• Nedre delen: Tretal/Fyrtal (summan av alla tärningar), Full House (25), Liten stege (30), Stor stege (40), Yahtzee (50), Chans (summan av alla tärningar).\n'
            '• En kategori kan även strykas med 0 om inget passande kast uppnås.\n'
            '• Spelet slutar när alla spelare har fyllt i alla kategorier - högsta totalsumman vinner.',
        'cat_1': 'Ettor', 'cat_2': 'Tvåor', 'cat_3': 'Treor', 'cat_4': 'Fyror', 'cat_5': 'Femmor', 'cat_6': 'Sexor',
        'cat_upper_sum': 'ÖVRE SUMMA', 'cat_bonus': 'BONUS',
        'cat_three_kind': 'Tretal', 'cat_four_kind': 'Fyrtal', 'cat_full_house': 'Full House',
        'cat_small_straight': 'Liten stege', 'cat_large_straight': 'Stor stege',
        'cat_yahtzee': 'Yahtzee', 'cat_chance': 'Chans', 'cat_total': 'TOTALT',
      },
      'hr': {
        'title': 'Yazzee', 'new_game_tooltip': 'Nova igra', 'add_hint': 'Ime igrača',
        'max_players_err': 'Najviše 6 igrača!', 'min_players_err': 'Potreban je najmanje 1 igrač!',
        'start_btn': 'POKRENI IGRU', 'cancel': 'ODUSTANI', 'save': 'SPREMI',
        'strike': 'Precrtaj (0)', 'standard_prefix': 'Standard', 'for_player': 'za',
        'winner_label': 'POBJEDNIK', 'points_label': 'Bodovi', 'rematch': 'UZVRAT',
        'new_game_setup': 'Nova igra (Postavke)', 'rules': 'Pravila', 'ok': 'RAZUMIJEM',
        'rules_text': 'Blok za bodovanje kockicama za igre poput Yahtzeeja (potrebne fizičke kockice).\n\n'
            '• Svaki igrač baca kockice i upisuje rezultat u odgovarajuću kategoriju.\n'
            '• Gornji dio (Jedinice-Šestice): zbroj te vrijednosti kockice.\n'
            '• Bonus: 35 bodova ako gornji dio iznosi najmanje 63.\n'
            '• Donji dio: Tris/Poker (zbroj svih kockica), Full House (25), Mali strit (30), Veliki strit (40), Yahtzee (50), Šansa (zbroj svih kockica).\n'
            '• Kategorija se također može precrtati s 0 ako se ne postigne odgovarajući rezultat.\n'
            '• Igra završava kada svaki igrač ispuni sve kategorije - pobjeđuje najviši ukupni zbroj.',
        'cat_1': 'Jedinice', 'cat_2': 'Dvojke', 'cat_3': 'Trojke', 'cat_4': 'Četvorke', 'cat_5': 'Petice', 'cat_6': 'Šestice',
        'cat_upper_sum': 'GORNJI ZBROJ', 'cat_bonus': 'BONUS',
        'cat_three_kind': 'Tris', 'cat_four_kind': 'Poker', 'cat_full_house': 'Full House',
        'cat_small_straight': 'Mali strit', 'cat_large_straight': 'Veliki strit',
        'cat_yahtzee': 'Yahtzee', 'cat_chance': 'Šansa', 'cat_total': 'UKUPNO',
      },
      'ru': {
        'title': 'Yazzee', 'new_game_tooltip': 'Новая игра', 'add_hint': 'Имя игрока',
        'max_players_err': 'Максимум 6 игроков!', 'min_players_err': 'Нужен хотя бы 1 игрок!',
        'start_btn': 'НАЧАТЬ ИГРУ', 'cancel': 'ОТМЕНА', 'save': 'СОХРАНИТЬ',
        'strike': 'Зачеркнуть (0)', 'standard_prefix': 'Стандарт', 'for_player': 'для',
        'winner_label': 'ПОБЕДИТЕЛЬ', 'points_label': 'Очки', 'rematch': 'РЕВАНШ',
        'new_game_setup': 'Новая игра (Настройка)', 'rules': 'Правила', 'ok': 'ПОНЯТНО',
        'rules_text': 'Таблица очков для игр в стиле Yahtzee (нужны физические кости).\n\n'
            '• Каждый игрок бросает кости и записывает результат в подходящую категорию.\n'
            '• Верхняя секция (Единицы-Шестёрки): сумма значений этой кости.\n'
            '• Бонус: 35 очков, если сумма верхней секции не менее 63.\n'
            '• Нижняя секция: Тройка/Каре (сумма всех костей), Full House (25), Малый стрит (30), Большой стрит (40), Yahtzee (50), Шанс (сумма всех костей).\n'
            '• Категорию также можно зачеркнуть с 0, если не выпал подходящий бросок.\n'
            '• Игра заканчивается, когда каждый игрок заполнит все категории - побеждает наибольшая сумма.',
        'cat_1': 'Единицы', 'cat_2': 'Двойки', 'cat_3': 'Тройки', 'cat_4': 'Четвёрки', 'cat_5': 'Пятёрки', 'cat_6': 'Шестёрки',
        'cat_upper_sum': 'ВЕРХНЯЯ СУММА', 'cat_bonus': 'БОНУС',
        'cat_three_kind': 'Тройка', 'cat_four_kind': 'Каре', 'cat_full_house': 'Full House',
        'cat_small_straight': 'Малый стрит', 'cat_large_straight': 'Большой стрит',
        'cat_yahtzee': 'Yahtzee', 'cat_chance': 'Шанс', 'cat_total': 'ИТОГО',
      },
      'ja': {
        'title': 'Yazzee', 'new_game_tooltip': '新しいゲーム', 'add_hint': 'プレイヤー名',
        'max_players_err': '最大6人まで！', 'min_players_err': '少なくとも1人必要です！',
        'start_btn': 'ゲーム開始', 'cancel': 'キャンセル', 'save': '保存',
        'strike': '取り消し (0)', 'standard_prefix': '標準', 'for_player': 'の',
        'winner_label': '勝者', 'points_label': '点', 'rematch': '再戦',
        'new_game_setup': '新しいゲーム（設定）', 'rules': 'ルール', 'ok': '了解',
        'rules_text': 'ヤッツィー系ゲーム用のダイススコアシート（実物のサイコロが必要です）。\n\n'
            '• 各プレイヤーはサイコロを振り、対応するカテゴリーに結果を記入します。\n'
            '• 上段（1の目～6の目）：そのサイコロの値の合計。\n'
            '• ボーナス：上段の合計が63以上でボーナス35点。\n'
            '• 下段：スリーカード/フォーカード（全サイコロの合計）、フルハウス（25点）、スモールストレート（30点）、ラージストレート（40点）、ヤッツィー（50点）、チャンス（全サイコロの合計）。\n'
            '• 該当する出目がない場合は0点で消すこともできます。\n'
            '• 全プレイヤーが全カテゴリーを埋めるとゲーム終了 - 合計得点が最も高い人が勝ちです。',
        'cat_1': '1の目', 'cat_2': '2の目', 'cat_3': '3の目', 'cat_4': '4の目', 'cat_5': '5の目', 'cat_6': '6の目',
        'cat_upper_sum': '上段合計', 'cat_bonus': 'ボーナス',
        'cat_three_kind': 'スリーカード', 'cat_four_kind': 'フォーカード', 'cat_full_house': 'フルハウス',
        'cat_small_straight': 'スモールストレート', 'cat_large_straight': 'ラージストレート',
        'cat_yahtzee': 'ヤッツィー', 'cat_chance': 'チャンス', 'cat_total': '合計',
      },
      'ko': {
        'title': 'Yazzee', 'new_game_tooltip': '새 게임', 'add_hint': '플레이어 이름',
        'max_players_err': '최대 6명!', 'min_players_err': '최소 1명 필요!',
        'start_btn': '게임 시작', 'cancel': '취소', 'save': '저장',
        'strike': '지우기 (0)', 'standard_prefix': '기본', 'for_player': '님의',
        'winner_label': '승자', 'points_label': '점수', 'rematch': '재대결',
        'new_game_setup': '새 게임 (설정)', 'rules': '규칙', 'ok': '확인',
        'rules_text': '야찌 스타일 게임을 위한 주사위 점수표입니다 (실제 주사위 필요).\n\n'
            '• 각 플레이어는 주사위를 굴려 결과를 해당 카테고리에 입력합니다.\n'
            '• 상단 (1~6): 해당 눈금 값의 합계.\n'
            '• 보너스: 상단 합계가 63 이상이면 35점.\n'
            '• 하단: 트리플/포카드 (모든 주사위 합), 풀하우스 (25), 스몰 스트레이트 (30), 라지 스트레이트 (40), 야찌 (50), 찬스 (모든 주사위 합).\n'
            '• 해당하는 조합이 없으면 0점으로 지울 수도 있습니다.\n'
            '• 모든 플레이어가 모든 카테고리를 채우면 게임이 종료되며, 총점이 가장 높은 사람이 승리합니다.',
        'cat_1': '1 눈', 'cat_2': '2 눈', 'cat_3': '3 눈', 'cat_4': '4 눈', 'cat_5': '5 눈', 'cat_6': '6 눈',
        'cat_upper_sum': '상단 합계', 'cat_bonus': '보너스',
        'cat_three_kind': '트리플', 'cat_four_kind': '포카드', 'cat_full_house': '풀하우스',
        'cat_small_straight': '스몰 스트레이트', 'cat_large_straight': '라지 스트레이트',
        'cat_yahtzee': '야찌', 'cat_chance': '찬스', 'cat_total': '합계',
      },
      'zh': {
        'title': 'Yazzee', 'new_game_tooltip': '新游戏', 'add_hint': '玩家姓名',
        'max_players_err': '最多6名玩家！', 'min_players_err': '至少需要1名玩家！',
        'start_btn': '开始游戏', 'cancel': '取消', 'save': '保存',
        'strike': '划掉 (0)', 'standard_prefix': '标准', 'for_player': '的',
        'winner_label': '获胜者', 'points_label': '分', 'rematch': '再来一局',
        'new_game_setup': '新游戏（设置）', 'rules': '规则', 'ok': '明白了',
        'rules_text': '雅兹骰子风格游戏的记分表（需要实体骰子）。\n\n'
            '• 每位玩家掷骰子，并将结果填入相应的类别。\n'
            '• 上半区（一点至六点）：该点数骰子的总和。\n'
            '• 奖励分：如果上半区总和达到63分以上，可获得35分奖励。\n'
            '• 下半区：三条/四条（所有骰子总和）、葫芦（25分）、小顺（30分）、大顺（40分）、Yahtzee（50分）、机会（所有骰子总和）。\n'
            '• 如果没有掷出合适的组合，也可以将某个类别划掉记为0分。\n'
            '• 当所有玩家填满所有类别时游戏结束——总分最高者获胜。',
        'cat_1': '一点', 'cat_2': '二点', 'cat_3': '三点', 'cat_4': '四点', 'cat_5': '五点', 'cat_6': '六点',
        'cat_upper_sum': '上半区总和', 'cat_bonus': '奖励分',
        'cat_three_kind': '三条', 'cat_four_kind': '四条', 'cat_full_house': '葫芦',
        'cat_small_straight': '小顺', 'cat_large_straight': '大顺',
        'cat_yahtzee': 'Yahtzee', 'cat_chance': '机会', 'cat_total': '总分',
      },
      'hi': {
        'title': 'Yazzee', 'new_game_tooltip': 'नया गेम', 'add_hint': 'खिलाड़ी का नाम',
        'max_players_err': 'अधिकतम 6 खिलाड़ी!', 'min_players_err': 'कम से कम 1 खिलाड़ी चाहिए!',
        'start_btn': 'गेम शुरू करें', 'cancel': 'रद्द करें', 'save': 'सहेजें',
        'strike': 'काटें (0)', 'standard_prefix': 'मानक', 'for_player': 'के लिए',
        'winner_label': 'विजेता', 'points_label': 'अंक', 'rematch': 'रीमैच',
        'new_game_setup': 'नया गेम (सेटअप)', 'rules': 'नियम', 'ok': 'समझ गया',
        'rules_text': 'यहत्ज़ी-शैली के खेलों के लिए एक डाइस स्कोर पैड (असली पासे चाहिए)।\n\n'
            '• हर खिलाड़ी पासे फेंकता है और अपना परिणाम उपयुक्त श्रेणी में दर्ज करता है।\n'
            '• ऊपरी भाग (एक-छह): उस पासे के मूल्य का योग।\n'
            '• बोनस: यदि ऊपरी भाग का योग कम से कम 63 हो तो 35 अंक।\n'
            '• निचला भाग: थ्री/फोर ऑफ अ काइंड (सभी पासों का योग), फुल हाउस (25), छोटी स्ट्रेट (30), बड़ी स्ट्रेट (40), यहत्ज़ी (50), चांस (सभी पासों का योग)।\n'
            '• यदि उपयुक्त पासा न आए तो श्रेणी को 0 से भी काटा जा सकता है।\n'
            '• जब हर खिलाड़ी सभी श्रेणियां भर देता है तो खेल समाप्त होता है - सबसे अधिक कुल अंक वाला जीतता है।',
        'cat_1': 'एक', 'cat_2': 'दो', 'cat_3': 'तीन', 'cat_4': 'चार', 'cat_5': 'पांच', 'cat_6': 'छह',
        'cat_upper_sum': 'ऊपरी योग', 'cat_bonus': 'बोनस',
        'cat_three_kind': 'थ्री ऑफ अ काइंड', 'cat_four_kind': 'फोर ऑफ अ काइंड', 'cat_full_house': 'फुल हाउस',
        'cat_small_straight': 'छोटी स्ट्रेट', 'cat_large_straight': 'बड़ी स्ट्रेट',
        'cat_yahtzee': 'यहत्ज़ी', 'cat_chance': 'चांस', 'cat_total': 'कुल',
      },
      'bn': {
        'title': 'Yazzee', 'new_game_tooltip': 'নতুন গেম', 'add_hint': 'খেলোয়াড়ের নাম',
        'max_players_err': 'সর্বোচ্চ ৬ জন খেলোয়াড়!', 'min_players_err': 'কমপক্ষে ১ জন খেলোয়াড় প্রয়োজন!',
        'start_btn': 'গেম শুরু করুন', 'cancel': 'বাতিল', 'save': 'সংরক্ষণ',
        'strike': 'কেটে দিন (0)', 'standard_prefix': 'স্ট্যান্ডার্ড', 'for_player': 'এর জন্য',
        'winner_label': 'বিজয়ী', 'points_label': 'পয়েন্ট', 'rematch': 'রিম্যাচ',
        'new_game_setup': 'নতুন গেম (সেটআপ)', 'rules': 'নিয়ম', 'ok': 'বুঝেছি',
        'rules_text': 'ইয়াহতজি-স্টাইল গেমের জন্য একটি ডাইস স্কোর প্যাড (আসল ডাইস প্রয়োজন)।\n\n'
            '• প্রতিটি খেলোয়াড় ডাইস ঘোরায় এবং তার ফলাফল উপযুক্ত বিভাগে লেখে।\n'
            '• উপরের অংশ (এক-ছয়): সেই ডাইসের মানের যোগফল।\n'
            '• বোনাস: উপরের অংশের যোগফল কমপক্ষে ৬৩ হলে ৩৫ পয়েন্ট।\n'
            '• নিচের অংশ: থ্রি/ফোর অফ আ কাইন্ড (সব ডাইসের যোগফল), ফুল হাউস (২৫), ছোট স্ট্রেট (৩০), বড় স্ট্রেট (৪০), ইয়াহতজি (৫০), চান্স (সব ডাইসের যোগফল)।\n'
            '• উপযুক্ত ফলাফল না পেলে একটি বিভাগ ০ দিয়েও কেটে দেওয়া যায়।\n'
            '• যখন প্রতিটি খেলোয়াড় সব বিভাগ পূরণ করে তখন গেম শেষ হয় - সর্বোচ্চ মোট পয়েন্টধারী জয়ী হয়।',
        'cat_1': 'এক', 'cat_2': 'দুই', 'cat_3': 'তিন', 'cat_4': 'চার', 'cat_5': 'পাঁচ', 'cat_6': 'ছয়',
        'cat_upper_sum': 'উপরের যোগফল', 'cat_bonus': 'বোনাস',
        'cat_three_kind': 'থ্রি অফ আ কাইন্ড', 'cat_four_kind': 'ফোর অফ আ কাইন্ড', 'cat_full_house': 'ফুল হাউস',
        'cat_small_straight': 'ছোট স্ট্রেট', 'cat_large_straight': 'বড় স্ট্রেট',
        'cat_yahtzee': 'ইয়াহতজি', 'cat_chance': 'চান্স', 'cat_total': 'মোট',
      },
      'ar': {
        'title': 'Yazzee', 'new_game_tooltip': 'لعبة جديدة', 'add_hint': 'اسم اللاعب',
        'max_players_err': '6 لاعبين كحد أقصى!', 'min_players_err': 'يلزم لاعب واحد على الأقل!',
        'start_btn': 'بدء اللعبة', 'cancel': 'إلغاء', 'save': 'حفظ',
        'strike': 'شطب (0)', 'standard_prefix': 'قياسي', 'for_player': 'لـ',
        'winner_label': 'الفائز', 'points_label': 'نقاط', 'rematch': 'إعادة المباراة',
        'new_game_setup': 'لعبة جديدة (إعداد)', 'rules': 'القواعد', 'ok': 'فهمت',
        'rules_text': 'لوحة تسجيل نقاط للألعاب على طراز ياهتزي (يلزم نرد حقيقي).\n\n'
            '• يرمي كل لاعب النرد ويسجل نتيجته في الفئة المناسبة.\n'
            '• القسم العلوي (واحد-ستة): مجموع قيمة ذلك النرد.\n'
            '• مكافأة: 35 نقطة إذا بلغ مجموع القسم العلوي 63 نقطة على الأقل.\n'
            '• القسم السفلي: ثلاثة/أربعة متشابهة (مجموع كل النرد)، فول هاوس (25)، تتابع صغير (30)، تتابع كبير (40)، ياهتزي (50)، فرصة (مجموع كل النرد).\n'
            '• يمكن أيضاً شطب فئة بـ 0 إذا لم يتم الحصول على رمية مناسبة.\n'
            '• تنتهي اللعبة عندما يملأ كل لاعب جميع الفئات - يفوز صاحب أعلى مجموع.',
        'cat_1': 'واحد', 'cat_2': 'اثنان', 'cat_3': 'ثلاثة', 'cat_4': 'أربعة', 'cat_5': 'خمسة', 'cat_6': 'ستة',
        'cat_upper_sum': 'مجموع علوي', 'cat_bonus': 'مكافأة',
        'cat_three_kind': 'ثلاثة متشابهة', 'cat_four_kind': 'أربعة متشابهة', 'cat_full_house': 'فول هاوس',
        'cat_small_straight': 'تتابع صغير', 'cat_large_straight': 'تتابع كبير',
        'cat_yahtzee': 'ياهتزي', 'cat_chance': 'فرصة', 'cat_total': 'المجموع',
      },
    };

    if (dictionary.containsKey(_currentLang) && dictionary[_currentLang]!.containsKey(key)) {
      return dictionary[_currentLang]![key]!;
    }
    return dictionary['en']![key] ?? key;
  }

  // Übersetztes Anzeige-Label für eine interne Kategorie
  String _catLabel(String category) => _t(_categoryTranslationKeys[category] ?? category);

  // --- SETUP ---

  void _addPlayer() {
    if (_nameController.text.trim().isNotEmpty) {
      if (_players.length >= 6) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('max_players_err'))));
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
    if (_players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('min_players_err'))));
      return;
    }
    setState(() {
      _gameStarted = true;
      _gameFinished = false;
      _currentPlayerIndex = 0;
    });
  }

  void _resetGame() {
    setState(() {
      _gameStarted = false;
      _gameFinished = false;
      _currentPlayerIndex = 0;
      _players.clear();
    });
  }

  void _rematch() {
    setState(() {
      for (var p in _players) {
        p.scores.clear();
      }
      _gameFinished = false;
      _currentPlayerIndex = 0;
    });
  }

  // Rückt den Zug zum nächsten Spieler weiter, der noch nicht fertig ist.
  void _advanceTurn() {
    if (_players.every((p) => p.isComplete)) {
      _gameFinished = true;
      return;
    }
    int next = _currentPlayerIndex;
    do {
      next = (next + 1) % _players.length;
    } while (_players[next].isComplete);
    _currentPlayerIndex = next;
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
        title: Text("${_catLabel(category)} ${_t('for_player')} ${player.name}", style: TextStyle(color: primaryColor)),
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
                _quickBtn(_t('strike'), "0", scoreCtrl, color: errorColor),
                if (suggestion != null)
                  _quickBtn("${_t('standard_prefix')} ($suggestion)", "$suggestion", scoreCtrl, color: secondaryColor),
              ],
            )
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t('cancel'), style: const TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black),
            onPressed: () {
              setState(() {
                int? val = int.tryParse(scoreCtrl.text);
                if (val != null) {
                  player.scores[category] = val;
                }
                int playerIndex = _players.indexOf(player);
                if (playerIndex == _currentPlayerIndex) {
                  _advanceTurn();
                }
              });
              Navigator.pop(context);
            },
            child: Text(_t('save')),
          )
        ],
      ),
    );
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
          title: Text(_t('title')),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: primaryColor,
          actions: [
            if (_gameStarted)
              IconButton(icon: const Icon(Icons.refresh), onPressed: _resetGame, tooltip: _t('new_game_tooltip')),
            IconButton(icon: const Icon(Icons.help_outline), onPressed: _showRules, tooltip: _t('rules')),
          ],
        ),
        body: SafeArea(
          child: _gameFinished
              ? _buildGameOver()
              : (_gameStarted ? _buildScoreTable() : _buildSetup()),
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
              child: Text(_t('start_btn'), style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
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
                                child: Text(_catLabel(cat),
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
                                children: _players.asMap().entries.map((entry) {
                                  final p = entry.value;
                                  final bool isTurn = entry.key == _currentPlayerIndex && !p.isComplete;
                                  return Container(
                                  width: cardWidth,
                                  height: headerHeight,
                                  padding: const EdgeInsets.all(4),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isTurn ? primaryColor.withOpacity(0.15) : surfaceColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isTurn ? primaryColor : Colors.white10, width: isTurn ? 2 : 1),
                                    ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (isTurn)
                                          Icon(Icons.play_arrow, color: primaryColor, size: 14),
                                        Text(
                                          p.name,
                                          style: TextStyle(color: isTurn ? primaryColor : Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
                                  );
                                }).toList(),
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

  // 3. GAME OVER SCREEN
  Widget _buildGameOver() {
    List<YazzeePlayer> sorted = List.from(_players);
    sorted.sort((a, b) => b.grandTotal.compareTo(a.grandTotal)); // Höchster Score gewinnt

    int bestScore = sorted.first.grandTotal;
    List<YazzeePlayer> winners = sorted.where((p) => p.grandTotal == bestScore).toList();
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
              Text(_t('winner_label'), style: TextStyle(color: Colors.white.withOpacity(0.6), letterSpacing: 2)),
              const SizedBox(height: 5),
              Text(
                  winnerNames,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 5),
              Text("$bestScore ${_t('points_label')}", style: TextStyle(color: primaryColor, fontSize: 20)),
              const SizedBox(height: 30),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final player = sorted[index];
                  int displayRank = sorted.indexWhere((p) => p.grandTotal == player.grandTotal) + 1;

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
                  onPressed: _rematch,
                  style: ElevatedButton.styleFrom(backgroundColor: successColor),
                  child: Text(_t('rematch'), style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                  onPressed: _resetGame,
                  child: Text(_t('new_game_setup'), style: const TextStyle(color: Colors.grey))
              )
            ],
          ),
        ),
      ),
    );
  }
}
