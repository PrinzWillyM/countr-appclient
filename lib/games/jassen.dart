import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';

// --- ENUMS ---
enum JassMode { schieber, differenzler }

class JassenGame extends StatefulWidget {
  final Color? themeColor;

  const JassenGame({super.key, this.themeColor});

  @override
  State<JassenGame> createState() => _JassenGameState();
}

class _JassenGameState extends State<JassenGame> {
  // --- STYLE ---
  Color get primaryColor => widget.themeColor ?? const Color(0xFFEBCB63); // Brand Yellow
  final Color bgColor = const Color(0xFF222629);
  final Color surfaceColor = const Color(0xFF30363B);
  final Color activeColor = const Color(0xFF3E444A);

  // --- STATE ---
  // Sprache: immer live vom globalen App-Status gelesen (reaktiv auf Sprachwechsel)
  String get _currentLang => appLocaleNotifier.value.languageCode;
  JassMode? _selectedMode;

  // Schieber State
  int team1Score = 0;
  int team2Score = 0;
  String team1Name = "Team 1"; // Wird in initState übersetzt
  String team2Name = "Team 2"; // Wird in initState übersetzt
  List<Map<String, dynamic>> history = [];
  String _currentInput = "";
  bool _isWeisMode = false; // Wenn true: Punkte werden direkt addiert (kein Split)
  int _multiplier = 1; // Trumpf-Multiplikator (x1-x4)
  int? _matchTarget; // Ziel-Punktzahl (null = unbegrenzt)
  bool _schieberFinished = false;

  // Differenzler State
  bool _diffGameStarted = false;
  bool _diffGameFinished = false;
  List<Map<String, dynamic>> diffPlayers = [];
  int _diffCurrentRound = 1;
  int? _diffRoundLimit; // Rundenlimit (null = unbegrenzt)
  Map<String, Map<String, int>> _diffRoundBuffer = {};
  List<Map<String, dynamic>> diffRoundLog = [];
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Standardnamen für Teams basierend auf der aktuellen Sprache
    team1Name = _t('team1');
    team2Name = _t('team2');
  }

  // --- TRANSLATIONS ---
  String _t(String key) {
    const Map<String, Map<String, String>> dictionary = {
      'de': {
        'title': 'Jass Tafel', 'rules': 'Anleitung', 'ok': 'VERSTANDEN',
        'mode_schieber': 'Schieber', 'desc_schieber': 'Team gegen Team. 157 Punkte + Weisen.',
        'mode_diff': 'Differenzler', 'desc_diff': 'Sage deine Punkte an. Die Differenz ist die Strafe.',
        'team1': 'Wir', 'team2': 'Gegner', 'undo': 'Rückgängig', 'reset': 'Neues Spiel',
        'input_score': 'Punkte...', 'round': 'Runde',
        'add_player': 'Spieler hinzufügen', 'start': 'SPIEL STARTEN', 'prediction': 'Ansage',
        'score': 'Erreicht', 'penalty': 'Strafe', 'weis_mode': 'Weis / Bonus',
        'weis_on': 'Weis Modus: AN', 'weis_off': 'Stich Modus',
        'rules_text': 'Wähle deinen Modus:\n\n• Schieber: Gib die Punkte eines Teams ein. Der Rest von 157 geht automatisch an das andere Team. Wähle vor der Eingabe optional einen Multiplikator (×1-×4) für den Trumpf. Für Weisen (Bonus): Aktiviere den Stern-Button, dann werden Punkte direkt und unmultipliziert addiert. Der Stöck-Button fügt einem Team direkt 20 Punkte hinzu. Optional lässt sich eine Ziel-Punktzahl setzen (Antippen der Ziel-Anzeige) - wird sie erreicht, endet das Spiel. Der Verlauf-Button zeigt alle bisherigen Einträge.\n\n• Differenzler: Füge Spieler hinzu und optional ein Rundenlimit. In jeder Runde sagt jeder Spieler seine Punkte an und trägt danach das Resultat ein - die Differenz gibt Strafpunkte. Die aktuelle Rundennummer wird oben angezeigt, der Verlauf ist über die Runden-Leiste erreichbar. Bei Rundenlimit endet das Spiel automatisch, wer die wenigsten Strafpunkte hat gewinnt.',
        'add_hint': 'Name', 'rename_title': 'Name ändern', 'cancel': 'ABBRECHEN', 'save': 'SPEICHERN',
        'multiplier': 'Multiplikator', 'stoeck': 'Stöck', 'target': 'Ziel', 'no_target': 'Kein Ziel',
        'history': 'Verlauf', 'no_history': 'Noch keine Einträge', 'match_won': 'GEWINNT DAS SPIEL!',
        'round_limit': 'Rundenlimit', 'no_limit': 'Unbegrenzt', 'rounds_short': 'Runden',
        'game_over': 'Spiel beendet', 'winner': 'Sieger', 'new_game_btn': 'Neues Spiel',
        'type_trick': 'Stich', 'type_weis': 'Weis', 'type_stoeck': 'Stöck',
      },
      'en': {
        'title': 'Jass Scoreboard', 'rules': 'Rules', 'ok': 'GOT IT',
        'mode_schieber': 'Schieber', 'desc_schieber': 'Team vs Team. 157 Points + Bonus.',
        'mode_diff': 'Differenzler', 'desc_diff': 'Predict score. Difference is penalty.',
        'team1': 'Us', 'team2': 'Them', 'undo': 'Undo', 'reset': 'Reset',
        'input_score': 'Points...', 'round': 'Round',
        'add_player': 'Add Player', 'start': 'START GAME', 'prediction': 'Bid',
        'score': 'Score', 'penalty': 'Penalty', 'weis_mode': 'Bonus / Weis',
        'weis_on': 'Bonus Mode: ON', 'weis_off': 'Trick Mode',
        'rules_text': 'Choose your mode:\n\n• Schieber: Enter points for one team, the remainder of 157 automatically goes to the other. Optionally pick a multiplier (×1-×4) for the trump before entering points. For Bonus (Weis): toggle the Star button - points are then added directly and unmultiplied. The Stöck button adds 20 points to a team directly. You can optionally set a target score (tap the target display) - once reached, the match ends. The History button shows every past entry.\n\n• Differenzler: Add players and optionally a round limit. Each round every player predicts their score, then enters the result - the difference becomes penalty points. The current round number is shown at the top; the round history is reachable via that bar. With a round limit, the game ends automatically and whoever has the fewest penalty points wins.',
        'add_hint': 'Name', 'rename_title': 'Rename', 'cancel': 'CANCEL', 'save': 'SAVE',
        'multiplier': 'Multiplier', 'stoeck': 'Stöck', 'target': 'Target', 'no_target': 'No Target',
        'history': 'History', 'no_history': 'No entries yet', 'match_won': 'WINS THE MATCH!',
        'round_limit': 'Round Limit', 'no_limit': 'Unlimited', 'rounds_short': 'Rounds',
        'game_over': 'Game Over', 'winner': 'Winner', 'new_game_btn': 'New Game',
        'type_trick': 'Trick', 'type_weis': 'Weis', 'type_stoeck': 'Stöck',
      },
      'fr': {
        'title': 'Jass (Chibre)', 'rules': 'Règles', 'ok': 'COMPRIS',
        'mode_schieber': 'Chibre', 'desc_schieber': 'Équipe vs Équipe. 157 points + Annonces.',
        'mode_diff': 'Differenzler', 'desc_diff': 'Prédisez vos points. La différence compte.',
        'team1': 'Nous', 'team2': 'Eux', 'undo': 'Annuler', 'reset': 'Réinitialiser',
        'input_score': 'Points...', 'round': 'Tour',
        'add_player': 'Ajouter joueur', 'start': 'DÉMARRER', 'prediction': 'Annonce',
        'score': 'Score', 'penalty': 'Pénalité', 'weis_mode': 'Annonce / Bonus',
        'weis_on': 'Mode Annonce : ON', 'weis_off': 'Mode Pli',
        'rules_text': 'Choisissez votre mode :\n\n• Chibre : Entrez les points d\'une équipe, le reste (sur 157) va automatiquement à l\'autre. Choisissez éventuellement un multiplicateur (×1-×4) pour l\'atout avant de saisir les points. Pour les Annonces (Weis) : activez le bouton étoile - les points sont alors ajoutés directement et sans multiplicateur. Le bouton Stöck ajoute directement 20 points à une équipe. Vous pouvez définir un score cible (touchez l\'affichage de la cible) - une fois atteint, la partie se termine. Le bouton Historique affiche toutes les entrées passées.\n\n• Differenzler : Ajoutez des joueurs et éventuellement une limite de tours. Chaque tour, chaque joueur prédit son score puis saisit le résultat - la différence devient des points de pénalité. Le numéro du tour actuel est affiché en haut ; l\'historique des tours est accessible via cette barre. Avec une limite de tours, la partie se termine automatiquement et celui qui a le moins de points de pénalité gagne.',
        'add_hint': 'Nom', 'rename_title': 'Renommer', 'cancel': 'ANNULER', 'save': 'ENREGISTRER',
        'multiplier': 'Multiplicateur', 'stoeck': 'Stöck', 'target': 'Objectif', 'no_target': 'Aucun objectif',
        'history': 'Historique', 'no_history': 'Aucune entrée', 'match_won': 'GAGNE LA PARTIE !',
        'round_limit': 'Limite de tours', 'no_limit': 'Illimité', 'rounds_short': 'Tours',
        'game_over': 'Partie terminée', 'winner': 'Vainqueur', 'new_game_btn': 'Nouvelle partie',
        'type_trick': 'Pli', 'type_weis': 'Annonce', 'type_stoeck': 'Stöck',
      },
      'it': {
        'title': 'Jass', 'rules': 'Regole', 'ok': 'CAPITO',
        'mode_schieber': 'Schieber', 'desc_schieber': 'Squadra vs Squadra. 157 punti + Dichiarazioni.',
        'mode_diff': 'Differenzler', 'desc_diff': 'Predici il punteggio. La differenza è la penalità.',
        'team1': 'Noi', 'team2': 'Loro', 'undo': 'Annulla', 'reset': 'Nuova Partita',
        'input_score': 'Punti...', 'round': 'Turno',
        'add_player': 'Aggiungi', 'start': 'AVVIA', 'prediction': 'Dichiarazione',
        'score': 'Punteggio', 'penalty': 'Penalità', 'weis_mode': 'Bonus',
        'weis_on': 'Modalità Bonus: ON', 'weis_off': 'Modalità Presa',
        'rules_text': 'Scegli la modalità:\n\n• Schieber: inserisci i punti di una squadra, il resto (su 157) va automaticamente all\'altra. Scegli facoltativamente un moltiplicatore (×1-×4) per la briscola prima di inserire i punti. Per i Bonus (Weis): attiva il pulsante stella - i punti vengono allora aggiunti direttamente senza moltiplicatore. Il pulsante Stöck aggiunge direttamente 20 punti a una squadra. Puoi impostare facoltativamente un punteggio obiettivo (tocca il display dell\'obiettivo) - una volta raggiunto, la partita termina. Il pulsante Cronologia mostra tutte le voci passate.\n\n• Differenzler: aggiungi giocatori e facoltativamente un limite di turni. Ad ogni turno ogni giocatore dichiara il proprio punteggio, poi inserisce il risultato - la differenza diventa punti di penalità. Il numero del turno attuale è mostrato in alto; la cronologia dei turni è raggiungibile tramite quella barra. Con un limite di turni, la partita termina automaticamente e vince chi ha meno punti di penalità.',
        'add_hint': 'Nome', 'rename_title': 'Rinomina', 'cancel': 'ANNULLA', 'save': 'SALVA',
        'multiplier': 'Moltiplicatore', 'stoeck': 'Stöck', 'target': 'Obiettivo', 'no_target': 'Nessun obiettivo',
        'history': 'Cronologia', 'no_history': 'Ancora nessuna voce', 'match_won': 'VINCE LA PARTITA!',
        'round_limit': 'Limite turni', 'no_limit': 'Illimitato', 'rounds_short': 'Turni',
        'game_over': 'Partita terminata', 'winner': 'Vincitore', 'new_game_btn': 'Nuova Partita',
        'type_trick': 'Presa', 'type_weis': 'Weis', 'type_stoeck': 'Stöck',
      },
      'es': {
        'title': 'Jass', 'rules': 'Reglas', 'ok': 'ENTENDIDO',
        'mode_schieber': 'Schieber', 'desc_schieber': 'Equipo vs Equipo. 157 puntos + Anuncios.',
        'mode_diff': 'Differenzler', 'desc_diff': 'Predice tu puntaje. La diferencia es la penalización.',
        'team1': 'Nosotros', 'team2': 'Ellos', 'undo': 'Deshacer', 'reset': 'Nueva Partida',
        'input_score': 'Puntos...', 'round': 'Ronda',
        'add_player': 'Añadir', 'start': 'INICIAR', 'prediction': 'Anuncio',
        'score': 'Puntaje', 'penalty': 'Penalización', 'weis_mode': 'Bono',
        'weis_on': 'Modo Bono: ON', 'weis_off': 'Modo Baza',
        'rules_text': 'Elige tu modo:\n\n• Schieber: introduce los puntos de un equipo, el resto (sobre 157) va automáticamente al otro. Elige opcionalmente un multiplicador (×1-×4) para el triunfo antes de introducir los puntos. Para los Bonos (Weis): activa el botón estrella - los puntos se suman entonces directamente y sin multiplicar. El botón Stöck añade 20 puntos directamente a un equipo. Puedes establecer opcionalmente un puntaje objetivo (toca el indicador de objetivo) - al alcanzarlo, la partida termina. El botón Historial muestra todas las entradas anteriores.\n\n• Differenzler: añade jugadores y opcionalmente un límite de rondas. En cada ronda cada jugador anuncia su puntaje, luego introduce el resultado - la diferencia se convierte en puntos de penalización. El número de ronda actual se muestra arriba; el historial de rondas es accesible mediante esa barra. Con un límite de rondas, la partida termina automáticamente y gana quien tenga menos puntos de penalización.',
        'add_hint': 'Nombre', 'rename_title': 'Renombrar', 'cancel': 'CANCELAR', 'save': 'GUARDAR',
        'multiplier': 'Multiplicador', 'stoeck': 'Stöck', 'target': 'Objetivo', 'no_target': 'Sin objetivo',
        'history': 'Historial', 'no_history': 'Aún sin entradas', 'match_won': '¡GANA LA PARTIDA!',
        'round_limit': 'Límite de rondas', 'no_limit': 'Ilimitado', 'rounds_short': 'Rondas',
        'game_over': 'Partida terminada', 'winner': 'Ganador', 'new_game_btn': 'Nueva Partida',
        'type_trick': 'Baza', 'type_weis': 'Weis', 'type_stoeck': 'Stöck',
      },
      'pt': {
        'title': 'Jass', 'rules': 'Regras', 'ok': 'ENTENDIDO',
        'mode_schieber': 'Schieber', 'desc_schieber': 'Equipe vs Equipe. 157 pontos + Anúncios.',
        'mode_diff': 'Differenzler', 'desc_diff': 'Preveja sua pontuação. A diferença é a penalidade.',
        'team1': 'Nós', 'team2': 'Eles', 'undo': 'Desfazer', 'reset': 'Novo Jogo',
        'input_score': 'Pontos...', 'round': 'Rodada',
        'add_player': 'Adicionar', 'start': 'INICIAR', 'prediction': 'Anúncio',
        'score': 'Pontuação', 'penalty': 'Penalidade', 'weis_mode': 'Bônus',
        'weis_on': 'Modo Bônus: ON', 'weis_off': 'Modo Vaza',
        'rules_text': 'Escolha o seu modo:\n\n• Schieber: insira os pontos de uma equipe, o restante (de 157) vai automaticamente para a outra. Escolha opcionalmente um multiplicador (×1-×4) para o trunfo antes de inserir os pontos. Para Bônus (Weis): ative o botão estrela - os pontos são então somados diretamente e sem multiplicador. O botão Stöck adiciona 20 pontos diretamente a uma equipe. Você pode definir opcionalmente uma pontuação alvo (toque no indicador de alvo) - ao atingi-la, a partida termina. O botão Histórico mostra todas as entradas anteriores.\n\n• Differenzler: adicione jogadores e opcionalmente um limite de rodadas. A cada rodada, cada jogador anuncia sua pontuação e depois insere o resultado - a diferença vira pontos de penalidade. O número da rodada atual é exibido no topo; o histórico de rodadas é acessível por essa barra. Com um limite de rodadas, o jogo termina automaticamente e quem tiver menos pontos de penalidade vence.',
        'add_hint': 'Nome', 'rename_title': 'Renomear', 'cancel': 'CANCELAR', 'save': 'SALVAR',
        'multiplier': 'Multiplicador', 'stoeck': 'Stöck', 'target': 'Meta', 'no_target': 'Sem meta',
        'history': 'Histórico', 'no_history': 'Ainda sem registros', 'match_won': 'VENCE A PARTIDA!',
        'round_limit': 'Limite de rodadas', 'no_limit': 'Ilimitado', 'rounds_short': 'Rodadas',
        'game_over': 'Jogo terminado', 'winner': 'Vencedor', 'new_game_btn': 'Novo Jogo',
        'type_trick': 'Vaza', 'type_weis': 'Weis', 'type_stoeck': 'Stöck',
      },
      'nl': {
        'title': 'Jassen', 'rules': 'Instructies', 'ok': 'BEGREPEN',
        'mode_schieber': 'Schieber', 'desc_schieber': 'Team vs Team. 157 punten + Aankondigingen.',
        'mode_diff': 'Differenzler', 'desc_diff': 'Voorspel je score. Het verschil is de straf.',
        'team1': 'Wij', 'team2': 'Zij', 'undo': 'Ongedaan maken', 'reset': 'Nieuw spel',
        'input_score': 'Punten...', 'round': 'Ronde',
        'add_player': 'Toevoegen', 'start': 'STARTEN', 'prediction': 'Aankondiging',
        'score': 'Score', 'penalty': 'Straf', 'weis_mode': 'Bonus',
        'weis_on': 'Bonusmodus: AAN', 'weis_off': 'Slagmodus',
        'rules_text': 'Kies je modus:\n\n• Schieber: voer de punten van een team in, de rest (van 157) gaat automatisch naar het andere team. Kies eventueel een vermenigvuldiger (×1-×4) voor de troef voordat je punten invoert. Voor Bonus (Weis): schakel de ster-knop in - punten worden dan direct en zonder vermenigvuldiging opgeteld. De Stöck-knop voegt direct 20 punten toe aan een team. Je kunt optioneel een streefscore instellen (tik op de doelweergave) - zodra die bereikt is, eindigt de wedstrijd. De Geschiedenis-knop toont alle eerdere invoeren.\n\n• Differenzler: voeg spelers toe en optioneel een rondelimiet. Elke ronde voorspelt iedere speler zijn score en voert daarna het resultaat in - het verschil wordt strafpunten. Het huidige rondenummer wordt bovenaan getoond; de rondegeschiedenis is bereikbaar via die balk. Met een rondelimiet eindigt het spel automatisch en wint wie de minste strafpunten heeft.',
        'add_hint': 'Naam', 'rename_title': 'Wijzigen', 'cancel': 'ANNULEREN', 'save': 'OPSLAAN',
        'multiplier': 'Vermenigvuldiger', 'stoeck': 'Stöck', 'target': 'Doel', 'no_target': 'Geen doel',
        'history': 'Geschiedenis', 'no_history': 'Nog geen invoeren', 'match_won': 'WINT DE WEDSTRIJD!',
        'round_limit': 'Rondelimiet', 'no_limit': 'Onbeperkt', 'rounds_short': 'Rondes',
        'game_over': 'Spel afgelopen', 'winner': 'Winnaar', 'new_game_btn': 'Nieuw spel',
        'type_trick': 'Slag', 'type_weis': 'Weis', 'type_stoeck': 'Stöck',
      },
      'pl': {
        'title': 'Jass', 'rules': 'Zasady', 'ok': 'ZROZUMIAŁEM',
        'mode_schieber': 'Schieber', 'desc_schieber': 'Drużyna vs Drużyna. 157 punktów + Zapowiedzi.',
        'mode_diff': 'Differenzler', 'desc_diff': 'Przewiduj wynik. Różnica to kara.',
        'team1': 'My', 'team2': 'Oni', 'undo': 'Cofnij', 'reset': 'Nowa Gra',
        'input_score': 'Punkty...', 'round': 'Runda',
        'add_player': 'Dodaj', 'start': 'START', 'prediction': 'Zapowiedź',
        'score': 'Wynik', 'penalty': 'Kara', 'weis_mode': 'Bonus',
        'weis_on': 'Tryb Bonus: WŁ', 'weis_off': 'Tryb Lew',
        'rules_text': 'Wybierz tryb:\n\n• Schieber: wpisz punkty jednej drużyny, reszta (do 157) automatycznie trafia do drugiej. Możesz opcjonalnie wybrać mnożnik (×1-×4) dla atutu przed wpisaniem punktów. Dla Bonusu (Weis): włącz przycisk gwiazdki - punkty są wtedy dodawane bezpośrednio, bez mnożnika. Przycisk Stöck dodaje bezpośrednio 20 punktów drużynie. Możesz opcjonalnie ustawić docelowy wynik (dotknij wskaźnika celu) - po jego osiągnięciu mecz się kończy. Przycisk Historia pokazuje wszystkie dotychczasowe wpisy.\n\n• Differenzler: dodaj graczy i opcjonalnie limit rund. W każdej rundzie każdy gracz zapowiada swój wynik, a następnie wpisuje rezultat - różnica staje się punktami karnymi. Numer aktualnej rundy jest wyświetlany u góry; historia rund jest dostępna przez ten pasek. Przy limicie rund gra kończy się automatycznie, a wygrywa gracz z najmniejszą liczbą punktów karnych.',
        'add_hint': 'Imię', 'rename_title': 'Zmień nazwę', 'cancel': 'ANULUJ', 'save': 'ZAPISZ',
        'multiplier': 'Mnożnik', 'stoeck': 'Stöck', 'target': 'Cel', 'no_target': 'Brak celu',
        'history': 'Historia', 'no_history': 'Brak wpisów', 'match_won': 'WYGRYWA MECZ!',
        'round_limit': 'Limit rund', 'no_limit': 'Bez limitu', 'rounds_short': 'Rundy',
        'game_over': 'Gra zakończona', 'winner': 'Zwycięzca', 'new_game_btn': 'Nowa Gra',
        'type_trick': 'Lew', 'type_weis': 'Weis', 'type_stoeck': 'Stöck',
      },
      'tr': {
        'title': 'Jass', 'rules': 'Kurallar', 'ok': 'ANLADIM',
        'mode_schieber': 'Schieber', 'desc_schieber': 'Takım vs Takım. 157 puan + Duyurular.',
        'mode_diff': 'Differenzler', 'desc_diff': 'Skorunu tahmin et. Fark ceza olur.',
        'team1': 'Biz', 'team2': 'Onlar', 'undo': 'Geri Al', 'reset': 'Yeni Oyun',
        'input_score': 'Puan...', 'round': 'Tur',
        'add_player': 'Ekle', 'start': 'BAŞLAT', 'prediction': 'Duyuru',
        'score': 'Skor', 'penalty': 'Ceza', 'weis_mode': 'Bonus',
        'weis_on': 'Bonus Modu: AÇIK', 'weis_off': 'El Modu',
        'rules_text': 'Modunu seç:\n\n• Schieber: bir takımın puanını gir, kalan (157\'ye tamamlanan) otomatik olarak diğer takıma gider. Puan girmeden önce koz için isteğe bağlı bir çarpan (×1-×4) seçebilirsin. Bonus (Weis) için: yıldız düğmesini aç - puanlar o zaman doğrudan ve çarpansız eklenir. Stöck düğmesi bir takıma doğrudan 20 puan ekler. İsteğe bağlı olarak bir hedef skor belirleyebilirsin (hedef göstergesine dokun) - ulaşıldığında maç sona erer. Geçmiş düğmesi tüm önceki girişleri gösterir.\n\n• Differenzler: oyuncu ekle ve isteğe bağlı bir tur limiti belirle. Her turda her oyuncu skorunu tahmin eder, ardından sonucu girer - fark ceza puanı olur. Güncel tur numarası üstte gösterilir; tur geçmişine o çubuktan ulaşılır. Tur limitiyle oyun otomatik olarak sona erer ve en az ceza puanına sahip olan kazanır.',
        'add_hint': 'İsim', 'rename_title': 'İsim Değiştir', 'cancel': 'İPTAL', 'save': 'KAYDET',
        'multiplier': 'Çarpan', 'stoeck': 'Stöck', 'target': 'Hedef', 'no_target': 'Hedef Yok',
        'history': 'Geçmiş', 'no_history': 'Henüz kayıt yok', 'match_won': 'MAÇI KAZANIYOR!',
        'round_limit': 'Tur Limiti', 'no_limit': 'Sınırsız', 'rounds_short': 'Turlar',
        'game_over': 'Oyun bitti', 'winner': 'Kazanan', 'new_game_btn': 'Yeni Oyun',
        'type_trick': 'El', 'type_weis': 'Weis', 'type_stoeck': 'Stöck',
      },
      'id': {
        'title': 'Jass', 'rules': 'Aturan', 'ok': 'MENGERTI',
        'mode_schieber': 'Schieber', 'desc_schieber': 'Tim vs Tim. 157 poin + Deklarasi.',
        'mode_diff': 'Differenzler', 'desc_diff': 'Prediksi skormu. Selisihnya menjadi hukuman.',
        'team1': 'Kami', 'team2': 'Mereka', 'undo': 'Batalkan', 'reset': 'Game Baru',
        'input_score': 'Poin...', 'round': 'Ronde',
        'add_player': 'Tambah', 'start': 'MULAI', 'prediction': 'Deklarasi',
        'score': 'Skor', 'penalty': 'Hukuman', 'weis_mode': 'Bonus',
        'weis_on': 'Mode Bonus: AKTIF', 'weis_off': 'Mode Trik',
        'rules_text': 'Pilih modemu:\n\n• Schieber: masukkan poin satu tim, sisanya (dari 157) otomatis ke tim lain. Kamu bisa memilih pengali (×1-×4) untuk kartu truf sebelum memasukkan poin. Untuk Bonus (Weis): aktifkan tombol bintang - poin lalu ditambahkan langsung tanpa pengali. Tombol Stöck menambah 20 poin langsung ke satu tim. Kamu bisa mengatur skor target (ketuk tampilan target) - setelah tercapai, pertandingan berakhir. Tombol Riwayat menampilkan semua entri sebelumnya.\n\n• Differenzler: tambahkan pemain dan opsional batas ronde. Setiap ronde setiap pemain mendeklarasikan skornya, lalu memasukkan hasilnya - selisihnya menjadi poin hukuman. Nomor ronde saat ini ditampilkan di atas; riwayat ronde dapat diakses lewat bilah itu. Dengan batas ronde, permainan berakhir otomatis dan siapa pun dengan poin hukuman terendah menang.',
        'add_hint': 'Nama', 'rename_title': 'Ubah Nama', 'cancel': 'BATAL', 'save': 'SIMPAN',
        'multiplier': 'Pengali', 'stoeck': 'Stöck', 'target': 'Target', 'no_target': 'Tanpa Target',
        'history': 'Riwayat', 'no_history': 'Belum ada entri', 'match_won': 'MEMENANGKAN PERTANDINGAN!',
        'round_limit': 'Batas Ronde', 'no_limit': 'Tanpa Batas', 'rounds_short': 'Ronde',
        'game_over': 'Permainan berakhir', 'winner': 'Pemenang', 'new_game_btn': 'Game Baru',
        'type_trick': 'Trik', 'type_weis': 'Weis', 'type_stoeck': 'Stöck',
      },
      'sv': {
        'title': 'Jass', 'rules': 'Regler', 'ok': 'FÖRSTÅTT',
        'mode_schieber': 'Schieber', 'desc_schieber': 'Lag mot Lag. 157 poäng + Ansägningar.',
        'mode_diff': 'Differenzler', 'desc_diff': 'Förutspå din poäng. Skillnaden blir straffet.',
        'team1': 'Vi', 'team2': 'Dem', 'undo': 'Ångra', 'reset': 'Nytt Spel',
        'input_score': 'Poäng...', 'round': 'Runda',
        'add_player': 'Lägg till', 'start': 'STARTA', 'prediction': 'Ansägning',
        'score': 'Poäng', 'penalty': 'Straff', 'weis_mode': 'Bonus',
        'weis_on': 'Bonusläge: PÅ', 'weis_off': 'Stickläge',
        'rules_text': 'Välj ditt läge:\n\n• Schieber: ange poängen för ett lag, resten (upp till 157) går automatiskt till det andra. Välj valfritt en multiplikator (×1-×4) för trumf innan du anger poäng. För Bonus (Weis): växla stjärnknappen - poäng läggs då till direkt och utan multiplikator. Stöck-knappen lägger till 20 poäng direkt till ett lag. Du kan valfritt ställa in ett målresultat (tryck på målvisningen) - när det nås avslutas matchen. Historikknappen visar alla tidigare poster.\n\n• Differenzler: lägg till spelare och valfritt en rundgräns. Varje runda förutspår varje spelare sin poäng och anger sedan resultatet - skillnaden blir straffpoäng. Aktuellt rundnummer visas högst upp; rundhistoriken nås via den raden. Med en rundgräns avslutas spelet automatiskt och den med minst straffpoäng vinner.',
        'add_hint': 'Namn', 'rename_title': 'Byt namn', 'cancel': 'AVBRYT', 'save': 'SPARA',
        'multiplier': 'Multiplikator', 'stoeck': 'Stöck', 'target': 'Mål', 'no_target': 'Inget mål',
        'history': 'Historik', 'no_history': 'Inga poster ännu', 'match_won': 'VINNER MATCHEN!',
        'round_limit': 'Rundgräns', 'no_limit': 'Obegränsat', 'rounds_short': 'Rundor',
        'game_over': 'Spelet slut', 'winner': 'Vinnare', 'new_game_btn': 'Nytt Spel',
        'type_trick': 'Stick', 'type_weis': 'Weis', 'type_stoeck': 'Stöck',
      },
      'hr': {
        'title': 'Jass', 'rules': 'Pravila', 'ok': 'RAZUMIJEM',
        'mode_schieber': 'Schieber', 'desc_schieber': 'Tim protiv Tima. 157 bodova + Najave.',
        'mode_diff': 'Differenzler', 'desc_diff': 'Predvidi svoj rezultat. Razlika je kazna.',
        'team1': 'Mi', 'team2': 'Oni', 'undo': 'Poništi', 'reset': 'Nova Igra',
        'input_score': 'Bodovi...', 'round': 'Krug',
        'add_player': 'Dodaj', 'start': 'POKRENI', 'prediction': 'Najava',
        'score': 'Rezultat', 'penalty': 'Kazna', 'weis_mode': 'Bonus',
        'weis_on': 'Bonus Način: UKLJUČEN', 'weis_off': 'Način Štiha',
        'rules_text': 'Odaberi svoj način:\n\n• Schieber: unesi bodove jednog tima, ostatak (do 157) automatski ide drugom timu. Prije unosa bodova možeš odabrati množitelj (×1-×4) za aduta. Za Bonus (Weis): uključi gumb sa zvijezdom - bodovi se tada zbrajaju izravno i bez množitelja. Gumb Stöck izravno dodaje 20 bodova timu. Možeš postaviti ciljni rezultat (dodirni prikaz cilja) - kad se dosegne, utakmica završava. Gumb Povijest prikazuje sve prijašnje unose.\n\n• Differenzler: dodaj igrače i opcionalno ograničenje krugova. Svaki krug svaki igrač najavljuje svoj rezultat, zatim unosi ishod - razlika postaje kazneni bodovi. Trenutni broj kruga prikazan je na vrhu; povijest krugova dostupna je putem te trake. S ograničenjem krugova igra automatski završava i pobjeđuje onaj s najmanje kaznenih bodova.',
        'add_hint': 'Ime', 'rename_title': 'Promijeni ime', 'cancel': 'ODUSTANI', 'save': 'SPREMI',
        'multiplier': 'Množitelj', 'stoeck': 'Stöck', 'target': 'Cilj', 'no_target': 'Bez cilja',
        'history': 'Povijest', 'no_history': 'Još nema unosa', 'match_won': 'POBJEĐUJE U UTAKMICI!',
        'round_limit': 'Ograničenje krugova', 'no_limit': 'Neograničeno', 'rounds_short': 'Krugovi',
        'game_over': 'Igra završena', 'winner': 'Pobjednik', 'new_game_btn': 'Nova Igra',
        'type_trick': 'Štih', 'type_weis': 'Weis', 'type_stoeck': 'Stöck',
      },
      'ru': {
        'title': 'Ясс', 'rules': 'Правила', 'ok': 'ПОНЯТНО',
        'mode_schieber': 'Шибер', 'desc_schieber': 'Команда на команду. 157 очков + Объявления.',
        'mode_diff': 'Дифференцлер', 'desc_diff': 'Спрогнозируй свой счёт. Разница - штраф.',
        'team1': 'Мы', 'team2': 'Они', 'undo': 'Отменить', 'reset': 'Новая игра',
        'input_score': 'Очки...', 'round': 'Раунд',
        'add_player': 'Добавить', 'start': 'НАЧАТЬ', 'prediction': 'Объявление',
        'score': 'Счёт', 'penalty': 'Штраф', 'weis_mode': 'Бонус',
        'weis_on': 'Режим бонуса: ВКЛ', 'weis_off': 'Режим взятки',
        'rules_text': 'Выберите режим:\n\n• Шибер: введите очки одной команды, остаток (до 157) автоматически идёт другой команде. Перед вводом очков можно выбрать множитель (×1-×4) для козыря. Для бонусов (Weis): включите кнопку со звездой - очки тогда добавляются напрямую, без множителя. Кнопка Stöck сразу добавляет команде 20 очков. Можно установить целевой счёт (нажмите на индикатор цели) - при его достижении матч завершается. Кнопка "История" показывает все прошлые записи.\n\n• Дифференцлер: добавьте игроков и, при желании, лимит раундов. Каждый раунд каждый игрок объявляет свой счёт, затем вводит результат - разница становится штрафными очками. Номер текущего раунда показан сверху; история раундов доступна через эту панель. При лимите раундов игра завершается автоматически, и побеждает тот, у кого меньше всего штрафных очков.',
        'add_hint': 'Имя', 'rename_title': 'Переименовать', 'cancel': 'ОТМЕНА', 'save': 'СОХРАНИТЬ',
        'multiplier': 'Множитель', 'stoeck': 'Stöck', 'target': 'Цель', 'no_target': 'Без цели',
        'history': 'История', 'no_history': 'Пока нет записей', 'match_won': 'ПОБЕЖДАЕТ В МАТЧЕ!',
        'round_limit': 'Лимит раундов', 'no_limit': 'Без ограничений', 'rounds_short': 'Раунды',
        'game_over': 'Игра окончена', 'winner': 'Победитель', 'new_game_btn': 'Новая игра',
        'type_trick': 'Взятка', 'type_weis': 'Weis', 'type_stoeck': 'Stöck',
      },
      'ja': {
        'title': 'ヤス', 'rules': 'ルール', 'ok': '了解',
        'mode_schieber': 'シーバー', 'desc_schieber': 'チーム対チーム。157点+アナウンス。',
        'mode_diff': 'ディフェレンツラー', 'desc_diff': 'スコアを予測。差がペナルティになります。',
        'team1': '私たち', 'team2': '彼ら', 'undo': '元に戻す', 'reset': '新しいゲーム',
        'input_score': 'ポイント...', 'round': 'ラウンド',
        'add_player': '追加', 'start': '開始', 'prediction': 'アナウンス',
        'score': 'スコア', 'penalty': 'ペナルティ', 'weis_mode': 'ボーナス',
        'weis_on': 'ボーナスモード: ON', 'weis_off': 'トリックモード',
        'rules_text': 'モードを選択:\n\n• シーバー: 片方のチームの得点を入力すると、157点の残りが自動的にもう一方のチームに加算されます。得点入力前に切り札の倍率(×1~×4)を任意で選択できます。ボーナス(Weis)の場合: スターボタンを切り替えると、得点は倍率なしで直接加算されます。Stöckボタンはチームに直接20点を加算します。目標得点を任意で設定でき(目標表示をタップ)、到達すると試合が終了します。履歴ボタンで過去の記録をすべて確認できます。\n\n• ディフェレンツラー: プレイヤーを追加し、任意でラウンド数の上限を設定します。各ラウンドで各プレイヤーが得点を予告し、その後結果を入力します - その差がペナルティ点になります。現在のラウンド番号は上部に表示され、ラウンド履歴はそのバーから確認できます。ラウンド上限に達すると試合は自動的に終了し、ペナルティ点が最も少ないプレイヤーが勝利します。',
        'add_hint': '名前', 'rename_title': '名前を変更', 'cancel': 'キャンセル', 'save': '保存',
        'multiplier': '倍率', 'stoeck': 'Stöck', 'target': '目標', 'no_target': '目標なし',
        'history': '履歴', 'no_history': 'まだ記録がありません', 'match_won': '試合に勝利!',
        'round_limit': 'ラウンド上限', 'no_limit': '無制限', 'rounds_short': 'ラウンド',
        'game_over': 'ゲーム終了', 'winner': '勝者', 'new_game_btn': '新しいゲーム',
        'type_trick': 'トリック', 'type_weis': 'Weis', 'type_stoeck': 'Stöck',
      },
      'ko': {
        'title': '야스', 'rules': '규칙', 'ok': '확인',
        'mode_schieber': '쉬버', 'desc_schieber': '팀 대 팀. 157점 + 선언.',
        'mode_diff': '디퍼렌즐러', 'desc_diff': '점수를 예측하세요. 차이가 벌점이 됩니다.',
        'team1': '우리', 'team2': '그들', 'undo': '실행 취소', 'reset': '새 게임',
        'input_score': '점수...', 'round': '라운드',
        'add_player': '추가', 'start': '시작', 'prediction': '선언',
        'score': '점수', 'penalty': '벌점', 'weis_mode': '보너스',
        'weis_on': '보너스 모드: 켜짐', 'weis_off': '트릭 모드',
        'rules_text': '모드를 선택하세요:\n\n• 쉬버: 한 팀의 점수를 입력하면 나머지(157점 기준)는 자동으로 다른 팀에 배정됩니다. 점수 입력 전 트럼프 배율(×1-×4)을 선택할 수 있습니다. 보너스(Weis)의 경우: 별 버튼을 켜면 점수가 배율 없이 바로 더해집니다. Stöck 버튼은 한 팀에 20점을 바로 추가합니다. 목표 점수를 설정할 수 있으며(목표 표시를 탭), 도달하면 경기가 종료됩니다. 기록 버튼으로 모든 이전 항목을 볼 수 있습니다.\n\n• 디퍼렌즐러: 플레이어를 추가하고 라운드 제한을 선택적으로 설정하세요. 매 라운드마다 각 플레이어가 점수를 선언한 후 결과를 입력합니다 - 그 차이가 벌점이 됩니다. 현재 라운드 번호가 상단에 표시되며, 라운드 기록은 해당 바를 통해 확인할 수 있습니다. 라운드 제한에 도달하면 게임이 자동으로 종료되고 벌점이 가장 적은 사람이 승리합니다.',
        'add_hint': '이름', 'rename_title': '이름 변경', 'cancel': '취소', 'save': '저장',
        'multiplier': '배율', 'stoeck': 'Stöck', 'target': '목표', 'no_target': '목표 없음',
        'history': '기록', 'no_history': '아직 기록 없음', 'match_won': '경기 승리!',
        'round_limit': '라운드 제한', 'no_limit': '무제한', 'rounds_short': '라운드',
        'game_over': '게임 종료', 'winner': '승자', 'new_game_btn': '새 게임',
        'type_trick': '트릭', 'type_weis': 'Weis', 'type_stoeck': 'Stöck',
      },
      'zh': {
        'title': '雅斯', 'rules': '规则', 'ok': '明白了',
        'mode_schieber': '席伯', 'desc_schieber': '团队对团队。157分+报牌。',
        'mode_diff': '差异赛', 'desc_diff': '预测你的分数,差值即为罚分。',
        'team1': '我们', 'team2': '他们', 'undo': '撤销', 'reset': '新游戏',
        'input_score': '分数...', 'round': '轮次',
        'add_player': '添加', 'start': '开始', 'prediction': '报牌',
        'score': '得分', 'penalty': '罚分', 'weis_mode': '奖励',
        'weis_on': '奖励模式:开', 'weis_off': '墩数模式',
        'rules_text': '选择你的模式:\n\n• 席伯:输入一队的分数,157分的剩余部分自动归另一队。输入分数前可选择将主牌倍率(×1-×4)。奖励(Weis):打开星形按钮后,分数将直接相加且不乘倍率。Stöck按钮可直接为一队加20分。可选择设定目标分数(点击目标显示区)——达到后比赛结束。历史按钮显示所有过往记录。\n\n• 差异赛:添加玩家,并可选择设置轮次上限。每轮每位玩家先报出预测分数,再输入实际结果——差值即为罚分。当前轮次号显示在顶部,轮次历史可通过该栏查看。设定轮次上限后,游戏会在达到上限时自动结束,罚分最少者获胜。',
        'add_hint': '姓名', 'rename_title': '重命名', 'cancel': '取消', 'save': '保存',
        'multiplier': '倍率', 'stoeck': 'Stöck', 'target': '目标', 'no_target': '无目标',
        'history': '历史', 'no_history': '暂无记录', 'match_won': '赢得比赛!',
        'round_limit': '轮次上限', 'no_limit': '无限制', 'rounds_short': '轮次',
        'game_over': '游戏结束', 'winner': '获胜者', 'new_game_btn': '新游戏',
        'type_trick': '墩', 'type_weis': 'Weis', 'type_stoeck': 'Stöck',
      },
      'hi': {
        'title': 'जैस', 'rules': 'नियम', 'ok': 'समझ गया',
        'mode_schieber': 'शिबर', 'desc_schieber': 'टीम बनाम टीम। 157 अंक + घोषणाएं।',
        'mode_diff': 'डिफरेंसलर', 'desc_diff': 'अपने अंक का अनुमान लगाएं। अंतर जुर्माना बनता है।',
        'team1': 'हम', 'team2': 'वे', 'undo': 'पूर्ववत करें', 'reset': 'नया खेल',
        'input_score': 'अंक...', 'round': 'दौर',
        'add_player': 'जोड़ें', 'start': 'शुरू', 'prediction': 'घोषणा',
        'score': 'स्कोर', 'penalty': 'जुर्माना', 'weis_mode': 'बोनस',
        'weis_on': 'बोनस मोड: चालू', 'weis_off': 'ट्रिक मोड',
        'rules_text': 'अपना मोड चुनें:\n\n• शिबर: एक टीम के अंक दर्ज करें, 157 का शेष स्वतः दूसरी टीम को मिल जाता है। अंक दर्ज करने से पहले तुरुप के लिए वैकल्पिक गुणक (×1-×4) चुनें। बोनस (Weis) के लिए: स्टार बटन चालू करें - अंक तब सीधे और बिना गुणक के जोड़े जाते हैं। Stöck बटन एक टीम में सीधे 20 अंक जोड़ता है। आप वैकल्पिक रूप से एक लक्ष्य स्कोर सेट कर सकते हैं (लक्ष्य डिस्प्ले पर टैप करें) - पहुंचने पर मैच समाप्त हो जाता है। इतिहास बटन सभी पिछली प्रविष्टियां दिखाता है।\n\n• डिफरेंसलर: खिलाड़ी जोड़ें और वैकल्पिक रूप से दौर की सीमा तय करें। हर दौर में हर खिलाड़ी अपने अंक की घोषणा करता है, फिर परिणाम दर्ज करता है - अंतर जुर्माना अंक बनता है। वर्तमान दौर संख्या ऊपर दिखाई जाती है; दौर इतिहास उस बार से देखा जा सकता है। दौर सीमा के साथ, खेल स्वतः समाप्त हो जाता है और सबसे कम जुर्माना अंक वाला जीतता है।',
        'add_hint': 'नाम', 'rename_title': 'नाम बदलें', 'cancel': 'रद्द करें', 'save': 'सहेजें',
        'multiplier': 'गुणक', 'stoeck': 'Stöck', 'target': 'लक्ष्य', 'no_target': 'कोई लक्ष्य नहीं',
        'history': 'इतिहास', 'no_history': 'अभी कोई प्रविष्टि नहीं', 'match_won': 'मैच जीता!',
        'round_limit': 'दौर सीमा', 'no_limit': 'असीमित', 'rounds_short': 'दौर',
        'game_over': 'खेल समाप्त', 'winner': 'विजेता', 'new_game_btn': 'नया खेल',
        'type_trick': 'ट्रिक', 'type_weis': 'Weis', 'type_stoeck': 'Stöck',
      },
      'bn': {
        'title': 'জাস', 'rules': 'নিয়ম', 'ok': 'বুঝেছি',
        'mode_schieber': 'শিবার', 'desc_schieber': 'দল বনাম দল। ১৫৭ পয়েন্ট + ঘোষণা।',
        'mode_diff': 'ডিফারেন্সলার', 'desc_diff': 'আপনার স্কোর পূর্বাভাস দিন। পার্থক্যটি জরিমানা হয়ে যায়।',
        'team1': 'আমরা', 'team2': 'তারা', 'undo': 'পূর্বাবস্থায় ফিরুন', 'reset': 'নতুন খেলা',
        'input_score': 'পয়েন্ট...', 'round': 'রাউন্ড',
        'add_player': 'যোগ', 'start': 'শুরু', 'prediction': 'ঘোষণা',
        'score': 'স্কোর', 'penalty': 'জরিমানা', 'weis_mode': 'বোনাস',
        'weis_on': 'বোনাস মোড: চালু', 'weis_off': 'ট্রিক মোড',
        'rules_text': 'আপনার মোড বেছে নিন:\n\n• শিবার: একটি দলের পয়েন্ট লিখুন, ১৫৭-এর বাকিটা স্বয়ংক্রিয়ভাবে অন্য দলে যাবে। পয়েন্ট লেখার আগে ঐচ্ছিকভাবে তুরুপের জন্য একটি গুণক (×1-×4) বেছে নিন। বোনাস (Weis)-এর জন্য: স্টার বাটন চালু করুন - পয়েন্ট তখন সরাসরি এবং গুণক ছাড়া যোগ হয়। Stöck বাটন সরাসরি একটি দলে ২০ পয়েন্ট যোগ করে। আপনি ঐচ্ছিকভাবে একটি লক্ষ্য স্কোর সেট করতে পারেন (লক্ষ্য প্রদর্শনে ট্যাপ করুন) - পৌঁছালে ম্যাচ শেষ হয়ে যায়। ইতিহাস বাটন সমস্ত পূর্ববর্তী এন্ট্রি দেখায়।\n\n• ডিফারেন্সলার: খেলোয়াড় যোগ করুন এবং ঐচ্ছিকভাবে একটি রাউন্ড সীমা নির্ধারণ করুন। প্রতি রাউন্ডে প্রতিটি খেলোয়াড় তার স্কোর ঘোষণা করে, তারপর ফলাফল লেখে - পার্থক্যটি জরিমানা পয়েন্ট হয়ে যায়। বর্তমান রাউন্ড নম্বর উপরে দেখানো হয়; রাউন্ড ইতিহাস সেই বার থেকে দেখা যায়। রাউন্ড সীমা সহ, খেলা স্বয়ংক্রিয়ভাবে শেষ হয় এবং সবচেয়ে কম জরিমানা পয়েন্টধারী জেতে।',
        'add_hint': 'নাম', 'rename_title': 'নাম পরিবর্তন', 'cancel': 'বাতিল', 'save': 'সংরক্ষণ',
        'multiplier': 'গুণক', 'stoeck': 'Stöck', 'target': 'লক্ষ্য', 'no_target': 'কোনো লক্ষ্য নেই',
        'history': 'ইতিহাস', 'no_history': 'এখনো কোনো এন্ট্রি নেই', 'match_won': 'ম্যাচ জিতেছে!',
        'round_limit': 'রাউন্ড সীমা', 'no_limit': 'সীমাহীন', 'rounds_short': 'রাউন্ড',
        'game_over': 'খেলা শেষ', 'winner': 'বিজয়ী', 'new_game_btn': 'নতুন খেলা',
        'type_trick': 'ট্রিক', 'type_weis': 'Weis', 'type_stoeck': 'Stöck',
      },
    };

    if (dictionary.containsKey(_currentLang) && dictionary[_currentLang]!.containsKey(key)) {
      return dictionary[_currentLang]![key]!;
    }
    var enDict = dictionary['en']!;
    return enDict[key] ?? key;
  }

  // --- LOGIC: SCHIEBER ---

  void _addInput(String val) {
    if (_currentInput.length < 4) {
      setState(() => _currentInput += val);
    }
  }

  void _backspace() {
    if (_currentInput.isNotEmpty) {
      setState(() => _currentInput = _currentInput.substring(0, _currentInput.length - 1));
    }
  }

  void _submitSchieberScore(bool isTeam1) {
    if (_currentInput.isEmpty) return;
    int points = int.parse(_currentInput);

    int t1Add = 0;
    int t2Add = 0;
    int appliedMultiplier = _isWeisMode ? 1 : _multiplier;

    if (_isWeisMode) {
      if (isTeam1) t1Add = points;
      else t2Add = points;
    } else {
      if (points <= 157) {
        if (isTeam1) {
          t1Add = points;
          t2Add = 157 - points;
        } else {
          t2Add = points;
          t1Add = 157 - points;
        }
      } else {
        if (isTeam1) t1Add = points;
        else t2Add = points;
      }
      t1Add *= appliedMultiplier;
      t2Add *= appliedMultiplier;
    }

    setState(() {
      team1Score += t1Add;
      team2Score += t2Add;
      history.add({
        't1': t1Add, 't2': t2Add,
        'type': _isWeisMode ? 'weis' : 'trick',
        'multiplier': appliedMultiplier,
      });
      _currentInput = "";
      _isWeisMode = false;
      _multiplier = 1;
      _checkMatchOver();
    });
  }

  // Stöck: 20 Punkte direkt und unmultipliziert für ein Team.
  void _addStoeck(bool isTeam1) {
    HapticFeedback.mediumImpact();
    setState(() {
      int t1Add = isTeam1 ? 20 : 0;
      int t2Add = isTeam1 ? 0 : 20;
      team1Score += t1Add;
      team2Score += t2Add;
      history.add({'t1': t1Add, 't2': t2Add, 'type': 'stoeck', 'multiplier': 1});
      _checkMatchOver();
    });
  }

  void _checkMatchOver() {
    if (_matchTarget == null) return;
    if (team1Score >= _matchTarget! || team2Score >= _matchTarget!) {
      _schieberFinished = true;
    }
  }

  void _undo() {
    if (history.isNotEmpty) {
      var last = history.removeLast();
      setState(() {
        team1Score -= last['t1'] as int;
        team2Score -= last['t2'] as int;
        _schieberFinished = false;
      });
    }
  }

  IconData _historyIcon(String type) {
    switch (type) {
      case 'weis': return Icons.star;
      case 'stoeck': return Icons.diamond;
      default: return Icons.style;
    }
  }

  String _historyLabel(String type) {
    switch (type) {
      case 'weis': return _t('type_weis');
      case 'stoeck': return _t('type_stoeck');
      default: return _t('type_trick');
    }
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_t('history'), style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: history.isEmpty
                  ? Center(child: Text(_t('no_history'), style: const TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        // Neueste zuerst
                        final entry = history[history.length - 1 - index];
                        final roundNr = history.length - index;
                        final type = entry['type'] as String? ?? 'trick';
                        final mult = entry['multiplier'] as int? ?? 1;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              Icon(_historyIcon(type), color: primaryColor, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "#$roundNr  ${_historyLabel(type)}${mult > 1 ? ' ×$mult' : ''}",
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ),
                              Text("${entry['t1']}", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 15),
                              Text("${entry['t2']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(bool isTeam1) {
    _nameController.text = isTeam1 ? team1Name : team2Name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: primaryColor)),
        title: Text(_t('rename_title'), style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
          ),
          onSubmitted: (_) {
            setState(() {
              if (isTeam1) team1Name = _nameController.text.trim();
              else team2Name = _nameController.text.trim();
            });
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (isTeam1) team1Name = _nameController.text.trim();
                else team2Name = _nameController.text.trim();
              });
              Navigator.pop(context);
            },
            child: Text(_t('save'), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- LOGIC: DIFFERENZLER ---

  void _addDiffPlayer() {
    if(_nameController.text.isNotEmpty) {
      setState(() {
        diffPlayers.add({
          'name': _nameController.text,
          'total_penalty': 0,
          'current_target': null,
        });
        _nameController.clear();
      });
    }
  }

  void _startDiffGame() {
    if (diffPlayers.length < 2) return;
    setState(() {
      _diffGameStarted = true;
      _diffGameFinished = false;
      _diffCurrentRound = 1;
      _diffRoundBuffer = {};
      diffRoundLog = [];
    });
  }

  void _submitDiffScore(int index, int madePoints) {
    var p = diffPlayers[index];
    if (p['current_target'] == null) {
      setState(() {
        p['current_target'] = madePoints;
      });
    } else {
      int target = p['current_target'];
      int diff = (target - madePoints).abs();
      setState(() {
        p['total_penalty'] += diff;
        _diffRoundBuffer[p['name']] = {'target': target, 'actual': madePoints, 'penalty': diff};
        p['current_target'] = null;

        // Runde ist komplett, wenn alle Spieler ihr Resultat eingetragen haben
        if (_diffRoundBuffer.length == diffPlayers.length) {
          diffRoundLog.add({
            'round': _diffCurrentRound,
            'entries': Map<String, Map<String, int>>.from(_diffRoundBuffer),
          });
          _diffRoundBuffer = {};

          if (_diffRoundLimit != null && _diffCurrentRound >= _diffRoundLimit!) {
            _diffGameFinished = true;
          } else {
            _diffCurrentRound++;
          }
        }
      });
    }
  }

  void _resetDiffGame() {
    setState(() {
      _diffGameStarted = false;
      _diffGameFinished = false;
      diffPlayers.clear();
      _diffCurrentRound = 1;
      _diffRoundBuffer = {};
      diffRoundLog = [];
    });
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
          if (_selectedMode == JassMode.schieber && history.isNotEmpty)
            IconButton(icon: const Icon(Icons.history), onPressed: _showHistorySheet, tooltip: _t('history')),
          if (_selectedMode != null)
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() {
              _selectedMode = null;
              team1Score = 0; team2Score = 0; history.clear();
              _isWeisMode = false; _multiplier = 1; _matchTarget = null; _schieberFinished = false;
              diffPlayers.clear();
              _diffGameStarted = false; _diffGameFinished = false;
              _diffCurrentRound = 1; _diffRoundBuffer = {}; diffRoundLog = []; _diffRoundLimit = null;
            })),
          IconButton(icon: const Icon(Icons.help_outline), onPressed: _showRules),
        ],
      ),
      body: _selectedMode == null ? _buildModeSelector() : _buildGameInterface(),
    );
  }

  void _showRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        title: Text(_t('rules'), style: TextStyle(color: primaryColor)),
        content: Text(_t('rules_text'), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_t('ok'), style: TextStyle(color: primaryColor))),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _modeCard(JassMode.schieber, Icons.edit_note, _t('mode_schieber'), _t('desc_schieber')),
            const SizedBox(height: 15),
            _modeCard(JassMode.differenzler, Icons.track_changes, _t('mode_diff'), _t('desc_diff')),
          ],
        ),
      ),
    );
  }

  Widget _modeCard(JassMode mode, IconData icon, String title, String desc) {
    return Card(
      color: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: primaryColor.withOpacity(0.3))),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Icon(icon, color: primaryColor, size: 40),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: Text(desc, style: const TextStyle(color: Colors.white54)),
        onTap: () => setState(() => _selectedMode = mode),
      ),
    );
  }

  Widget _buildGameInterface() {
    if (_selectedMode == JassMode.differenzler) {
      return _buildDifferenzlerUI();
    }
    return _buildSchieberUI();
  }

  // --- SCHIEBER UI ---
  Widget _buildSchieberUI() {
    if (_schieberFinished) return _buildSchieberGameOver();

    return Column(
      children: [
        // Ziel-Anzeige
        GestureDetector(
          onTap: _showTargetPicker,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.black12,
            child: Center(
              child: Text(
                "${_t('target')}: ${_matchTarget == null ? _t('no_target') : _matchTarget}",
                style: TextStyle(color: primaryColor.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),

        // Score Display
        Expanded(
          flex: 2,
          child: Row(
            children: [
              _buildTeamColumn(team1Name, team1Score, true),
              Container(width: 2, color: Colors.black26),
              _buildTeamColumn(team2Name, team2Score, false),
            ],
          ),
        ),

        // Input Area
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            color: surfaceColor,
            padding: const EdgeInsets.only(top: 25, left: 20, right: 20, bottom: 30),
            child: Column(
              children: [
                // Multiplikator Auswahl
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [1, 2, 3, 4].map((m) {
                    bool selected = _multiplier == m;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _multiplier = m),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? primaryColor : Colors.black26,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: selected ? primaryColor : Colors.transparent),
                          ),
                          child: Text("×$m", style: TextStyle(color: selected ? Colors.black : Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // Weis Toggle & Input Display
                Row(
                  children: [
                    // Weis Toggle
                    GestureDetector(
                      onTap: () => setState(() => _isWeisMode = !_isWeisMode),
                      child: Container(
                        height: 70,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                            color: _isWeisMode ? primaryColor : Colors.black26,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: _isWeisMode ? Colors.white : Colors.transparent)
                        ),
                        child: Icon(Icons.star, color: _isWeisMode ? Colors.black : Colors.grey, size: 30),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Display Input
                    Expanded(
                      child: Container(
                        height: 70,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                _isWeisMode ? _t('weis_on') : _t('weis_off'),
                                style: TextStyle(color: _isWeisMode ? primaryColor : Colors.grey, fontSize: 14)
                            ),
                            Text(
                              _currentInput.isEmpty ? "0" : _currentInput,
                              style: TextStyle(color: _currentInput.isEmpty ? Colors.white24 : Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Keypad (jetzt komplett mit Flex, damit nichts abgeschnitten wird)
                Expanded(
                  child: _buildKeypad(),
                ),

                const SizedBox(height: 20),

                // Assign Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _currentInput.isEmpty ? null : () => _submitSchieberScore(true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _isWeisMode ? Colors.orange : primaryColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                        ),
                        child: Text(team1Name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20), overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(15)
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.undo, color: Colors.grey),
                        iconSize: 30,
                        padding: const EdgeInsets.all(15),
                        onPressed: history.isEmpty ? null : _undo,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _currentInput.isEmpty ? null : () => _submitSchieberScore(false),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _isWeisMode ? Colors.orange : primaryColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                        ),
                        child: Text(team2Name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20), overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showTargetPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: primaryColor)),
        title: Text(_t('target'), style: TextStyle(color: primaryColor)),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [null, 1000, 1500, 2500].map((val) {
            bool selected = _matchTarget == val;
            return ChoiceChip(
              label: Text(val == null ? _t('no_target') : "$val", style: TextStyle(color: selected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
              selected: selected,
              selectedColor: primaryColor,
              backgroundColor: Colors.black26,
              onSelected: (_) {
                setState(() {
                  _matchTarget = val;
                  _checkMatchOver();
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSchieberGameOver() {
    bool team1Wins = team1Score < team2Score; // weniger Punkte = besser
    String winnerName = team1Wins ? team1Name : team2Name;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 90, color: primaryColor),
            const SizedBox(height: 20),
            Text(_t('game_over'), style: const TextStyle(color: Colors.grey, letterSpacing: 2)),
            const SizedBox(height: 5),
            Text(winnerName, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
            Text(_t('match_won'), style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text("$team1Name: $team1Score   —   $team2Name: $team2Score", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    team1Score = 0; team2Score = 0; history.clear();
                    _schieberFinished = false;
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black),
                child: Text(_t('new_game_btn'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamColumn(String name, int score, bool isTeam1) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showRenameDialog(isTeam1),
        child: Container(
          color: Colors.transparent, // Nötig für Klick-Erkennung auf ganzer Fläche
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: TextStyle(color: primaryColor, fontSize: 22, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit, color: primaryColor.withOpacity(0.5), size: 16),
                ],
              ),
              const SizedBox(height: 10),
              Text("$score", style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _addStoeck(isTeam1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.diamond, size: 12, color: primaryColor.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text("${_t('stoeck')} +20", style: TextStyle(color: primaryColor.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Flexibles Keypad ohne GridView, um Overflow/Abschneiden zu verhindern
  Widget _buildKeypad() {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: ["1", "2", "3"].map((val) => _keyBtn(val)).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: ["4", "5", "6"].map((val) => _keyBtn(val)).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: ["7", "8", "9"].map((val) => _keyBtn(val)).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _iconKeyBtn(Icons.backspace, _backspace),
              _keyBtn("0"),
              Expanded(child: const SizedBox()), // Leeres Feld rechts unten
            ],
          ),
        ),
      ],
    );
  }

  Widget _keyBtn(String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ElevatedButton(
          onPressed: () { HapticFeedback.selectionClick(); _addInput(label); },
          style: ElevatedButton.styleFrom(
              backgroundColor: activeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4
          ),
          child: Text(label, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _iconKeyBtn(IconData icon, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ElevatedButton(
          onPressed: () { HapticFeedback.selectionClick(); onTap(); },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0
          ),
          child: Icon(icon, size: 28),
        ),
      ),
    );
  }

  // --- DIFFERENZLER UI ---
  Widget _buildDifferenzlerUI() {
    if (!_diffGameStarted) {
      // Setup Phase
      return Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Icon(Icons.groups, size: 80, color: primaryColor),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _t('add_hint'),
                          filled: true, fillColor: surfaceColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onSubmitted: (_) => _addDiffPlayer(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _addDiffPlayer,
                      style: IconButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.all(12)),
                      icon: const Icon(Icons.add, color: Colors.black),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                if (diffPlayers.isNotEmpty)
                  ...diffPlayers.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(10)),
                    child: Text(p['name'], style: const TextStyle(color: Colors.white, fontSize: 16)),
                  )),

                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_t('round_limit'), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [null, 5, 10, 15].map((val) {
                    bool selected = _diffRoundLimit == val;
                    return ChoiceChip(
                      label: Text(val == null ? _t('no_limit') : "$val", style: TextStyle(color: selected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                      selected: selected,
                      selectedColor: primaryColor,
                      backgroundColor: surfaceColor,
                      onSelected: (_) => setState(() => _diffRoundLimit = val),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          if (diffPlayers.length >= 2)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _startDiffGame,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                child: Text(_t('start'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )
        ],
      );
    }

    if (_diffGameFinished) return _buildDiffGameOver();

    // Game Phase
    return Column(
      children: [
        GestureDetector(
          onTap: diffRoundLog.isEmpty ? null : _showDiffHistorySheet,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.black12,
            child: Center(
              child: Text(
                "${_t('round')} $_diffCurrentRound${_diffRoundLimit != null ? ' / $_diffRoundLimit' : ''}"
                "${diffRoundLog.isNotEmpty ? '   •   ${_t('history')}' : ''}",
                style: TextStyle(color: primaryColor.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: diffPlayers.length,
            itemBuilder: (context, index) {
              final p = diffPlayers[index];
              bool waitingForAnsage = p['current_target'] == null;

              return Card(
                color: surfaceColor,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: primaryColor.withOpacity(0.3))),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['name'], style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text("${_t('penalty')}: ${p['total_penalty']}", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      ),

                      // Status / Input Trigger
                      InkWell(
                        onTap: () => _showDiffInput(index, waitingForAnsage),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          decoration: BoxDecoration(
                              color: waitingForAnsage ? Colors.black26 : primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: waitingForAnsage ? Colors.grey : primaryColor)
                          ),
                          child: Column(
                            children: [
                              Text(waitingForAnsage ? _t('prediction') : _t('score'), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                              Text(
                                  waitingForAnsage ? "?" : "${p['current_target']}",
                                  style: TextStyle(color: waitingForAnsage ? Colors.white : primaryColor, fontSize: 20, fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDiffHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_t('history'), style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: diffRoundLog.length,
                itemBuilder: (context, i) {
                  final round = diffRoundLog[diffRoundLog.length - 1 - i];
                  final Map<String, Map<String, int>> entries = round['entries'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${_t('round')} ${round['round']}", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        ...entries.entries.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            "${e.key}: ${_t('prediction')} ${e.value['target']} → ${_t('score')} ${e.value['actual']} (+${e.value['penalty']})",
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        )),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiffGameOver() {
    List<Map<String, dynamic>> sorted = List.from(diffPlayers);
    sorted.sort((a, b) => (a['total_penalty'] as int).compareTo(b['total_penalty'] as int));
    int bestScore = sorted.first['total_penalty'];
    String winnerName = sorted.first['name'];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 90, color: primaryColor),
            const SizedBox(height: 20),
            Text(_t('game_over'), style: const TextStyle(color: Colors.grey, letterSpacing: 2)),
            const SizedBox(height: 5),
            Text(winnerName, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
            Text("${_t('penalty')}: $bestScore", style: TextStyle(color: primaryColor, fontSize: 16)),
            const SizedBox(height: 30),
            ...sorted.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Text("${e.key + 1}.", style: TextStyle(color: e.key == 0 ? primaryColor : Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 15),
                  Expanded(child: Text(e.value['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Text("${e.value['total_penalty']}", style: const TextStyle(color: Colors.white)),
                ],
              ),
            )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _resetDiffGame,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black),
                child: Text(_t('new_game_btn'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDiffInput(int index, bool isAnsage) {
    String title = isAnsage ? _t('prediction') : _t('score');
    String buffer = "";

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            // Nutzen wir hier Media Query für eine dynamische Höhe ohne Overflow
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                Text("${diffPlayers[index]['name']} - $title", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                  child: Text(buffer.isEmpty ? "0" : buffer, textAlign: TextAlign.center, style: TextStyle(color: primaryColor, fontSize: 40, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),

                // Keypad auch hier auf Flex umgestellt, damit es auf kleinen Screens passt
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: ["1", "2", "3"].map((val) => _diffKeyBtn(val, setModalState, (v) => buffer = v, buffer)).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: ["4", "5", "6"].map((val) => _diffKeyBtn(val, setModalState, (v) => buffer = v, buffer)).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: ["7", "8", "9"].map((val) => _diffKeyBtn(val, setModalState, (v) => buffer = v, buffer)).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _diffIconBtn(Icons.delete, Colors.red.withOpacity(0.3), Colors.white, () => setModalState(() => buffer = "")),
                            _diffKeyBtn("0", setModalState, (v) => buffer = v, buffer),
                            _diffIconBtn(Icons.check, primaryColor, Colors.black, () {
                              int val = int.tryParse(buffer) ?? 0;
                              _submitDiffScore(index, val);
                              Navigator.pop(context);
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        });
      },
    );
  }

  // Hilfs-Buttons für das Differenzler Keypad (mit Flex)
  Widget _diffKeyBtn(String label, StateSetter setModalState, Function(String) updateBuffer, String currentBuffer) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: activeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            if (currentBuffer.length < 4) {
              setModalState(() => updateBuffer(currentBuffer + label));
            }
          },
          child: Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _diffIconBtn(IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }
}