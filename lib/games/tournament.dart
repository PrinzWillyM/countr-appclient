import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- MODELS ---
enum TournamentType { knockout, league }

class TournamentMatch {
  String id;
  String player1;
  String player2;
  String? winner; // null = noch nicht gespielt
  int round; // Für K.O. System (1 = Achtelfinale, etc.)

  TournamentMatch({
    required this.id,
    required this.player1,
    required this.player2,
    this.round = 1,
    this.winner,
  });
}

class LeaguePlayer {
  String name;
  int wins;
  int losses;
  int points;

  LeaguePlayer({required this.name, this.wins = 0, this.losses = 0, this.points = 0});
}

// --- WIDGET ---
class TournamentGame extends StatefulWidget {
  final Color? themeColor;

  const TournamentGame({super.key, this.themeColor});

  @override
  State<TournamentGame> createState() => _TournamentGameState();
}

class _TournamentGameState extends State<TournamentGame> {
  // --- STYLE ---
  Color get primaryColor => widget.themeColor ?? const Color(0xFFEBCB63); // Standard Gelb
  final Color bgColor = const Color(0xFF222629);
  final Color surfaceColor = const Color(0xFF30363B);
  final Color activeColor = const Color(0xFF3E444A);

  // --- STATE ---
  int _step = 0; // 0=Mode, 1=Players, 2=Tournament
  TournamentType? _selectedMode;
  List<String> _playerNames = [];
  final TextEditingController _nameController = TextEditingController();

  // Game Logic State
  List<TournamentMatch> _matches = [];
  List<LeaguePlayer> _leagueTable = [];
  int _currentRound = 1; // Nur für K.O.

  // --- LANGUAGE ---
  String _currentLang = 'en';

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

  String _t(String key) {
    const Map<String, Map<String, String>> dictionary = {
      'de': {
        'title': 'Turnier Planer', 'mode_ko': 'K.O. System', 'mode_league': 'Jeder gegen Jeden',
        'mode_ko_desc': 'Der Verlierer fliegt raus.', 'mode_league_desc': 'Alle spielen gegen alle.',
        'add_players': 'Teilnehmer', 'add_hint': 'Name eingeben', 'start': 'TURNIER STARTEN',
        'round': 'Runde', 'winner': 'Gewinner', 'standing': 'Tabelle',
        'games': 'Spiele', 'wins': 'S', 'points': 'Pkt', 'set_winner': 'Wer hat gewonnen?',
        'champion': 'Turniersieger:', 'next_round': 'NÄCHSTE RUNDE',
        'game_over': 'Turnier beendet!', 'reset': 'Beenden', 'not_enough': 'Mindestens 2 Spieler',
        'bye': 'Freilos', 'rules_title': 'Anleitung', 'ok': 'VERSTANDEN',
        'rules_text': 'Wähle einen Modus:\n\n• K.O.: Der Gewinner kommt weiter, der Verlierer scheidet aus.\n• Liga: Jeder spielt gegen jeden. Ein Sieg gibt 3 Punkte.\n\nTippe auf ein Match, um den Gewinner zu bestimmen.',
      },
      'en': {
        'title': 'Tournament Planner', 'mode_ko': 'Knockout', 'mode_league': 'Round Robin',
        'mode_ko_desc': 'Loser is out.', 'mode_league_desc': 'Everyone plays everyone.',
        'add_players': 'Participants', 'add_hint': 'Enter name', 'start': 'START TOURNAMENT',
        'round': 'Round', 'winner': 'Winner', 'standing': 'Standings',
        'games': 'Matches', 'wins': 'W', 'points': 'Pts', 'set_winner': 'Who won?',
        'champion': 'Champion:', 'next_round': 'NEXT ROUND',
        'game_over': 'Tournament over!', 'reset': 'Quit', 'not_enough': 'Need 2+ players',
        'bye': 'Bye', 'rules_title': 'How it works', 'ok': 'GOT IT',
        'rules_text': 'Choose a mode:\n\n• Knockout: Winner advances, loser is out.\n• League: Everyone plays everyone. Win = 3 Points.\n\nTap a match to select the winner.',
      },
      'fr': {
        'title': 'Planificateur de Tournoi', 'mode_ko': 'Élimination directe', 'mode_league': 'Championnat',
        'mode_ko_desc': 'Le perdant est éliminé.', 'mode_league_desc': 'Tout le monde joue contre tout le monde.',
        'add_players': 'Participants', 'add_hint': 'Entrez le nom', 'start': 'COMMENCER',
        'round': 'Tour', 'winner': 'Vainqueur', 'standing': 'Classement',
        'games': 'Matchs', 'wins': 'V', 'points': 'Pts', 'set_winner': 'Qui a gagné ?',
        'champion': 'Champion :', 'next_round': 'TOUR SUIVANT',
        'game_over': 'Tournoi terminé !', 'reset': 'Quitter', 'not_enough': 'Il faut 2+ joueurs',
        'bye': 'Exempt', 'rules_title': 'Instructions', 'ok': 'COMPRIS',
        'rules_text': 'Choisissez un mode :\n\n• K.O. : Le vainqueur avance, le perdant est éliminé.\n• Ligue : Tout le monde s\'affronte. Victoire = 3 points.\n\nAppuyez sur un match pour choisir le vainqueur.',
      },
      'it': {
        'title': 'Torneo', 'mode_ko': 'Eliminazione diretta', 'mode_league': 'Campionato',
        'mode_ko_desc': 'Chi perde esce.', 'mode_league_desc': 'Tutti contro tutti.',
        'add_players': 'Partecipanti', 'add_hint': 'Inserisci nome', 'start': 'AVVIA TORNEO',
        'round': 'Round', 'winner': 'Vincitore', 'standing': 'Classifica',
        'games': 'Partite', 'wins': 'V', 'points': 'Pt', 'set_winner': 'Chi ha vinto?',
        'champion': 'Campione:', 'next_round': 'PROSSIMO ROUND',
        'game_over': 'Torneo finito!', 'reset': 'Esci', 'not_enough': 'Servono 2+ giocatori',
        'bye': 'Bye', 'rules_title': 'Istruzioni', 'ok': 'CAPITO',
        'rules_text': 'Scegli una modalità:\n\n• K.O.: Il vincitore avanza, chi perde esce.\n• Campionato: Tutti giocano contro tutti. Vittoria = 3 punti.\n\nTocca una partita per scegliere il vincitore.',
      },
      'es': {
        'title': 'Torneo', 'mode_ko': 'Eliminatoria', 'mode_league': 'Liga',
        'mode_ko_desc': 'El perdedor queda fuera.', 'mode_league_desc': 'Todos contra todos.',
        'add_players': 'Participantes', 'add_hint': 'Nombre', 'start': 'INICIAR TORNEO',
        'round': 'Ronda', 'winner': 'Ganador', 'standing': 'Clasificación',
        'games': 'Partidos', 'wins': 'V', 'points': 'Pts', 'set_winner': '¿Quién ganó?',
        'champion': 'Campeón:', 'next_round': 'SIGUIENTE RONDA',
        'game_over': '¡Torneo terminado!', 'reset': 'Salir', 'not_enough': 'Necesitas 2+ jugadores',
        'bye': 'Pase', 'rules_title': 'Instrucciones', 'ok': 'ENTENDIDO',
        'rules_text': 'Elige un modo:\n\n• K.O.: El ganador avanza, el perdedor queda fuera.\n• Liga: Todos contra todos. Victoria = 3 puntos.\n\nToca un partido para elegir al ganador.',
      },
      'pt': {
        'title': 'Torneio', 'mode_ko': 'Mata-mata', 'mode_league': 'Liga',
        'mode_ko_desc': 'Quem perde sai.', 'mode_league_desc': 'Todos contra todos.',
        'add_players': 'Participantes', 'add_hint': 'Nome', 'start': 'INICIAR',
        'round': 'Rodada', 'winner': 'Vencedor', 'standing': 'Classificação',
        'games': 'Jogos', 'wins': 'V', 'points': 'Pts', 'set_winner': 'Quem ganhou?',
        'champion': 'Campeão:', 'next_round': 'PRÓXIMA RODADA',
        'game_over': 'Fim do torneio!', 'reset': 'Sair', 'not_enough': 'Precisa de 2+ jogadores',
        'bye': 'Isento', 'rules_title': 'Instruções', 'ok': 'ENTENDIDO',
        'rules_text': 'Escolha um modo:\n\n• Mata-mata: O vencedor avança.\n• Liga: Todos jogam contra todos. Vitória = 3 pontos.\n\nToque em um jogo para escolher o vencedor.',
      },
      'nl': {
        'title': 'Toernooi', 'mode_ko': 'Knock-out', 'mode_league': 'Competitie',
        'mode_ko_desc': 'Verliezer ligt eruit.', 'mode_league_desc': 'Iedereen tegen iedereen.',
        'add_players': 'Deelnemers', 'add_hint': 'Naam invoeren', 'start': 'STARTEN',
        'round': 'Ronde', 'winner': 'Winnaar', 'standing': 'Stand',
        'games': 'Wedstrijden', 'wins': 'W', 'points': 'Pnt', 'set_winner': 'Wie heeft gewonnen?',
        'champion': 'Kampioen:', 'next_round': 'VOLGENDE RONDE',
        'game_over': 'Toernooi voorbij!', 'reset': 'Stoppen', 'not_enough': 'Min. 2 spelers',
        'bye': 'Vrij', 'rules_title': 'Instructies', 'ok': 'BEGREPEN',
        'rules_text': 'Kies een modus:\n\n• K.O.: Winnaar gaat door.\n• Competitie: Iedereen speelt tegen iedereen. Winst = 3 punten.\n\nTik op een wedstrijd om de winnaar te kiezen.',
      },
      'pl': {
        'title': 'Turniej', 'mode_ko': 'Pucharowy', 'mode_league': 'Liga',
        'mode_ko_desc': 'Przegrany odpada.', 'mode_league_desc': 'Każdy z każdym.',
        'add_players': 'Uczestnicy', 'add_hint': 'Wpisz imię', 'start': 'START',
        'round': 'Runda', 'winner': 'Zwycięzca', 'standing': 'Tabela',
        'games': 'Mecze', 'wins': 'W', 'points': 'Pkt', 'set_winner': 'Kto wygrał?',
        'champion': 'Mistrz:', 'next_round': 'NASTĘPNA RUNDA',
        'game_over': 'Koniec turnieju!', 'reset': 'Wyjdź', 'not_enough': 'Min. 2 graczy',
        'bye': 'Wolny los', 'rules_title': 'Instrukcja', 'ok': 'ZROZUMIAŁEM',
        'rules_text': 'Wybierz tryb:\n\n• Pucharowy: Zwycięzca przechodzi dalej.\n• Liga: Każdy z każdym. Wygrana = 3 punkty.\n\nDotknij meczu, aby wybrać zwycięzcę.',
      },
      'tr': {
        'title': 'Turnuva', 'mode_ko': 'Eleme', 'mode_league': 'Lig',
        'mode_ko_desc': 'Kaybeden elenir.', 'mode_league_desc': 'Herkes herkesle oynar.',
        'add_players': 'Katılımcılar', 'add_hint': 'İsim girin', 'start': 'BAŞLAT',
        'round': 'Tur', 'winner': 'Kazanan', 'standing': 'Puan Durumu',
        'games': 'Maçlar', 'wins': 'G', 'points': 'P', 'set_winner': 'Kim kazandı?',
        'champion': 'Şampiyon:', 'next_round': 'SONRAKİ TUR',
        'game_over': 'Turnuva bitti!', 'reset': 'Çıkış', 'not_enough': 'En az 2 oyuncu',
        'bye': 'Bay', 'rules_title': 'Kurallar', 'ok': 'ANLADIM',
        'rules_text': 'Bir mod seçin:\n\n• Eleme: Kazanan ilerler, kaybeden elenir.\n• Lig: Herkes herkesle oynar. Galibiyet = 3 puan.\n\nKazananı seçmek için maça dokunun.',
      },
      'id': {
        'title': 'Turnamen', 'mode_ko': 'Sistem Gugur', 'mode_league': 'Liga',
        'mode_ko_desc': 'Yang kalah keluar.', 'mode_league_desc': 'Semua lawan semua.',
        'add_players': 'Peserta', 'add_hint': 'Masukkan nama', 'start': 'MULAI',
        'round': 'Ronde', 'winner': 'Pemenang', 'standing': 'Klasemen',
        'games': 'Pertandingan', 'wins': 'M', 'points': 'Poin', 'set_winner': 'Siapa yang menang?',
        'champion': 'Juara:', 'next_round': 'RONDE BERIKUTNYA',
        'game_over': 'Turnamen selesai!', 'reset': 'Keluar', 'not_enough': 'Min. 2 pemain',
        'bye': 'Bye', 'rules_title': 'Instruksi', 'ok': 'MENGERTI',
        'rules_text': 'Pilih mode:\n\n• Gugur: Pemenang lanjut.\n• Liga: Semua lawan semua. Menang = 3 poin.\n\nKetuk pertandingan untuk memilih pemenang.',
      },
      'sv': {
        'title': 'Turnering', 'mode_ko': 'Utslagning', 'mode_league': 'Liga',
        'mode_ko_desc': 'Förloraren åker ut.', 'mode_league_desc': 'Alla möter alla.',
        'add_players': 'Deltagare', 'add_hint': 'Ange namn', 'start': 'STARTA',
        'round': 'Runda', 'winner': 'Vinnare', 'standing': 'Tabell',
        'games': 'Matcher', 'wins': 'V', 'points': 'P', 'set_winner': 'Vem vann?',
        'champion': 'Mästare:', 'next_round': 'NÄSTA RUNDA',
        'game_over': 'Turneringen slut!', 'reset': 'Avsluta', 'not_enough': 'Minst 2 spelare',
        'bye': 'Frirond', 'rules_title': 'Instruktioner', 'ok': 'FÖRSTÅTT',
        'rules_text': 'Välj läge:\n\n• Utslagning: Vinnaren går vidare.\n• Liga: Alla möter alla. Vinst = 3 poäng.\n\nTryck på en match för att välja vinnare.',
      },
      'hr': {
        'title': 'Turnir', 'mode_ko': 'Nokaut', 'mode_league': 'Liga',
        'mode_ko_desc': 'Gubitnik ispada.', 'mode_league_desc': 'Svatko protiv svakoga.',
        'add_players': 'Sudionici', 'add_hint': 'Upiši ime', 'start': 'POKRENI',
        'round': 'Runda', 'winner': 'Pobjednik', 'standing': 'Ljestvica',
        'games': 'Utakmice', 'wins': 'P', 'points': 'Bod', 'set_winner': 'Tko je pobijedio?',
        'champion': 'Prvak:', 'next_round': 'SLJEDEĆA RUNDA',
        'game_over': 'Turnir završen!', 'reset': 'Izlaz', 'not_enough': 'Min. 2 igrača',
        'bye': 'Slobodan', 'rules_title': 'Upute', 'ok': 'RAZUMIJEM',
        'rules_text': 'Odaberite način:\n\n• Nokaut: Pobjednik ide dalje.\n• Liga: Svatko protiv svakoga. Pobjeda = 3 boda.\n\nDodirnite utakmicu za odabir pobjednika.',
      },
      'ru': {
        'title': 'Турнир', 'mode_ko': 'На вылет', 'mode_league': 'Лига',
        'mode_ko_desc': 'Проигравший выбывает.', 'mode_league_desc': 'Все против всех.',
        'add_players': 'Участники', 'add_hint': 'Введите имя', 'start': 'НАЧАТЬ',
        'round': 'Раунд', 'winner': 'Победитель', 'standing': 'Таблица',
        'games': 'Игры', 'wins': 'В', 'points': 'Очк', 'set_winner': 'Кто победил?',
        'champion': 'Чемпион:', 'next_round': 'СЛЕД. РАУНД',
        'game_over': 'Турнир окончен!', 'reset': 'Выйти', 'not_enough': 'Мин. 2 игрока',
        'bye': 'Пропуск', 'rules_title': 'Инструкции', 'ok': 'ПОНЯТНО',
        'rules_text': 'Выберите режим:\n\n• На вылет: Победитель проходит дальше.\n• Лига: Все против всех. Победа = 3 очка.\n\nНажмите на матч, чтобы выбрать победителя.',
      },
      'ja': {
        'title': 'トーナメント', 'mode_ko': '勝ち抜き戦', 'mode_league': 'リーグ戦',
        'mode_ko_desc': '敗者は脱落します。', 'mode_league_desc': '総当たり戦です。',
        'add_players': '参加者', 'add_hint': '名前を入力', 'start': '開始',
        'round': 'ラウンド', 'winner': '勝者', 'standing': '順位表',
        'games': '試合', 'wins': '勝', 'points': '点', 'set_winner': '勝者は？',
        'champion': '優勝:', 'next_round': '次のラウンド',
        'game_over': '大会終了！', 'reset': '終了', 'not_enough': '2人以上必要',
        'bye': '不戦勝', 'rules_title': '遊び方', 'ok': '了解',
        'rules_text': 'モードを選択:\n\n• 勝ち抜き: 勝者が次に進みます。\n• リーグ: 総当たり戦。勝利 = 3点。\n\n試合をタップして勝者を選んでください。',
      },
      'ko': {
        'title': '토너먼트', 'mode_ko': '노크아웃', 'mode_league': '리그',
        'mode_ko_desc': '패자는 탈락합니다.', 'mode_league_desc': '모두와 대결합니다.',
        'add_players': '참가자', 'add_hint': '이름 입력', 'start': '시작',
        'round': '라운드', 'winner': '승자', 'standing': '순위',
        'games': '경기', 'wins': '승', 'points': '점', 'set_winner': '누가 이겼나요?',
        'champion': '우승:', 'next_round': '다음 라운드',
        'game_over': '대회 종료!', 'reset': '종료', 'not_enough': '최소 2명 필요',
        'bye': '부전승', 'rules_title': '설명', 'ok': '확인',
        'rules_text': '모드 선택:\n\n• 노크아웃: 승자가 진출합니다.\n• 리그: 모두와 대결. 승리 = 3점.\n\n경기를 탭하여 승자를 선택하세요.',
      },
      'zh': {
        'title': '锦标赛', 'mode_ko': '淘汰赛', 'mode_league': '联赛',
        'mode_ko_desc': '输者淘汰。', 'mode_league_desc': '循环赛。',
        'add_players': '参赛者', 'add_hint': '输入名字', 'start': '开始',
        'round': '轮次', 'winner': '获胜者', 'standing': '积分榜',
        'games': '比赛', 'wins': '胜', 'points': '分', 'set_winner': '谁赢了？',
        'champion': '冠军:', 'next_round': '下一轮',
        'game_over': '比赛结束！', 'reset': '退出', 'not_enough': '至少2人',
        'bye': '轮空', 'rules_title': '说明', 'ok': '明白了',
        'rules_text': '选择模式：\n\n• 淘汰赛：胜者晋级。\n• 联赛：循环赛。胜利 = 3分。\n\n点击比赛选择获胜者。',
      },
      'hi': {
        'title': 'टूर्नामेंट', 'mode_ko': 'नॉकआउट', 'mode_league': 'लीग',
        'mode_ko_desc': 'हारने वाला बाहर।', 'mode_league_desc': 'सभी एक दूसरे से खेलते हैं।',
        'add_players': 'प्रतिभागी', 'add_hint': 'नाम दर्ज करें', 'start': 'शुरू करें',
        'round': 'दौर', 'winner': 'विजेता', 'standing': 'अंक तालिका',
        'games': 'मैच', 'wins': 'जीत', 'points': 'अंक', 'set_winner': 'कौन जीता?',
        'champion': 'विजेता:', 'next_round': 'अगला दौर',
        'game_over': 'टूर्नामेंट समाप्त!', 'reset': 'बाहर निकलें', 'not_enough': 'कम से कम 2 खिलाड़ी',
        'bye': 'बाई', 'rules_title': 'निर्देश', 'ok': 'समझ गया',
        'rules_text': 'मोड चुनें:\n\n• नॉकआउट: विजेता आगे बढ़ता है।\n• लीग: राउंड रॉबिन। जीत = 3 अंक।\n\nविजेता चुनने के लिए मैच पर टैप करें।',
      },
      'bn': {
        'title': 'টুর্নামেন্ট', 'mode_ko': 'নকআউট', 'mode_league': 'লিগ',
        'mode_ko_desc': 'হেরে গেলে বাদ।', 'mode_league_desc': 'সবাই সবার সাথে খেলে।',
        'add_players': 'অংশগ্রহণকারী', 'add_hint': 'নাম লিখুন', 'start': 'শুরু',
        'round': 'রাউন্ড', 'winner': 'বিজয়ী', 'standing': 'পয়েন্ট টেবিল',
        'games': 'ম্যাচ', 'wins': 'জয়', 'points': 'পয়েন্ট', 'set_winner': 'কে জিতেছে?',
        'champion': 'চ্যাম্পিয়ন:', 'next_round': 'পরবর্তী রাউন্ড',
        'game_over': 'টুর্নামেন্ট শেষ!', 'reset': 'প্রস্থান', 'not_enough': 'কমপক্ষে ২ জন খেলোয়াড়',
        'bye': 'বাই', 'rules_title': 'নির্দেশনা', 'ok': 'বুঝেছি',
        'rules_text': 'মোড নির্বাচন করুন:\n\n• নকআউট: বিজয়ী এগিয়ে যায়।\n• লিগ: রাউন্ড রবিন। জয় = ৩ পয়েন্ট।\n\nবিজয়ী নির্বাচন করতে ম্যাচে ট্যাপ করুন।',
      },
      'ar': {
        'title': 'بطولة', 'mode_ko': 'خروج المغلوب', 'mode_league': 'دوري',
        'mode_ko_desc': 'الخاسر يخرج.', 'mode_league_desc': 'الكل يلعب ضد الكل.',
        'add_players': 'المشاركين', 'add_hint': 'أدخل الاسم', 'start': 'بدء',
        'round': 'جولة', 'winner': 'الفائز', 'standing': 'الترتيب',
        'games': 'مباريات', 'wins': 'فوز', 'points': 'نقاط', 'set_winner': 'من فاز؟',
        'champion': 'البطل:', 'next_round': 'الجولة التالية',
        'game_over': 'انتهت البطولة!', 'reset': 'خروج', 'not_enough': 'مطلوب لاعبين 2+',
        'bye': 'تأهل تلقائي', 'rules_title': 'تعليمات', 'ok': 'فهمت',
        'rules_text': 'اختر الوضع:\n\n• خروج المغلوب: الفائز يتأهل.\n• دوري: الكل ضد الكل. الفوز = 3 نقاط.\n\nاضغط على المباراة لاختيار الفائز.',
      },
    };
    if (dictionary.containsKey(_currentLang) && dictionary[_currentLang]!.containsKey(key)) {
      return dictionary[_currentLang]![key]!;
    }
    return dictionary['en']![key] ?? key;
  }

  // --- LOGIC: SETUP ---

  void _addPlayer() {
    if (_nameController.text.trim().isNotEmpty) {
      setState(() {
        _playerNames.add(_nameController.text.trim());
        _nameController.clear();
      });
    }
  }

  void _startTournament() {
    if (_playerNames.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('not_enough'))));
      return;
    }
    FocusScope.of(context).unfocus();

    setState(() {
      _step = 2;
      _currentRound = 1;
      _matches.clear();

      if (_selectedMode == TournamentType.knockout) {
        _generateKnockoutRound(_playerNames);
      } else {
        _generateLeagueSchedule();
        _calculateLeagueTable();
      }
    });
  }

  // --- LOGIC: KNOCKOUT ---

  void _generateKnockoutRound(List<String> participants) {
    participants.shuffle();

    int matchCount = participants.length ~/ 2;
    for (int i = 0; i < matchCount; i++) {
      _matches.add(TournamentMatch(
        id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
        player1: participants[i * 2],
        player2: participants[(i * 2) + 1],
        round: _currentRound,
      ));
    }

    if (participants.length.isOdd) {
      var m = TournamentMatch(
          id: "bye_${_currentRound}",
          player1: participants.last,
          player2: _t('bye'),
          round: _currentRound,
          winner: participants.last
      );
      _matches.add(m);
    }
  }

  void _generateNextRound() {
    List<String> winners = _matches
        .where((m) => m.round == _currentRound && m.winner != null)
        .map((m) => m.winner!)
        .toList();

    if (winners.length < 2) return;

    setState(() {
      _currentRound++;
      _generateKnockoutRound(winners);
    });
  }

  // --- LOGIC: LEAGUE ---

  void _generateLeagueSchedule() {
    for (int i = 0; i < _playerNames.length; i++) {
      for (int j = i + 1; j < _playerNames.length; j++) {
        _matches.add(TournamentMatch(
          id: "$i-$j",
          player1: _playerNames[i],
          player2: _playerNames[j],
          round: 1,
        ));
      }
    }
    _matches.shuffle();
  }

  void _calculateLeagueTable() {
    Map<String, LeaguePlayer> stats = {};
    for (var name in _playerNames) {
      stats[name] = LeaguePlayer(name: name);
    }

    for (var m in _matches) {
      if (m.winner != null) {
        stats[m.winner]!.wins++;
        stats[m.winner]!.points += 3;
        String loser = m.winner == m.player1 ? m.player2 : m.player1;
        stats[loser]!.losses++;
      }
    }

    _leagueTable = stats.values.toList();
    _leagueTable.sort((a, b) {
      int cmp = b.points.compareTo(a.points);
      if (cmp != 0) return cmp;
      return b.wins.compareTo(a.wins);
    });
  }

  void _setMatchWinner(TournamentMatch match, String winnerName) {
    setState(() {
      match.winner = winnerName;
      if (_selectedMode == TournamentType.league) {
        _calculateLeagueTable();
      }
    });
  }

  void _showRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        title: Text(_t('rules_title'), style: TextStyle(color: primaryColor)),
        content: Text(_t('rules_text'), style: const TextStyle(color: Colors.white70, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('ok'), style: TextStyle(color: primaryColor)),
          )
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
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showRules,
          ),
        ],
      ),
      body: _buildCurrentStep(),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0: return _buildModeSelection();
      case 1: return _buildPlayerEntry();
      case 2: return _buildTournamentView();
      default: return Container();
    }
  }

  Widget _buildModeSelection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _modeCard(Icons.account_tree, _t('mode_ko'), _t('mode_ko_desc'), TournamentType.knockout),
            const SizedBox(height: 20),
            _modeCard(Icons.grid_view, _t('mode_league'), _t('mode_league_desc'), TournamentType.league),
          ],
        ),
      ),
    );
  }

  Widget _modeCard(IconData icon, String title, String subtitle, TournamentType type) {
    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() {
          _selectedMode = type;
          _step = 1;
        }),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle),
                child: Icon(icon, color: primaryColor, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerEntry() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(_t('add_players'), style: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _t('add_hint'),
                        filled: true,
                        fillColor: surfaceColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _addPlayer(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: _addPlayer,
                    style: IconButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.all(12)),
                    icon: const Icon(Icons.add, color: Colors.black),
                  )
                ],
              ),
              const SizedBox(height: 20),
              ..._playerNames.asMap().entries.map((entry) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${entry.key + 1}. ${entry.value}", style: const TextStyle(color: Colors.white, fontSize: 16)),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey.shade600),
                      onPressed: () => setState(() => _playerNames.removeAt(entry.key)),
                    )
                  ],
                ),
              )),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: _startTournament,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: Text(_t('start'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildTournamentView() {
    if (_selectedMode == TournamentType.knockout) {
      return _buildKnockoutView();
    } else {
      return _buildLeagueView();
    }
  }

  Widget _buildKnockoutView() {
    var roundMatches = _matches.where((m) => m.round == _currentRound).toList();
    bool roundFinished = roundMatches.every((m) => m.winner != null);
    bool isFinale = roundMatches.length == 1;
    bool tournamentOver = isFinale && roundFinished;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            tournamentOver ? _t('game_over') : "${_t('round')} $_currentRound",
            style: TextStyle(color: primaryColor, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),

        if (tournamentOver)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, size: 100, color: Colors.white),
                  const SizedBox(height: 20),
                  Text(_t('champion'), style: const TextStyle(color: Colors.grey, fontSize: 18)),
                  Text(roundMatches.first.winner ?? "", style: TextStyle(color: primaryColor, fontSize: 40, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 50),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: surfaceColor),
                    child: Text(_t('reset'), style: const TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: roundMatches.length,
              itemBuilder: (context, index) {
                return _buildMatchCard(roundMatches[index]);
              },
            ),
          ),

        if (!tournamentOver && roundFinished)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: _generateNextRound,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(_t('next_round'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildLeagueView() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            indicatorColor: primaryColor,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: _t('games')),
              Tab(text: _t('standing')),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _matches.length,
                  itemBuilder: (context, index) => _buildMatchCard(_matches[index]),
                ),
                ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _leagueTable.length,
                  itemBuilder: (context, index) {
                    final p = _leagueTable[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                        border: index == 0 ? Border.all(color: primaryColor) : null,
                      ),
                      child: Row(
                        children: [
                          Text("${index + 1}.", style: TextStyle(color: index == 0 ? primaryColor : Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 15),
                          Expanded(child: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                          Column(
                            children: [
                              Text("${p.wins}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text(_t('wins'), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Column(
                            children: [
                              Text("${p.points}", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
                              Text(_t('points'), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(TournamentMatch match) {
    bool isFinished = match.winner != null;

    return Card(
      color: surfaceColor,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: isFinished ? BorderSide(color: primaryColor.withOpacity(0.5)) : BorderSide.none
      ),
      child: InkWell(
        onTap: isFinished ? null : () => _showWinnerDialog(match),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                    match.player1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: match.winner == match.player1 ? primaryColor : Colors.white,
                        fontWeight: match.winner == match.player1 ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16
                    )
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: isFinished
                    ? Icon(Icons.check_circle, color: primaryColor)
                    : const Text("VS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Text(
                    match.player2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: match.winner == match.player2 ? primaryColor : Colors.white,
                        fontWeight: match.winner == match.player2 ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16
                    )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWinnerDialog(TournamentMatch match) {
    if(match.player2 == _t('bye')) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        title: Text(_t('set_winner'), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(match.player1, style: const TextStyle(color: Colors.white, fontSize: 18)),
              leading: Icon(Icons.person, color: primaryColor),
              onTap: () {
                _setMatchWinner(match, match.player1);
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.grey),
            ListTile(
              title: Text(match.player2, style: const TextStyle(color: Colors.white, fontSize: 18)),
              leading: Icon(Icons.person, color: primaryColor),
              onTap: () {
                _setMatchWinner(match, match.player2);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}