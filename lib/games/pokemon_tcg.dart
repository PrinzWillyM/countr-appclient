import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/game_persistence.dart';

// --- DATA MODELS ---
enum SpecialCondition { none, asleep, paralyzed, confused }

class PokeSlot {
  int damage = 0;
  bool isPoisoned = false;
  bool isBurned = false;
  SpecialCondition condition = SpecialCondition.none;

  PokeSlot();

  void applyToken(String token) {
    if (token == '10') damage += 10;
    if (token == '50') damage += 50;
    if (token == '100') damage += 100;
    if (token == 'P') isPoisoned = true;
    if (token == 'B') isBurned = true;

    // Asleep, Paralyzed, Confused überschreiben sich gegenseitig
    if (token == 'SLP') condition = SpecialCondition.asleep;
    if (token == 'PAR') condition = SpecialCondition.paralyzed;
    if (token == 'CNF') condition = SpecialCondition.confused;
  }

  void clearAll() {
    damage = 0;
    clearConditions();
  }

  // Beim Wechsel auf die Bank verliert ein Pokémon alle Speziellen Zustände (inkl. Gift & Verbrennung)
  void clearConditions() {
    isPoisoned = false;
    isBurned = false;
    condition = SpecialCondition.none;
  }

  static bool isDamageToken(String token) => token == '10' || token == '50' || token == '100';

  Map<String, dynamic> toJson() => {
        'damage': damage,
        'isPoisoned': isPoisoned,
        'isBurned': isBurned,
        'condition': condition.name,
      };

  factory PokeSlot.fromJson(Map<String, dynamic> json) {
    final slot = PokeSlot();
    slot.damage = json['damage'] as int? ?? 0;
    slot.isPoisoned = json['isPoisoned'] as bool? ?? false;
    slot.isBurned = json['isBurned'] as bool? ?? false;
    slot.condition = SpecialCondition.values.firstWhere(
      (c) => c.name == json['condition'],
      orElse: () => SpecialCondition.none,
    );
    return slot;
  }
}

class PokePlayer {
  String name;
  int prizes = 6;
  bool gxUsed = false;
  bool vstarUsed = false;
  bool supporterUsed = false;
  bool retreatUsed = false;
  PokeSlot active = PokeSlot();
  List<PokeSlot> bench = List.generate(5, (_) => PokeSlot());

  PokePlayer(this.name);

  void endTurn() {
    supporterUsed = false;
    retreatUsed = false;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'prizes': prizes,
        'gxUsed': gxUsed,
        'vstarUsed': vstarUsed,
        'supporterUsed': supporterUsed,
        'retreatUsed': retreatUsed,
        'active': active.toJson(),
        'bench': bench.map((s) => s.toJson()).toList(),
      };

  factory PokePlayer.fromJson(Map<String, dynamic> json) {
    final player = PokePlayer(json['name'] as String);
    player.prizes = json['prizes'] as int? ?? 6;
    player.gxUsed = json['gxUsed'] as bool? ?? false;
    player.vstarUsed = json['vstarUsed'] as bool? ?? false;
    player.supporterUsed = json['supporterUsed'] as bool? ?? false;
    player.retreatUsed = json['retreatUsed'] as bool? ?? false;
    player.active = PokeSlot.fromJson(Map<String, dynamic>.from(json['active'] as Map));
    player.bench = (json['bench'] as List<dynamic>)
        .map((s) => PokeSlot.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList();
    return player;
  }
}

// --- WIDGET ---
class PokemonTCGGame extends StatefulWidget {
  final Color? themeColor;
  final bool resume;

  const PokemonTCGGame({super.key, this.themeColor, this.resume = false});

  @override
  State<PokemonTCGGame> createState() => _PokemonTCGGameState();
}

class _PokemonTCGGameState extends State<PokemonTCGGame> {
  static const String gameId = 'game_title_pkm';

  // --- STYLE ---
  Color get primaryColor => widget.themeColor ?? const Color(0xFFEBCB63); // Pokemon Gelb
  final Color bgColor = const Color(0xFF222629);
  final Color surfaceColor = const Color(0xFF30363B);
  final Color activeColor = const Color(0xFF3E444A);
  final Color damageColor = const Color(0xFFEB6B6B);
  final Color poisonColor = const Color(0xFF9B59B6);
  final Color burnColor = const Color(0xFFE67E22);
  final Color statusColor = const Color(0xFF3498DB);
  final Color successColor = const Color(0xFF27AE60);

  // --- STATE ---
  // Sprache: immer live vom globalen App-Status gelesen (reaktiv auf Sprachwechsel)
  String get _currentLang => appLocaleNotifier.value.languageCode;
  // Direkt initialisiert, damit der erste Frame beim Fortsetzen (asynchrones Laden) nicht crasht
  late PokePlayer player1 = PokePlayer(_t('you'));
  late PokePlayer player2 = PokePlayer(_t('opponent'));

  final TextEditingController _renameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.resume) {
      _loadSavedState();
    } else {
      _persist();
    }
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedState() async {
    final saved = await GamePersistence.load(gameId);
    if (!mounted) return;
    if (saved == null) {
      _resetGame();
      return;
    }
    setState(() {
      player1 = PokePlayer.fromJson(Map<String, dynamic>.from(saved['player1'] as Map));
      player2 = PokePlayer.fromJson(Map<String, dynamic>.from(saved['player2'] as Map));
    });
  }

  void _persist() {
    GamePersistence.save(gameId, {
      'player1': player1.toJson(),
      'player2': player2.toJson(),
    });
  }

  void _resetGame() {
    setState(() {
      player1 = PokePlayer(_t('you'));
      player2 = PokePlayer(_t('opponent'));
    });
    _persist();
  }

  // --- TRANSLATIONS ---
  String _t(String key) {
    const Map<String, Map<String, String>> dictionary = {
      'de': {
        'title': 'Pokémon TCG', 'rules': 'Anleitung', 'ok': 'VERSTANDEN',
        'you': 'Du', 'opponent': 'Gegner', 'prizes': 'Preise',
        'active': 'Aktiv', 'bench': 'Bank', 'clear': 'Leeren',
        'rename_title': 'Name ändern', 'cancel': 'ABBRECHEN', 'save': 'SPEICHERN',
        'swap_active': 'Einwechseln', 'manage_prizes': 'Preiskarten', 'back': 'ZURÜCK',
        'supporter': 'Supporter', 'retreat': 'Rückzug', 'end_turn': 'Zug Beenden', 'turn': 'Zug', 'player_wins': '{name} gewinnt!',
        'rules_text': 'Der perfekte TCG Begleiter:\n\n• Drag & Drop: Ziehe Schadens- oder Statusmarken aus der Mitte auf ein Pokémon.\n• Bearbeiten: Tippe auf ein Pokémon, um Marken anzupassen.\n• Einwechseln: Tippe auf ein Bank-Pokémon, um es mit dem Aktiven zu tauschen.\n• Once-per-Game: Tippe auf [GX] / [VSTAR], um sie zu verbrauchen.\n• Zug Aktionen: Markiere gespielte Unterstützer oder genutzten Rückzug.',
      },
      'en': {
        'title': 'Pokémon TCG', 'rules': 'Rules', 'ok': 'GOT IT',
        'you': 'You', 'opponent': 'Opponent', 'prizes': 'Prizes',
        'active': 'Active', 'bench': 'Bench', 'clear': 'Clear All',
        'rename_title': 'Rename', 'cancel': 'CANCEL', 'save': 'SAVE',
        'swap_active': 'Switch', 'manage_prizes': 'Prizes', 'back': 'BACK',
        'supporter': 'Supporter', 'retreat': 'Retreat', 'end_turn': 'End Turn', 'turn': 'Turn', 'player_wins': '{name} wins!',
        'rules_text': 'The perfect TCG companion:\n\n• Drag & Drop: Drag damage or status tokens from the center onto a Pokémon.\n• Edit: Tap a Pokémon to adjust counters.\n• Switch: Tap a benched Pokémon to switch it with the active one.\n• Once-per-Game: Tap [GX] / [VSTAR] to mark them as used.\n• Turn Actions: Track played supporters or used retreats.',
      },
      'fr': {
        'title': 'Pokémon TCG', 'rules': 'Règles', 'ok': 'COMPRIS', 'you': 'Toi', 'opponent': 'Adversaire', 'prizes': 'Prix', 'active': 'Actif', 'bench': 'Banc', 'clear': 'Vider', 'rename_title': 'Renommer', 'cancel': 'ANNULER', 'save': 'SAUVER', 'swap_active': 'Remplacer', 'manage_prizes': 'Prix', 'back': 'RETOUR', 'supporter': 'Supporter', 'retreat': 'Retraite', 'end_turn': 'Fin de tour', 'turn': 'Tour', 'player_wins': '{name} gagne !', 'rules_text': 'Le compagnon TCG parfait :\n\n• Glisser-déposer : Glissez les marqueurs de dégâts ou de statut du centre vers un Pokémon.\n• Modifier : Appuyez sur un Pokémon pour ajuster les marqueurs.\n• Remplacer : Appuyez sur un Pokémon du banc pour l\'échanger avec l\'actif.\n• Une fois par partie : Appuyez sur [GX] / [VSTAR] pour les marquer comme utilisés.\n• Actions de tour : Suivez les supporters joués ou les retraites utilisées.'
      },
      'it': { 'title': 'Pokémon TCG', 'rules': 'Regole', 'ok': 'CAPITO', 'you': 'Tu', 'opponent': 'Avversario', 'prizes': 'Premi', 'active': 'Attivo', 'bench': 'Panchina', 'clear': 'Svuota', 'swap_active': 'Scambia', 'manage_prizes': 'Premi', 'back': 'INDIETRO', 'rename_title': 'Rinomina', 'cancel': 'ANNULLA', 'save': 'SALVA', 'supporter': 'Aiuto', 'retreat': 'Ritirata', 'end_turn': 'Fine Turno', 'turn': 'Turno', 'player_wins': '{name} vince!', 'rules_text': 'Il compagno perfetto per il TCG:\n\n• Trascina e rilascia: Trascina i segnalini di danno o stato dal centro su un Pokémon.\n• Modifica: Tocca un Pokémon per regolare i segnalini.\n• Scambia: Tocca un Pokémon in panchina per scambiarlo con quello attivo.\n• Una volta per partita: Tocca [GX] / [VSTAR] per segnarli come usati.\n• Azioni di turno: Tieni traccia dei supporter giocati o delle ritirate usate.' },
      'es': { 'title': 'Pokémon TCG', 'rules': 'Reglas', 'ok': 'ENTENDIDO', 'you': 'Tú', 'opponent': 'Rival', 'prizes': 'Premios', 'active': 'Activo', 'bench': 'Banca', 'clear': 'Limpiar', 'swap_active': 'Cambiar', 'manage_prizes': 'Premios', 'back': 'VOLVER', 'rename_title': 'Renombrar', 'cancel': 'CANCELAR', 'save': 'GUARDAR', 'supporter': 'Partidario', 'retreat': 'Retirada', 'end_turn': 'Fin de turno', 'turn': 'Turno', 'player_wins': '¡{name} gana!', 'rules_text': 'El compañero perfecto para el TCG:\n\n• Arrastrar y soltar: Arrastra los contadores de daño o estado desde el centro hacia un Pokémon.\n• Editar: Toca un Pokémon para ajustar los contadores.\n• Cambiar: Toca un Pokémon en la banca para intercambiarlo con el activo.\n• Una vez por partida: Toca [GX] / [VSTAR] para marcarlos como usados.\n• Acciones de turno: Registra los partidarios jugados o las retiradas usadas.' },
      'pt': { 'title': 'Pokémon TCG', 'rules': 'Regras', 'ok': 'ENTENDIDO', 'you': 'Você', 'opponent': 'Oponente', 'prizes': 'Prêmios', 'active': 'Ativo', 'bench': 'Banco', 'clear': 'Limpar', 'swap_active': 'Trocar', 'manage_prizes': 'Prêmios', 'back': 'VOLTAR', 'rename_title': 'Renomear', 'cancel': 'CANCELAR', 'save': 'SALVAR', 'supporter': 'Apoiador', 'retreat': 'Recuar', 'end_turn': 'Fim do turno', 'turn': 'Turno', 'player_wins': '{name} venceu!', 'rules_text': 'O companheiro perfeito para o TCG:\n\n• Arrastar e soltar: Arraste os marcadores de dano ou status do centro para um Pokémon.\n• Editar: Toque em um Pokémon para ajustar os marcadores.\n• Trocar: Toque em um Pokémon no banco para trocá-lo com o ativo.\n• Uma vez por partida: Toque em [GX] / [VSTAR] para marcá-los como usados.\n• Ações de turno: Acompanhe os apoiadores jogados ou recuos usados.' },
      'nl': { 'title': 'Pokémon TCG', 'rules': 'Regels', 'ok': 'BEGREPEN', 'you': 'Jij', 'opponent': 'Tegenstander', 'prizes': 'Prijzen', 'active': 'Actief', 'bench': 'Bank', 'clear': 'Wissen', 'swap_active': 'Wissel', 'manage_prizes': 'Prijzen', 'back': 'TERUG', 'rename_title': 'Wijzigen', 'cancel': 'ANNULEREN', 'save': 'OPSLAAN', 'supporter': 'Supporter', 'retreat': 'Terugtrekken', 'end_turn': 'Einde beurt', 'turn': 'Beurt', 'player_wins': '{name} wint!', 'rules_text': 'De perfecte TCG-metgezel:\n\n• Slepen en neerzetten: Sleep schade- of statusmarkers vanuit het midden naar een Pokémon.\n• Bewerken: Tik op een Pokémon om markers aan te passen.\n• Wisselen: Tik op een Pokémon op de bank om deze te wisselen met de actieve.\n• Eén keer per potje: Tik op [GX] / [VSTAR] om ze als gebruikt te markeren.\n• Beurtacties: Houd bij welke supporters zijn gespeeld en welke terugtrekkingen zijn gebruikt.' },
      'pl': { 'title': 'Pokémon TCG', 'rules': 'Zasady', 'ok': 'ZROZUMIAŁEM', 'you': 'Ty', 'opponent': 'Przeciwnik', 'prizes': 'Nagrody', 'active': 'Aktywny', 'bench': 'Ławka', 'clear': 'Wyczyść', 'swap_active': 'Zmień', 'manage_prizes': 'Nagrody', 'back': 'WRÓĆ', 'rename_title': 'Zmień nazwę', 'cancel': 'ANULUJ', 'save': 'ZAPISZ', 'supporter': 'Wsparcie', 'retreat': 'Wycofanie', 'end_turn': 'Koniec tury', 'turn': 'Tura', 'player_wins': '{name} wygrywa!', 'rules_text': 'Idealny towarzysz TCG:\n\n• Przeciągnij i upuść: Przeciągnij znaczniki obrażeń lub statusu ze środka na Pokémona.\n• Edytuj: Dotknij Pokémona, aby dostosować znaczniki.\n• Zmień: Dotknij Pokémona na ławce, aby zamienić go z aktywnym.\n• Raz na grę: Dotknij [GX] / [VSTAR], aby oznaczyć jako użyte.\n• Akcje tury: Śledź zagranych supporterów i użyte wycofania.' },
      'tr': { 'title': 'Pokémon TCG', 'rules': 'Kurallar', 'ok': 'ANLADIM', 'you': 'Sen', 'opponent': 'Rakip', 'prizes': 'Ödüller', 'active': 'Aktif', 'bench': 'Yedek', 'clear': 'Temizle', 'swap_active': 'Değiştir', 'manage_prizes': 'Ödüller', 'back': 'GERİ', 'rename_title': 'İsim Değiştir', 'cancel': 'İPTAL', 'save': 'KAYDET', 'supporter': 'Destekçi', 'retreat': 'Geri Çekil', 'end_turn': 'Turu Bitir', 'turn': 'Tur', 'player_wins': '{name} kazandı!', 'rules_text': 'Mükemmel TCG yoldaşı:\n\n• Sürükle & Bırak: Hasar veya durum jetonlarını ortadan bir Pokémon\'a sürükleyin.\n• Düzenle: Sayaçları ayarlamak için bir Pokémon\'a dokunun.\n• Değiştir: Aktif olanla değiştirmek için yedekteki bir Pokémon\'a dokunun.\n• Oyun başına bir kez: Kullanıldı olarak işaretlemek için [GX] / [VSTAR]\'a dokunun.\n• Tur aksiyonları: Oynanan destekçileri ve kullanılan geri çekilmeleri takip edin.' },
      'id': { 'title': 'Pokémon TCG', 'rules': 'Aturan', 'ok': 'MENGERTI', 'you': 'Kamu', 'opponent': 'Lawan', 'prizes': 'Hadiah', 'active': 'Aktif', 'bench': 'Cadangan', 'clear': 'Bersihkan', 'swap_active': 'Tukar', 'manage_prizes': 'Hadiah', 'back': 'KEMBALI', 'rename_title': 'Ubah Nama', 'cancel': 'BATAL', 'save': 'SIMPAN', 'supporter': 'Pendukung', 'retreat': 'Mundur', 'end_turn': 'Akhiri Giliran', 'turn': 'Giliran', 'player_wins': '{name} menang!', 'rules_text': 'Pendamping TCG yang sempurna:\n\n• Seret & Lepas: Seret token kerusakan atau status dari tengah ke Pokémon.\n• Edit: Ketuk Pokémon untuk menyesuaikan penghitung.\n• Tukar: Ketuk Pokémon di bangku cadangan untuk menukarnya dengan yang aktif.\n• Sekali per game: Ketuk [GX] / [VSTAR] untuk menandainya sebagai terpakai.\n• Aksi giliran: Lacak pendukung yang dimainkan atau mundur yang digunakan.' },
      'sv': { 'title': 'Pokémon TCG', 'rules': 'Regler', 'ok': 'FÖRSTÅTT', 'you': 'Du', 'opponent': 'Motståndare', 'prizes': 'Priser', 'active': 'Aktiv', 'bench': 'Bänk', 'clear': 'Rensa', 'swap_active': 'Byt', 'manage_prizes': 'Priser', 'back': 'TILLBAKA', 'rename_title': 'Byt namn', 'cancel': 'AVBRYT', 'save': 'SPARA', 'supporter': 'Supporter', 'retreat': 'Reträtt', 'end_turn': 'Avsluta tur', 'turn': 'Tur', 'player_wins': '{name} vinner!', 'rules_text': 'Den perfekta TCG-följeslagaren:\n\n• Dra och släpp: Dra skade- eller statusmarkörer från mitten till en Pokémon.\n• Redigera: Tryck på en Pokémon för att justera markörer.\n• Byt: Tryck på en Pokémon på bänken för att byta den mot den aktiva.\n• En gång per match: Tryck på [GX] / [VSTAR] för att markera dem som använda.\n• Turåtgärder: Håll koll på spelade supportrar och använda reträtter.' },
      'hr': { 'title': 'Pokémon TCG', 'rules': 'Pravila', 'ok': 'RAZUMIJEM', 'you': 'Ti', 'opponent': 'Protivnik', 'prizes': 'Nagrade', 'active': 'Aktivni', 'bench': 'Klupa', 'clear': 'Očisti', 'swap_active': 'Zamijeni', 'manage_prizes': 'Nagrade', 'back': 'NATRAG', 'rename_title': 'Promijeni ime', 'cancel': 'ODUSTANI', 'save': 'SPREMI', 'supporter': 'Podrška', 'retreat': 'Povlačenje', 'end_turn': 'Kraj Poteza', 'turn': 'Potez', 'player_wins': '{name} pobjeđuje!', 'rules_text': 'Savršeni TCG pratitelj:\n\n• Povuci i ispusti: Povuci žetone oštećenja ili statusa iz sredine na Pokémona.\n• Uredi: Dodirni Pokémona za prilagodbu žetona.\n• Zamijeni: Dodirni Pokémona na klupi da ga zamijeniš s aktivnim.\n• Jednom po igri: Dodirni [GX] / [VSTAR] da ih označiš kao iskorištene.\n• Radnje poteza: Prati odigrane podržavatelje i iskorištena povlačenja.' },
      'ru': { 'title': 'Pokémon TCG', 'rules': 'Правила', 'ok': 'ПОНЯТНО', 'you': 'Вы', 'opponent': 'Соперник', 'prizes': 'Призы', 'active': 'Активный', 'bench': 'Скамья', 'clear': 'Очистить', 'swap_active': 'Сменить', 'manage_prizes': 'Призы', 'back': 'НАЗАД', 'rename_title': 'Переименовать', 'cancel': 'ОТМЕНА', 'save': 'СОХРАНИТЬ', 'supporter': 'Поддержка', 'retreat': 'Отступление', 'end_turn': 'Конец хода', 'turn': 'Ход', 'player_wins': '{name} побеждает!', 'rules_text': 'Идеальный компаньон для ККИ:\n\n• Перетаскивание: Перетащите жетоны урона или статуса из центра на покемона.\n• Редактирование: Нажмите на покемона, чтобы настроить счётчики.\n• Замена: Нажмите на покемона на скамейке, чтобы поменять его местами с активным.\n• Один раз за игру: Нажмите [GX] / [VSTAR], чтобы отметить их как использованные.\n• Действия хода: Отслеживайте сыгранных саппортов и использованные отступления.' },
      'ja': { 'title': 'Pokémon TCG', 'rules': 'ルール', 'ok': '了解', 'you': 'あなた', 'opponent': '相手', 'prizes': 'サイド', 'active': 'バトル場', 'bench': 'ベンチ', 'clear': 'クリア', 'swap_active': '入れ替え', 'manage_prizes': 'サイド', 'back': '戻る', 'rename_title': '名前を変更', 'cancel': 'キャンセル', 'save': '保存', 'supporter': 'サポート', 'retreat': 'にげる', 'end_turn': 'ターン終了', 'turn': 'ターン', 'player_wins': '{name}の勝ち！', 'rules_text': '最高のTCGパートナー：\n\n• ドラッグ＆ドロップ：中央のダメージ・状態マーカーをポケモンにドラッグします。\n• 編集：ポケモンをタップしてマーカーを調整します。\n• 交代：ベンチのポケモンをタップしてバトル場のポケモンと入れ替えます。\n• 1試合1回：[GX]／[VSTAR]をタップして使用済みにします。\n• ターンの操作：使用したサポートやにげるを記録します。' },
      'ko': { 'title': 'Pokémon TCG', 'rules': '규칙', 'ok': '확인', 'you': '당신', 'opponent': '상대방', 'prizes': '프라이즈', 'active': '배틀필드', 'bench': '벤치', 'clear': '지우기', 'swap_active': '교체', 'manage_prizes': '프라이즈', 'back': '뒤로', 'rename_title': '이름 변경', 'cancel': '취소', 'save': '저장', 'supporter': '서포터', 'retreat': '후퇴', 'end_turn': '턴 종료', 'turn': '턴', 'player_wins': '{name} 승리!', 'rules_text': '완벽한 TCG 동반자:\n\n• 드래그 앤 드롭: 중앙의 데미지 또는 상태 토큰을 포켓몬 위로 드래그하세요.\n• 편집: 포켓몬을 탭하여 카운터를 조정하세요.\n• 교체: 벤치의 포켓몬을 탭하여 배틀필드의 포켓몬과 교체하세요.\n• 게임당 한 번: [GX] / [VSTAR]를 탭하여 사용됨으로 표시하세요.\n• 턴 액션: 사용한 서포터와 후퇴를 기록하세요.' },
      'zh': { 'title': '宝可梦 TCG', 'rules': '规则', 'ok': '明白了', 'you': '你', 'opponent': '对手', 'prizes': '奖赏卡', 'active': '出战', 'bench': '备战区', 'clear': '清除', 'swap_active': '替换', 'manage_prizes': '奖赏卡', 'back': '返回', 'rename_title': '重命名', 'cancel': '取消', 'save': '保存', 'supporter': '支援者', 'retreat': '撤退', 'end_turn': '结束回合', 'turn': '回合', 'player_wins': '{name} 获胜！', 'rules_text': '完美的集换式卡牌搭档：\n\n• 拖放：将中间的伤害或状态标记拖到宝可梦身上。\n• 编辑：点击宝可梦以调整标记。\n• 替换：点击备战区的宝可梦以与出战宝可梦互换。\n• 每场一次：点击[GX]／[VSTAR]将其标记为已使用。\n• 回合操作：记录已使用的支援者和已使用的撤退。' },
      'hi': { 'title': 'Pokémon TCG', 'rules': 'नियम', 'ok': 'समझ गया', 'you': 'आप', 'opponent': 'प्रतिद्वंद्वी', 'prizes': 'इनाम', 'active': 'सक्रिय', 'bench': 'बेंच', 'clear': 'साफ़ करें', 'swap_active': 'बदलें', 'manage_prizes': 'इनाम', 'back': 'वापस', 'rename_title': 'नाम बदलें', 'cancel': 'रद्द करें', 'save': 'सहेजें', 'supporter': 'समर्थक', 'retreat': 'पीछे हटना', 'end_turn': 'बारी समाप्त', 'turn': 'बारी', 'player_wins': '{name} जीत गया!', 'rules_text': 'परफेक्ट TCG साथी:\n\n• ड्रैग एंड ड्रॉप: बीच से डैमेज या स्टेटस टोकन को किसी पोकेमॉन पर खींचें।\n• संपादित करें: काउंटर समायोजित करने के लिए किसी पोकेमॉन पर टैप करें।\n• बदलें: बेंच के पोकेमॉन को सक्रिय पोकेमॉन से बदलने के लिए उस पर टैप करें।\n• प्रति गेम एक बार: उन्हें उपयोग किया हुआ चिह्नित करने के लिए [GX] / [VSTAR] पर टैप करें।\n• बारी की क्रियाएं: खेले गए समर्थकों और उपयोग की गई वापसी को ट्रैक करें।' },
      'bn': { 'title': 'Pokémon TCG', 'rules': 'নিয়ম', 'ok': 'বুঝেছি', 'you': 'আপনি', 'opponent': 'প্রতিপক্ষ', 'prizes': 'পুরস্কার', 'active': 'সক্রিয়', 'bench': 'বেঞ্চ', 'clear': 'পরিষ্কার', 'swap_active': 'পরিবর্তন করুন', 'manage_prizes': 'পুরস্কার', 'back': 'ফিরে যান', 'rename_title': 'নাম পরিবর্তন', 'cancel': 'বাতিল', 'save': 'সংরক্ষণ', 'supporter': 'সমর্থক', 'retreat': 'পশ্চাদপসরণ', 'end_turn': 'পালা শেষ', 'turn': 'পালা', 'player_wins': '{name} জিতেছে!', 'rules_text': 'নিখুঁত TCG সঙ্গী:\n\n• ড্র্যাগ ও ড্রপ: মাঝখান থেকে ড্যামেজ বা স্ট্যাটাস টোকেন কোনো পোকেমনের উপর টেনে আনুন।\n• সম্পাদনা: কাউন্টার সামঞ্জস্য করতে একটি পোকেমনে ট্যাপ করুন।\n• পরিবর্তন: বেঞ্চের পোকেমনকে সক্রিয়টির সাথে পরিবর্তন করতে তাতে ট্যাপ করুন।\n• প্রতি গেমে একবার: ব্যবহৃত হিসেবে চিহ্নিত করতে [GX] / [VSTAR] এ ট্যাপ করুন।\n• পালার কার্যক্রম: খেলা সমর্থক এবং ব্যবহৃত পশ্চাদপসরণ ট্র্যাক করুন।' },
    };

    if (dictionary.containsKey(_currentLang) && dictionary[_currentLang]!.containsKey(key)) {
      return dictionary[_currentLang]![key]!;
    }
    var enDict = dictionary['en']!;
    return enDict[key] ?? key;
  }

  // --- LOGIC ---

  void _showRenameDialog(PokePlayer player) {
    _renameController.text = player.name;

    void save(BuildContext dialogContext) {
      final name = _renameController.text.trim();
      if (name.isNotEmpty) {
        setState(() => player.name = name);
        _persist();
      }
      Navigator.pop(dialogContext);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: primaryColor)),
        title: Text(_t('rename_title'), style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: _renameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
          ),
          onSubmitted: (_) => save(context),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_t('cancel'), style: const TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => save(context),
            child: Text(_t('save'), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPrizeDialog(PokePlayer player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: primaryColor)),
        title: Text(_t('manage_prizes'), style: TextStyle(color: primaryColor), textAlign: TextAlign.center),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.remove, color: Colors.white, size: 30),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  final hadPrizes = player.prizes > 0;
                  setState(() {
                    if (hadPrizes) player.prizes--;
                  });
                  _persist();
                  Navigator.pop(context);
                  if (hadPrizes && player.prizes == 0) {
                    // Screen-Context statt Dialog-Context: der Dialog ist hier bereits geschlossen
                    ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
                      content: Text(_t('player_wins').replaceAll('{name}', player.name)),
                      backgroundColor: primaryColor,
                    ));
                  }
                },
              ),
            ),
            Text("${player.prizes}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
            Container(
              decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 30),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (player.prizes < 6) player.prizes++;
                  });
                  _persist();
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('back'), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
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
        content: Text(_t('rules_text'), style: const TextStyle(color: Colors.white70, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_t('ok'), style: TextStyle(color: primaryColor)))
        ],
      ),
    );
  }

  void _editSlot(bool isPlayer1, int benchIndex, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {

            // Änderung genau einmal ausführen, danach Sheet und Spielfeld neu zeichnen
            void updateState(VoidCallback fn) {
              setState(fn);
              setModalState(() {});
              _persist();
            }

            PokePlayer player = isPlayer1 ? player1 : player2;
            PokeSlot slot = benchIndex == -1 ? player.active : player.bench[benchIndex];

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewPadding.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Damage Adjustments
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _editBtn("-50", () => updateState(() => slot.damage = max(0, slot.damage - 50))),
                      _editBtn("-10", () => updateState(() => slot.damage = max(0, slot.damage - 10))),
                      Expanded(
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text("${slot.damage}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold))
                          )
                      ),
                      _editBtn("+10", () => updateState(() => slot.damage += 10)),
                      _editBtn("+50", () => updateState(() => slot.damage += 50)),
                    ],
                  ),

                  // Spezielle Zustände (nur aktives Pokémon) - Antippen schaltet an/aus
                  if (benchIndex == -1) ...[
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statusToggle(Icons.local_fire_department, burnColor, slot.isBurned,
                            () => updateState(() => slot.isBurned = !slot.isBurned)),
                        _statusToggle(Icons.sick, poisonColor, slot.isPoisoned,
                            () => updateState(() => slot.isPoisoned = !slot.isPoisoned)),
                        Container(width: 2, height: 30, color: Colors.white12),
                        for (final entry in {
                          SpecialCondition.asleep: (Icons.nights_stay, statusColor),
                          SpecialCondition.paralyzed: (Icons.bolt, primaryColor),
                          SpecialCondition.confused: (Icons.sync, statusColor),
                        }.entries)
                          _statusToggle(entry.value.$1, entry.value.$2, slot.condition == entry.key,
                              () => updateState(() => slot.condition =
                                  slot.condition == entry.key ? SpecialCondition.none : entry.key)),
                      ],
                    ),
                  ],

                  const SizedBox(height: 30),

                  // Aktionen
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            updateState(() => slot.clearAll());
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.delete),
                          label: Text(_t('clear')),
                          style: ElevatedButton.styleFrom(backgroundColor: damageColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                        ),
                      ),
                      if (benchIndex >= 0) ...[
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                // Tausche Active mit Bank - das bisher aktive Pokémon verliert seine Zustände
                                PokeSlot temp = player.active..clearConditions();
                                player.active = player.bench[benchIndex];
                                player.bench[benchIndex] = temp;
                              });
                              _persist();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.swap_vert),
                            label: Text(_t('swap_active')),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          }
      ),
    );
  }

  Widget _statusToggle(IconData icon, Color color, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 50, height: 50,
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.35) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: active ? color : Colors.white24, width: 2),
        ),
        child: Icon(icon, color: active ? color : Colors.white38),
      ),
    );
  }

  Widget _editBtn(String text, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      // Feste Grösse, damit die Reihe auch auf schmalen Handys (<= 360pt) nicht überläuft
      style: ElevatedButton.styleFrom(backgroundColor: activeColor, shape: const CircleBorder(), padding: EdgeInsets.zero, fixedSize: const Size(56, 56), minimumSize: const Size(56, 56)),
      child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetGame),
          IconButton(icon: const Icon(Icons.help_outline), onPressed: _showRules),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // OPPONENT AREA (Top) - Rotated by 180 degrees
            Expanded(
              flex: 4,
              child: RotatedBox(
                quarterTurns: 2,
                child: _buildPlayerArea(player2, isTop: true),
              ),
            ),

            // TRAY AREA (Middle) - Scrollable list of Drag sources
            Container(
              height: 70,
              margin: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border.symmetric(horizontal: BorderSide(color: primaryColor.withOpacity(0.3), width: 2))
              ),
              child: Center(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      children: [
                        _buildDraggableToken('10', damageColor),
                        _buildDraggableToken('50', damageColor),
                        _buildDraggableToken('100', damageColor),

                        Container(width: 2, height: 40, color: Colors.white12, margin: const EdgeInsets.symmetric(horizontal: 10)),

                        _buildDraggableToken('B', burnColor, icon: Icons.local_fire_department), // Burn
                        _buildDraggableToken('P', poisonColor, icon: Icons.sick), // Poison

                        Container(width: 2, height: 40, color: Colors.white12, margin: const EdgeInsets.symmetric(horizontal: 10)),

                        _buildDraggableToken('SLP', statusColor, icon: Icons.nights_stay), // Asleep
                        _buildDraggableToken('PAR', primaryColor, icon: Icons.bolt), // Paralyzed
                        _buildDraggableToken('CNF', statusColor, icon: Icons.sync), // Confused
                      ],
                    ),
              ),
            ),

            // YOUR AREA (Bottom)
            Expanded(
              flex: 4,
              child: _buildPlayerArea(player1, isTop: false),
            ),
          ],
        ),
      ),
    );
  }

  // Player Area Layout
  Widget _buildPlayerArea(PokePlayer player, {required bool isTop}) {
    List<Widget> children = [
      _buildPlayerHeader(player),
      const SizedBox(height: 10),
      Expanded(flex: 2, child: _buildBenchRow(player)),
      const SizedBox(height: 10),
      Expanded(flex: 3, child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _buildActiveSlot(player)),
          const SizedBox(width: 10),
          Expanded(flex: 1, child: _buildTurnActions(player)), // Supporter & Retreat Panel
        ],
      )),
    ];

    if (!isTop) {
      children = children.reversed.toList();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        children: children,
      ),
    );
  }

  // Header: Name, Prizes, GX, VSTAR
  Widget _buildPlayerHeader(PokePlayer player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Name & Once-per-game markers
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: GestureDetector(
                  onTap: () => _showRenameDialog(player),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text(player.name, style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 5),
                      Icon(Icons.edit, color: primaryColor.withOpacity(0.5), size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // GX Button
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => player.gxUsed = !player.gxUsed);
                  _persist();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                      color: player.gxUsed ? Colors.black26 : Colors.blueAccent.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: player.gxUsed ? Colors.grey : Colors.blueAccent)
                  ),
                  child: Text("GX", style: TextStyle(color: player.gxUsed ? Colors.grey : Colors.white, fontWeight: FontWeight.bold, fontSize: 12, decoration: player.gxUsed ? TextDecoration.lineThrough : null)),
                ),
              ),
              const SizedBox(width: 5),
              // VSTAR Button
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => player.vstarUsed = !player.vstarUsed);
                  _persist();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                      color: player.vstarUsed ? Colors.black26 : Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: player.vstarUsed ? Colors.grey : Colors.white)
                  ),
                  child: Text("VSTAR", style: TextStyle(color: player.vstarUsed ? Colors.grey : Colors.black, fontWeight: FontWeight.bold, fontSize: 12, decoration: player.vstarUsed ? TextDecoration.lineThrough : null)),
                ),
              ),
            ],
          ),
        ),

        // Prizes
        GestureDetector(
          onTap: () => _showPrizeDialog(player),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withOpacity(0.5))
            ),
            child: Row(
              children: List.generate(6, (index) {
                bool hasCard = index < player.prizes;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    Icons.catching_pokemon,
                    color: hasCard ? primaryColor : Colors.grey.withOpacity(0.2),
                    size: 20,
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  // Turn Actions (Supporter, Retreat)
  Widget _buildTurnActions(PokePlayer player) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => player.supporterUsed = !player.supporterUsed);
              _persist();
            },
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  color: player.supporterUsed ? successColor.withOpacity(0.2) : activeColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: player.supporterUsed ? successColor : Colors.transparent)
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, color: player.supporterUsed ? successColor : Colors.white54, size: 20),
                  const SizedBox(height: 2),
                  Text(_t('supporter'), style: TextStyle(color: player.supporterUsed ? successColor : Colors.white54, fontSize: 8), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => player.retreatUsed = !player.retreatUsed);
              _persist();
            },
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  color: player.retreatUsed ? Colors.orange.withOpacity(0.2) : activeColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: player.retreatUsed ? Colors.orange : Colors.transparent)
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_run, color: player.retreatUsed ? Colors.orange : Colors.white54, size: 20),
                  const SizedBox(height: 2),
                  Text(_t('retreat'), style: TextStyle(color: player.retreatUsed ? Colors.orange : Colors.white54, fontSize: 8), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() => player.endTurn());
            _persist();
          },
          child: Tooltip(
            message: _t('end_turn'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(10)),
              // skip_next statt refresh: refresh sieht aus wie "Spiel zurücksetzen" oben rechts
              child: const Icon(Icons.skip_next, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  // Active Pokemon Slot
  Widget _buildActiveSlot(PokePlayer player) {
    bool isP1 = player == player1;
    return _buildDroppableSlot(player.active, _t('active'), true, isP1, -1);
  }

  // Bench Slots
  Widget _buildBenchRow(PokePlayer player) {
    bool isP1 = player == player1;
    return Row(
      children: player.bench.asMap().entries.map((entry) {
        int index = entry.key;
        PokeSlot slot = entry.value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _buildDroppableSlot(slot, _t('bench'), false, isP1, index),
          ),
        );
      }).toList(),
    );
  }

  // Reusable Slot with DragTarget
  Widget _buildDroppableSlot(PokeSlot slot, String title, bool isActive, bool isP1, int benchIndex) {
    return DragTarget<String>(
      // Bank-Pokémon können keine Speziellen Zustände haben - dort nur Schadensmarken annehmen
      onWillAcceptWithDetails: (details) => isActive || PokeSlot.isDamageToken(details.data),
      onAcceptWithDetails: (details) {
        HapticFeedback.heavyImpact();
        setState(() => slot.applyToken(details.data));
        _persist();
      },
      builder: (context, candidateData, rejectedData) {
        bool isHovered = candidateData.isNotEmpty;

        Color slotBorder = isHovered ? primaryColor : (slot.damage > 0 ? damageColor.withOpacity(0.5) : Colors.white10);

        if (isActive) {
          if (slot.condition != SpecialCondition.none && !isHovered) {
            slotBorder = statusColor;
          }
        }

        return GestureDetector(
          onTap: () => _editSlot(isP1, benchIndex, title),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isHovered ? primaryColor.withOpacity(0.2) : activeColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: slotBorder, width: isHovered ? 3 : 2),
            ),
            child: Stack(
              children: [
                // Title
                Positioned(
                  top: isActive ? 10 : 5, left: 0, right: 0,
                  child: Text(title, textAlign: TextAlign.center, style: TextStyle(color: Colors.white24, fontSize: isActive ? 16 : 10, fontWeight: FontWeight.bold)),
                ),

                // Damage Text
                Center(
                  child: Text(
                    slot.damage > 0 ? "${slot.damage}" : "",
                    style: TextStyle(
                        color: damageColor,
                        fontSize: isActive ? 48 : 24,
                        fontWeight: FontWeight.w900,
                        shadows: [const Shadow(color: Colors.black, blurRadius: 10)]
                    ),
                  ),
                ),

                // Status Icons Bottom (Burn/Poison)
                Positioned(
                  bottom: isActive ? 10 : 5, left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (slot.isBurned) Icon(Icons.local_fire_department, color: burnColor, size: isActive ? 24 : 16),
                      if (slot.isBurned && slot.isPoisoned) const SizedBox(width: 5),
                      if (slot.isPoisoned) Icon(Icons.sick, color: poisonColor, size: isActive ? 24 : 16),
                    ],
                  ),
                ),

                // Condition Icon Top Right (Sleep/Para/Confuse)
                if (isActive && slot.condition != SpecialCondition.none)
                  Positioned(
                      top: 5, right: 5,
                      child: Icon(
                          slot.condition == SpecialCondition.asleep ? Icons.nights_stay :
                          slot.condition == SpecialCondition.paralyzed ? Icons.bolt : Icons.sync,
                          color: statusColor, size: 24
                      )
                  )
              ],
            ),
          ),
        );
      },
    );
  }

  // Draggable Token for the Tray
  Widget _buildDraggableToken(String value, Color color, {IconData? icon}) {
    Widget visual = Container(
      width: 50, height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 5), // Spacing for ListView
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, color: color)
            : Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );

    return Draggable<String>(
      data: value,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.2,
          child: visual,
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: visual),
      child: visual,
    );
  }
}