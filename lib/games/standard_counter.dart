import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StandardCounterGame extends StatefulWidget {
  final Color? themeColor;

  const StandardCounterGame({super.key, this.themeColor});

  @override
  State<StandardCounterGame> createState() => _StandardCounterGameState();
}

class _StandardCounterGameState extends State<StandardCounterGame> {
  // --- STYLE ---
  Color get primaryColor => widget.themeColor ?? const Color(0xFF4CBF98);
  final Color bgColor = const Color(0xFF222629);
  final Color surfaceColor = const Color(0xFF30363B);
  final Color errorColor = const Color(0xFFEB6B6B);

  // --- STATE ---
  List<Map<String, dynamic>> players = [];
  final TextEditingController _renameController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Sprach-Status (Default 'en', wird in initState überschrieben)
  String _currentLang = 'en';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  // Lade Sprache direkt aus dem Speicher, um Context-Probleme zu umgehen
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentLang = prefs.getString('language_code') ?? 'de';
      });
    }
  }

  // --- ÜBERSETZUNG ---
  String _t(String key) {
    const Map<String, Map<String, String>> dictionary = {
      'de': {
        'title': 'Standard Counter', 'reset_title': 'Punkte zurücksetzen?', 'reset_msg': 'Alle Punktestände werden auf 0 gesetzt.',
        'cancel': 'ABBRECHEN', 'reset_confirm': 'RESET', 'delete_confirm': 'Löschen', 'no_players': 'Keine Spieler',
        'start_hint': 'Füge Spieler hinzu', 'add_btn': 'SPIELER HINZUFÜGEN', 'player_default': 'Spieler', 'rename_title': 'Name ändern',
        'save': 'SPEICHERN', 'rules_title': 'Anleitung', 'rules_text': 'Ein einfacher Zähler für alle Gelegenheiten.\n\n• Tippe auf + oder - um Punkte zu ändern.\n• Tippe auf den Stift, um den Namen zu ändern.\n• Wische eine Karte weg, um den Spieler zu löschen.', 'ok': 'VERSTANDEN',
      },
      'en': {
        'title': 'Standard Counter', 'reset_title': 'Reset Scores?', 'reset_msg': 'All scores will be reset to 0.',
        'cancel': 'CANCEL', 'reset_confirm': 'RESET', 'delete_confirm': 'Delete', 'no_players': 'No Players',
        'start_hint': 'Add players to start', 'add_btn': 'ADD PLAYER', 'player_default': 'Player', 'rename_title': 'Rename Player',
        'save': 'SAVE', 'rules_title': 'How to play', 'rules_text': 'A simple counter for any occasion.\n\n• Tap + or - to change scores.\n• Tap the pencil icon to rename.\n• Swipe a card to remove the player.', 'ok': 'GOT IT',
      },
      'fr': {
        'title': 'Compteur Standard', 'reset_title': 'Réinitialiser ?', 'reset_msg': 'Tous les scores seront remis à 0.',
        'cancel': 'ANNULER', 'reset_confirm': 'RÉINITIALISER', 'delete_confirm': 'Supprimer', 'no_players': 'Aucun joueur',
        'start_hint': 'Ajoutez des joueurs', 'add_btn': 'AJOUTER JOUEUR', 'player_default': 'Joueur', 'rename_title': 'Renommer',
        'save': 'ENREGISTRER', 'rules_title': 'Comment jouer', 'rules_text': 'Un compteur simple.\n\n• Appuyez sur + ou - pour changer les scores.\n• Appuyez sur le crayon pour renommer.\n• Glissez pour supprimer.', 'ok': 'COMPRIS',
      },
      'it': {
        'title': 'Contatore Standard', 'reset_title': 'Resettare?', 'reset_msg': 'Tutti i punteggi saranno azzerati.',
        'cancel': 'ANNULLA', 'reset_confirm': 'RESET', 'delete_confirm': 'Elimina', 'no_players': 'Nessun giocatore',
        'start_hint': 'Aggiungi giocatori', 'add_btn': 'AGGIUNGI GIOCATORE', 'player_default': 'Giocatore', 'rename_title': 'Rinomina',
        'save': 'SALVA', 'rules_title': 'Istruzioni', 'rules_text': 'Un contatore semplice.\n\n• Tocca + o - per cambiare i punteggi.\n• Tocca la matita per rinominare.\n• Scorri per eliminare.', 'ok': 'CAPITO',
      },
      'es': {
        'title': 'Contador Estándar', 'reset_title': '¿Reiniciar?', 'reset_msg': 'Todos los puntajes volverán a 0.',
        'cancel': 'CANCELAR', 'reset_confirm': 'REINICIAR', 'delete_confirm': 'Eliminar', 'no_players': 'Sin jugadores',
        'start_hint': 'Añadir jugadores', 'add_btn': 'AÑADIR JUGADOR', 'player_default': 'Jugador', 'rename_title': 'Renombrar',
        'save': 'GUARDAR', 'rules_title': 'Instrucciones', 'rules_text': 'Un contador simple.\n\n• Toca + o - para cambiar puntajes.\n• Toca el lápiz para renombrar.\n• Desliza para eliminar.', 'ok': 'ENTENDIDO',
      },
      'pt': {
        'title': 'Contador Padrão', 'reset_title': 'Reiniciar?', 'reset_msg': 'Todas as pontuações voltarão a 0.',
        'cancel': 'CANCELAR', 'reset_confirm': 'REINICIAR', 'delete_confirm': 'Excluir', 'no_players': 'Sem jogadores',
        'start_hint': 'Adicione jogadores', 'add_btn': 'ADICIONAR JOGADOR', 'player_default': 'Jogador', 'rename_title': 'Renomear',
        'save': 'SALVAR', 'rules_title': 'Instruções', 'rules_text': 'Um contador simples.\n\n• Toque em + ou - para mudar pontuações.\n• Toque no lápis para renomear.\n• Deslize para excluir.', 'ok': 'ENTENDIDO',
      },
      'nl': {
        'title': 'Standaard Teller', 'reset_title': 'Resetten?', 'reset_msg': 'Alle scores worden op 0 gezet.',
        'cancel': 'ANNULEREN', 'reset_confirm': 'RESET', 'delete_confirm': 'Verwijderen', 'no_players': 'Geen spelers',
        'start_hint': 'Voeg spelers toe', 'add_btn': 'SPELER TOEVOEGEN', 'player_default': 'Speler', 'rename_title': 'Naam wijzigen',
        'save': 'OPSLAAN', 'rules_title': 'Instructies', 'rules_text': 'Een simpele teller.\n\n• Tik op + of - om scores te wijzigen.\n• Tik op het potlood om te wijzigen.\n• Veeg om te verwijderen.', 'ok': 'BEGREPEN',
      },
      'pl': {
        'title': 'Standardowy Licznik', 'reset_title': 'Zresetować?', 'reset_msg': 'Wszystkie wyniki zostaną wyzerowane.',
        'cancel': 'ANULUJ', 'reset_confirm': 'RESET', 'delete_confirm': 'Usuń', 'no_players': 'Brak graczy',
        'start_hint': 'Dodaj graczy', 'add_btn': 'DODAJ GRACZA', 'player_default': 'Gracz', 'rename_title': 'Zmień nazwę',
        'save': 'ZAPISZ', 'rules_title': 'Instrukcja', 'rules_text': 'Prosty licznik.\n\n• Dotknij + lub - aby zmienić wynik.\n• Dotknij ołówka, aby zmienić nazwę.\n• Przesuń, aby usunąć.', 'ok': 'ZROZUMIAŁEM',
      },
      'tr': {
        'title': 'Standart Sayaç', 'reset_title': 'Sıfırla?', 'reset_msg': 'Tüm puanlar 0 olacak.',
        'cancel': 'İPTAL', 'reset_confirm': 'SIFIRLA', 'delete_confirm': 'Sil', 'no_players': 'Oyuncu yok',
        'start_hint': 'Oyuncu ekle', 'add_btn': 'OYUNCU EKLE', 'player_default': 'Oyuncu', 'rename_title': 'İsim Değiştir',
        'save': 'KAYDET', 'rules_title': 'Talimatlar', 'rules_text': 'Basit bir sayaç.\n\n• Puanları değiştirmek için + veya -.\n• İsim değiştirmek için kalem.\n• Silmek için kaydırın.', 'ok': 'ANLADIM',
      },
      'id': {
        'title': 'Penghitung Standar', 'reset_title': 'Reset?', 'reset_msg': 'Semua skor akan diatur ke 0.',
        'cancel': 'BATAL', 'reset_confirm': 'RESET', 'delete_confirm': 'Hapus', 'no_players': 'Tidak ada pemain',
        'start_hint': 'Tambahkan pemain', 'add_btn': 'TAMBAH PEMAIN', 'player_default': 'Pemain', 'rename_title': 'Ubah Nama',
        'save': 'SIMPAN', 'rules_title': 'Instruksi', 'rules_text': 'Penghitung sederhana.\n\n• Ketuk + atau - untuk skor.\n• Ketuk pensil untuk nama.\n• Geser untuk menghapus.', 'ok': 'MENGERTI',
      },
      'sv': {
        'title': 'Standardräknare', 'reset_title': 'Återställ?', 'reset_msg': 'Alla poäng återställs till 0.',
        'cancel': 'AVBRYT', 'reset_confirm': 'ÅTERSTÄLL', 'delete_confirm': 'Ta bort', 'no_players': 'Inga spelare',
        'start_hint': 'Lägg till spelare', 'add_btn': 'LÄGG TILL SPELARE', 'player_default': 'Spelare', 'rename_title': 'Byt namn',
        'save': 'SPARA', 'rules_title': 'Instruktioner', 'rules_text': 'En enkel räknare.\n\n• Tryck på + eller - för poäng.\n• Tryck på pennan för namn.\n• Svep för att ta bort.', 'ok': 'FÖRSTÅTT',
      },
      'hr': {
        'title': 'Standardni Brojač', 'reset_title': 'Resetirati?', 'reset_msg': 'Svi bodovi bit će vraćeni na 0.',
        'cancel': 'ODUSTANI', 'reset_confirm': 'RESET', 'delete_confirm': 'Obriši', 'no_players': 'Nema igrača',
        'start_hint': 'Dodaj igrače', 'add_btn': 'DODAJ IGRAČA', 'player_default': 'Igrač', 'rename_title': 'Promijeni ime',
        'save': 'SPREMI', 'rules_title': 'Upute', 'rules_text': 'Jednostavan brojač.\n\n• Dodirnite + ili - za bodove.\n• Dodirnite olovku za ime.\n• Povucite za brisanje.', 'ok': 'RAZUMIJEM',
      },
      'ru': {
        'title': 'Стандартный счетчик', 'reset_title': 'Сбросить?', 'reset_msg': 'Все очки будут сброшены на 0.',
        'cancel': 'ОТМЕНА', 'reset_confirm': 'СБРОС', 'delete_confirm': 'Удалить', 'no_players': 'Нет игроков',
        'start_hint': 'Добавьте игроков', 'add_btn': 'ДОБАВИТЬ ИГРОКА', 'player_default': 'Игрок', 'rename_title': 'Переименовать',
        'save': 'СОХРАНИТЬ', 'rules_title': 'Инструкции', 'rules_text': 'Простой счетчик.\n\n• Нажмите + или - для очков.\n• Нажмите карандаш для имени.\n• Смахните для удаления.', 'ok': 'ПОНЯТНО',
      },
      'ja': {
        'title': '標準カウンター', 'reset_title': 'リセットしますか？', 'reset_msg': 'すべてのスコアが0になります。',
        'cancel': 'キャンセル', 'reset_confirm': 'リセット', 'delete_confirm': '削除', 'no_players': 'プレイヤーなし',
        'start_hint': 'プレイヤーを追加', 'add_btn': 'プレイヤーを追加', 'player_default': 'プレイヤー', 'rename_title': '名前を変更',
        'save': '保存', 'rules_title': '遊び方', 'rules_text': 'シンプルなカウンター。\n\n• + または - でスコア変更。\n• 鉛筆で名前変更。\n• スワイプで削除。', 'ok': '了解',
      },
      'ko': {
        'title': '기본 카운터', 'reset_title': '초기화?', 'reset_msg': '모든 점수가 0이 됩니다.',
        'cancel': '취소', 'reset_confirm': '초기화', 'delete_confirm': '삭제', 'no_players': '플레이어 없음',
        'start_hint': '플레이어 추가', 'add_btn': '플레이어 추가', 'player_default': '플레이어', 'rename_title': '이름 변경',
        'save': '저장', 'rules_title': '설명', 'rules_text': '간단한 카운터.\n\n• + 또는 - 로 점수 변경.\n• 연필로 이름 변경.\n• 스와이프로 삭제.', 'ok': '확인',
      },
      'zh': {
        'title': '标准计数器', 'reset_title': '重置？', 'reset_msg': '所有分数将归零。',
        'cancel': '取消', 'reset_confirm': '重置', 'delete_confirm': '删除', 'no_players': '无玩家',
        'start_hint': '添加玩家', 'add_btn': '添加玩家', 'player_default': '玩家', 'rename_title': '重命名',
        'save': '保存', 'rules_title': '说明', 'rules_text': '简单计数器。\n\n• 点击 + 或 - 更改分数。\n• 点击铅笔更改名称。\n• 滑动删除。', 'ok': '明白了',
      },
      'hi': {
        'title': 'मानक काउंटर', 'reset_title': 'रीसेट करें?', 'reset_msg': 'सभी स्कोर 0 हो जाएंगे।',
        'cancel': 'रद्द करें', 'reset_confirm': 'रीसेट', 'delete_confirm': 'हटाएं', 'no_players': 'कोई खिलाड़ी नहीं',
        'start_hint': 'खिलाड़ी जोड़ें', 'add_btn': 'खिलाड़ी जोड़ें', 'player_default': 'खिलाड़ी', 'rename_title': 'नाम बदलें',
        'save': 'सहेजें', 'rules_title': 'निर्देश', 'rules_text': 'सरल काउंटर।\n\n• स्कोर बदलने के लिए + या - दबाएं।\n• नाम बदलने के लिए पेंसिल दबाएं।\n• हटाने के लिए स्वाइप करें।', 'ok': 'समझ गया',
      },
      'bn': {
        'title': 'স্ট্যান্ডার্ড কাউন্টার', 'reset_title': 'রিসেট?', 'reset_msg': 'সব স্কোর 0 হবে।',
        'cancel': 'বাতিল', 'reset_confirm': 'রিসেট', 'delete_confirm': 'মুছুন', 'no_players': 'খেলোয়াড় নেই',
        'start_hint': 'খেলোয়াড় যোগ করুন', 'add_btn': 'খেলোয়াড় যোগ করুন', 'player_default': 'খেলোয়াড়', 'rename_title': 'নাম পরিবর্তন',
        'save': 'সংরক্ষণ', 'rules_title': 'নির্দেশনা', 'rules_text': 'সহজ কাউন্টার।\n\n• স্কোর বদলাতে + বা - চাপুন।\n• নাম বদলাতে পেন্সিল চাপুন।\n• মুছতে সোয়াইপ করুন।', 'ok': 'বুঝেছি',
      },
      'ar': {
        'title': 'العداد القياسي', 'reset_title': 'إعادة تعيين؟', 'reset_msg': 'ستعود النقاط إلى 0.',
        'cancel': 'إلغاء', 'reset_confirm': 'إعادة تعيين', 'delete_confirm': 'حذف', 'no_players': 'لا لاعبين',
        'start_hint': 'أضف لاعبين', 'add_btn': 'إضافة لاعب', 'player_default': 'لاعب', 'rename_title': 'تغيير الاسم',
        'save': 'حفظ', 'rules_title': 'تعليمات', 'rules_text': 'عداد بسيط.\n\n• + أو - للنقاط.\n• القلم للاسم.\n• اسحب للحذف.', 'ok': 'فهمت',
      },
    };

    // Nutze die geladene Sprache aus SharedPreferences
    if (dictionary.containsKey(_currentLang) && dictionary[_currentLang]!.containsKey(key)) {
      return dictionary[_currentLang]![key]!;
    }
    return dictionary['en']![key] ?? key;
  }

  // --- LOGIK ---

  void _addPlayer() {
    HapticFeedback.lightImpact();
    setState(() {
      int nextNum = players.length + 1;
      players.add({
        'name': '${_t('player_default')} $nextNum',
        'score': 0,
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _changeScore(int index, int amount) {
    HapticFeedback.selectionClick();
    setState(() {
      players[index]['score'] += amount;
    });
  }

  void _showRenameDialog(int index) {
    _renameController.text = players[index]['name'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: primaryColor)),
        title: Text(_t('rename_title'), style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: _renameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
          ),
          onSubmitted: (_) {
            _saveName(index);
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
              _saveName(index);
              Navigator.pop(context);
            },
            child: Text(_t('save'), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _saveName(int index) {
    if (_renameController.text.trim().isNotEmpty) {
      setState(() {
        players[index]['name'] = _renameController.text.trim();
      });
    }
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

  void _resetScores() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        title: Text(_t('reset_title'), style: const TextStyle(color: Colors.white)),
        content: Text(_t('reset_msg'), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_t('cancel'), style: const TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              setState(() {
                for (var p in players) {
                  p['score'] = 0;
                }
              });
              Navigator.pop(context);
            },
            child: Text(_t('reset_confirm'), style: TextStyle(color: errorColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(_t('title')),
        backgroundColor: Colors.transparent,
        foregroundColor: primaryColor,
        elevation: 0,
        actions: [
          if (players.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetScores,
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showRules,
          ),
        ],
      ),
      body: Column(
        children: [
          // --- SPIELER LISTE ---
          Expanded(
            child: players.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              itemCount: players.length,
              itemBuilder: (context, index) => _buildPlayerCard(index),
            ),
          ),

          // --- BOTTOM BUTTON ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -5))],
            ),
            child: SafeArea(
              child: SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _addPlayer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        _t('add_btn'),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, size: 100, color: Colors.white.withAlpha(25)),
          const SizedBox(height: 20),
          Text(
            _t('no_players'),
            style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            _t('start_hint'),
            style: TextStyle(color: Colors.white.withAlpha(77), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(int index) {
    final player = players[index];

    return Dismissible(
      key: Key(player.hashCode.toString()), // Unique Key
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.only(right: 30),
        decoration: BoxDecoration(
          color: errorColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      onDismissed: (direction) {
        setState(() {
          players.removeAt(index);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20), // Großzügiges Padding
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(10), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Minus Button
            _hugeControlBtn(Icons.remove, () => _changeScore(index, -1), Colors.grey.shade700),

            // Center Info (Name & Score)
            Expanded(
              child: Column(
                children: [
                  Text(
                    "${player['score']}",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 56, // RIESIGE Zahl
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () => _showRenameDialog(index),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            player['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.edit, color: Colors.white.withAlpha(100), size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Plus Button
            _hugeControlBtn(Icons.add, () => _changeScore(index, 1), primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _hugeControlBtn(IconData icon, VoidCallback onTap, Color color) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withAlpha(100),
          child: Container(
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(80), width: 2),
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
        ),
      ),
    );
  }
}