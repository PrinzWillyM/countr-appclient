import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LifeTrackerGame extends StatefulWidget {
  final Color? themeColor;

  const LifeTrackerGame({super.key, this.themeColor});

  @override
  State<LifeTrackerGame> createState() => _LifeTrackerGameState();
}

class _LifeTrackerGameState extends State<LifeTrackerGame> {
  // --- STYLE ---
  Color get primaryColor => widget.themeColor ?? const Color(0xFFEBCB63); // Brand Yellow
  final Color bgColor = const Color(0xFF222629);
  final Color surfaceColor = const Color(0xFF30363B);

  // --- STATE ---
  int playerCount = 2;
  int startLife = 20;
  List<Map<String, dynamic>> players = [];
  String _currentLang = 'en';

  final TextEditingController _renameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _resetGame();
  }

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
        'title': 'Life Tracker', 'start_life': 'Start-Leben', 'players': 'Spieler',
        'reset': 'Reset', 'rules_title': 'Anleitung', 'ok': 'VERSTANDEN', 'cancel': 'ABBRECHEN', 'save': 'SPEICHERN',
        'rename_title': 'Name ändern',
        'rules_text': 'Ein Lebenspunktezähler für Kartenspiele.\n\n• Tippe auf +/- um Leben zu ändern.\n• Tippe auf den Namen, um ihn zu ändern.',
      },
      'en': {
        'title': 'Life Tracker', 'start_life': 'Start Life', 'players': 'Players',
        'reset': 'Reset', 'rules_title': 'Instructions', 'ok': 'GOT IT', 'cancel': 'CANCEL', 'save': 'SAVE',
        'rename_title': 'Rename',
        'rules_text': 'A life counter for card games.\n\n• Tap +/- to change life.\n• Tap the name to rename.',
      },
      'fr': {
        'title': 'Compteur de Vie', 'start_life': 'Vie de départ', 'players': 'Joueurs',
        'reset': 'Réinit.', 'rules_title': 'Instructions', 'ok': 'COMPRIS', 'cancel': 'ANNULER', 'save': 'SAUVER',
        'rename_title': 'Renommer',
        'rules_text': 'Un compteur de vie pour jeux de cartes.\n\n• Appuyez sur +/- pour changer.\n• Appuyez sur le nom pour renommer.',
      },
      'it': { 'title': 'Contatore Vita', 'start_life': 'Vita Iniziale', 'players': 'Giocatori', 'reset': 'Reset', 'rules_title': 'Istruzioni', 'ok': 'CAPITO', 'cancel': 'ANNULLA', 'save': 'SALVA', 'rename_title': 'Rinomina', 'rules_text': 'Contatore di vita per giochi di carte.' },
      'es': { 'title': 'Contador de Vida', 'start_life': 'Vida Inicial', 'players': 'Jugadores', 'reset': 'Reiniciar', 'rules_title': 'Instrucciones', 'ok': 'ENTENDIDO', 'cancel': 'CANCELAR', 'save': 'GUARDAR', 'rename_title': 'Renombrar', 'rules_text': 'Contador de vida para juegos de cartas.' },
      'pt': { 'title': 'Contador de Vida', 'start_life': 'Vida Inicial', 'players': 'Jogadores', 'reset': 'Reiniciar', 'rules_title': 'Instruções', 'ok': 'ENTENDIDO', 'cancel': 'CANCELAR', 'save': 'SALVAR', 'rename_title': 'Renomear', 'rules_text': 'Contador de vida para jogos de cartas.' },
      'nl': { 'title': 'Levensteller', 'start_life': 'Startleven', 'players': 'Spelers', 'reset': 'Reset', 'rules_title': 'Instructies', 'ok': 'BEGREPEN', 'cancel': 'ANNULEREN', 'save': 'OPSLAAN', 'rename_title': 'Wijzigen', 'rules_text': 'Levensteller voor kaartspellen.' },
      'pl': { 'title': 'Licznik Życia', 'start_life': 'Życie Startowe', 'players': 'Graczy', 'reset': 'Reset', 'rules_title': 'Instrukcja', 'ok': 'ZROZUMIAŁEM', 'cancel': 'ANULUJ', 'save': 'ZAPISZ', 'rename_title': 'Zmień nazwę', 'rules_text': 'Licznik życia do gier karcianych.' },
      'tr': { 'title': 'Can Sayacı', 'start_life': 'Başlangıç Canı', 'players': 'Oyuncular', 'reset': 'Sıfırla', 'rules_title': 'Talimatlar', 'ok': 'ANLADIM', 'cancel': 'İPTAL', 'save': 'KAYDET', 'rename_title': 'İsim Değiştir', 'rules_text': 'Kart oyunları için can sayacı.' },
      'id': { 'title': 'Pelacak Nyawa', 'start_life': 'Nyawa Awal', 'players': 'Pemain', 'reset': 'Reset', 'rules_title': 'Instruksi', 'ok': 'MENGERTI', 'cancel': 'BATAL', 'save': 'SIMPAN', 'rename_title': 'Ubah Nama', 'rules_text': 'Penghitung nyawa untuk permainan kartu.' },
      'sv': { 'title': 'Livräknare', 'start_life': 'Startliv', 'players': 'Spelare', 'reset': 'Återställ', 'rules_title': 'Instruktioner', 'ok': 'FÖRSTÅTT', 'cancel': 'AVBRYT', 'save': 'SPARA', 'rename_title': 'Byt namn', 'rules_text': 'Livräknare för kortspel.' },
      'hr': { 'title': 'Praćenje života', 'start_life': 'Početni život', 'players': 'Igrača', 'reset': 'Reset', 'rules_title': 'Upute', 'ok': 'RAZUMIJEM', 'cancel': 'ODUSTANI', 'save': 'SPREMI', 'rename_title': 'Promijeni ime', 'rules_text': 'Brojač života za kartaške igre.' },
      'ru': { 'title': 'Счетчик жизни', 'start_life': 'Нач. жизнь', 'players': 'Игроков', 'reset': 'Сброс', 'rules_title': 'Инструкции', 'ok': 'ПОНЯТНО', 'cancel': 'ОТМЕНА', 'save': 'СОХРАНИТЬ', 'rename_title': 'Переименовать', 'rules_text': 'Счетчик жизни для карточных игр.' },
      'ja': { 'title': 'ライフカウンター', 'start_life': '初期ライフ', 'players': 'プレイヤー', 'reset': 'リセット', 'rules_title': '遊び方', 'ok': '了解', 'cancel': 'キャンセル', 'save': '保存', 'rename_title': '名前を変更', 'rules_text': 'カードゲーム用ライフカウンター。' },
      'ko': { 'title': '라이프 트래커', 'start_life': '시작 생명', 'players': '플레이어', 'reset': '초기화', 'rules_title': '설명', 'ok': '확인', 'cancel': '취소', 'save': '저장', 'rename_title': '이름 변경', 'rules_text': '카드 게임용 라이프 카운터.' },
      'zh': { 'title': '生命计数器', 'start_life': '初始生命', 'players': '玩家', 'reset': '重置', 'rules_title': '说明', 'ok': '明白了', 'cancel': '取消', 'save': '保存', 'rename_title': '重命名', 'rules_text': '卡牌游戏的生命计数器。' },
      'hi': { 'title': 'जीवन ट्रैकर', 'start_life': 'प्रारंभिक जीवन', 'players': 'खिलाड़ी', 'reset': 'रीसेट', 'rules_title': 'निर्देश', 'ok': 'समझ गया', 'cancel': 'रद्द करें', 'save': 'सहेजें', 'rename_title': 'नाम बदलें', 'rules_text': 'कार्ड गेम के लिए लाइफ काउंटर।' },
      'bn': { 'title': 'লাইফ ট্র্যাকার', 'start_life': 'শুরুর জীবন', 'players': 'খেলোয়াড়', 'reset': 'রিসেট', 'rules_title': 'নির্দেশনা', 'ok': 'বুঝেছি', 'cancel': 'বাতিল', 'save': 'সংরক্ষণ', 'rename_title': 'নাম পরিবর্তন', 'rules_text': 'কার্ড গেমের জন্য লাইফ কাউন্টার।' },
      'ar': { 'title': 'تتبع الحياة', 'start_life': 'حياة البداية', 'players': 'اللاعبين', 'reset': 'إعادة تعيين', 'rules_title': 'تعليمات', 'ok': 'فهمت', 'cancel': 'إلغاء', 'save': 'حفظ', 'rename_title': 'تغيير الاسم', 'rules_text': 'عداد حياة لألعاب الورق.' },
    };

    if (dictionary.containsKey(_currentLang) && dictionary[_currentLang]!.containsKey(key)) {
      return dictionary[_currentLang]![key]!;
    }
    return dictionary['en']![key] ?? key;
  }

  // --- LOGIK ---

  void _resetGame() {
    setState(() {
      players = List.generate(playerCount, (index) => {
        'name': 'P${index + 1}',
        'life': startLife,
      });
    });
  }

  void _updateLife(int index, int amount) {
    HapticFeedback.selectionClick();
    setState(() {
      players[index]['life'] += amount;
    });
  }

  void _showRenameDialog(int index) {
    _renameController.text = players[index]['name'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        title: Text(_t('rename_title'), style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: _renameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                players[index]['name'] = _renameController.text.trim();
              });
              Navigator.pop(context);
            },
            child: Text(_t('save'), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        title: Text(_t('rules_title'), style: TextStyle(color: primaryColor)),
        content: Text(_t('rules_text'), style: const TextStyle(color: Colors.white70, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_t('ok'), style: TextStyle(color: primaryColor)))
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
      body: Column(
        children: [
          // --- TOP MENU ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            color: Colors.black12,
            child: Row(
              children: [
                Expanded(
                  child: _buildConfigButton(
                    icon: Icons.favorite,
                    label: "$startLife",
                    title: _t('start_life'),
                    onTap: _showLifePicker,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildConfigButton(
                    icon: Icons.groups,
                    label: "$playerCount",
                    title: _t('players'),
                    onTap: _showPlayerCountPicker,
                  ),
                ),
                const SizedBox(width: 15),
                // Reset Button
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: primaryColor.withAlpha(50)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.refresh, color: primaryColor),
                    onPressed: _resetGame,
                  ),
                ),
              ],
            ),
          ),

          // --- GAME AREA ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15.0), // Padding around the whole area
              child: playerCount == 2
                  ? _buildTwoPlayerLayout()
                  : _buildGridPlayerLayout(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigButton({required IconData icon, required String label, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: primaryColor.withAlpha(50)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primaryColor, size: 24),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- LAYOUTS ---

  Widget _buildTwoPlayerLayout() {
    return Column(
      children: [
        // P1
        Expanded(
          child: _SimpleLifeCard(
            name: players[0]['name'],
            life: players[0]['life'],
            color: primaryColor,
            onChanged: (val) => _updateLife(0, val),
            onRename: () => _showRenameDialog(0),
          ),
        ),
        // Abstand
        const SizedBox(height: 15),
        // P2
        Expanded(
          child: _SimpleLifeCard(
            name: players[1]['name'],
            life: players[1]['life'],
            color: primaryColor,
            onChanged: (val) => _updateLife(1, val),
            onRename: () => _showRenameDialog(1),
          ),
        ),
      ],
    );
  }

  Widget _buildGridPlayerLayout() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 15, // Mehr Abstand
        mainAxisSpacing: 15,  // Mehr Abstand
      ),
      itemCount: playerCount,
      itemBuilder: (context, index) {
        return _SimpleLifeCard(
          name: players[index]['name'],
          life: players[index]['life'],
          color: primaryColor,
          onChanged: (val) => _updateLife(index, val),
          onRename: () => _showRenameDialog(index),
        );
      },
    );
  }

  // --- PICKERS ---

  void _showLifePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 200,
        child: Column(
          children: [
            Text(_t('start_life'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [20, 30, 40, 50, 60, 100].map((val) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ChoiceChip(
                    label: Text("$val", style: TextStyle(color: startLife == val ? Colors.black : Colors.white, fontSize: 18)),
                    selected: startLife == val,
                    selectedColor: primaryColor,
                    backgroundColor: bgColor,
                    padding: const EdgeInsets.all(12),
                    onSelected: (_) {
                      setState(() { startLife = val; _resetGame(); });
                      Navigator.pop(context);
                    },
                  ),
                )).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showPlayerCountPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 200,
        child: Column(
          children: [
            Text(_t('players'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [2, 3, 4, 5, 6].map((val) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ChoiceChip(
                    label: Text("$val", style: TextStyle(color: playerCount == val ? Colors.black : Colors.white, fontSize: 18)),
                    selected: playerCount == val,
                    selectedColor: primaryColor,
                    backgroundColor: bgColor,
                    padding: const EdgeInsets.all(12),
                    onSelected: (_) {
                      setState(() { playerCount = val; _resetGame(); });
                      Navigator.pop(context);
                    },
                  ),
                )).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- KARTE WIDGET ---
class _SimpleLifeCard extends StatelessWidget {
  final String name;
  final int life;
  final Color color;
  final Function(int) onChanged;
  final VoidCallback onRename;

  const _SimpleLifeCard({required this.name, required this.life, required this.color, required this.onChanged, required this.onRename});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20), // Mehr Platz oben für Namen
      decoration: BoxDecoration(
        color: const Color(0xFF30363B),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Verteilt Inhalt
        children: [
          // Name (klickbar)
          GestureDetector(
            onTap: onRename,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(name, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Icon(Icons.edit, size: 16, color: color.withOpacity(0.5)),
                ],
              ),
            ),
          ),

          // Life (Centered via Spacer)
          Spacer(),
          Text("$life", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 80, height: 1.0)),
          Spacer(),

          // Buttons (Bottom)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(-1),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(23)),
                  child: Container(
                    height: 70, // Grösser
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(23)),
                    ),
                    child: const Icon(Icons.remove, color: Colors.white, size: 36),
                  ),
                ),
              ),
              Container(width: 1, height: 70, color: Colors.white10),
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(1),
                  borderRadius: const BorderRadius.only(bottomRight: Radius.circular(23)),
                  child: Container(
                    height: 70, // Grösser
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.only(bottomRight: Radius.circular(23)),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 36),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}