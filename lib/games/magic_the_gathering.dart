import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MagicTheGatheringGame extends StatefulWidget {
  final Color? themeColor;

  const MagicTheGatheringGame({super.key, this.themeColor});

  @override
  State<MagicTheGatheringGame> createState() => _MagicTheGatheringGameState();
}

class _MagicTheGatheringGameState extends State<MagicTheGatheringGame> {
  // --- STYLE ---
  Color get primaryColor => widget.themeColor ?? const Color(0xFFEBCB63); // Brand Yellow
  final Color bgColor = const Color(0xFF222629);
  final Color surfaceColor = const Color(0xFF30363B);

  // --- STATE ---
  int playerCount = 2;
  int startLife = 20; // 20 für Standard, 40 für Commander
  List<Map<String, dynamic>> players = [];
  String _currentLang = 'en';

  final TextEditingController _renameController = TextEditingController();

  // Menü-Steuerung
  int _activeMenu = 0; // 0=nichts, 1=Life, 2=Players

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
        // Falls Namen schon generiert wurden, übersetze sie nachträglich
        for (int i = 0; i < players.length; i++) {
          if (players[i]['name'].toString().startsWith('Planeswalker') || players[i]['name'].toString().startsWith('Jogador')) {
            players[i]['name'] = '${_t('planeswalker')} ${i + 1}';
          }
        }
      });
    }
  }

  // --- ÜBERSETZUNG ---
  String _t(String key) {
    const Map<String, Map<String, String>> dictionary = {
      'de': {
        'title': 'Magic: The Gathering', 'start_life': 'Format', 'players': 'Spieler',
        'reset': 'Reset', 'rules_title': 'Anleitung', 'ok': 'VERSTANDEN', 'cancel': 'ABBRECHEN', 'save': 'SPEICHERN',
        'rename_title': 'Name ändern', 'planeswalker': 'Planeswalker',
        'rules_text': 'MTG Lebenszähler.\n\n• Wähle oben 20 (Standard) oder 40 (Commander).\n• Nutze die -5/-1/+1/+5 Buttons für schnelles Ändern.\n• Tippe auf den Namen, um ihn zu ändern.',
      },
      'en': {
        'title': 'Magic: The Gathering', 'start_life': 'Format', 'players': 'Players',
        'reset': 'Reset', 'rules_title': 'Rules', 'ok': 'GOT IT', 'cancel': 'CANCEL', 'save': 'SAVE',
        'rename_title': 'Rename', 'planeswalker': 'Planeswalker',
        'rules_text': 'MTG Life Counter.\n\n• Choose 20 (Standard) or 40 (Commander).\n• Use -5/-1/+1/+5 buttons to change life.\n• Tap the name to rename.',
      },
      'fr': {
        'title': 'Magic: The Gathering', 'start_life': 'Format', 'players': 'Joueurs',
        'reset': 'Réinit.', 'rules_title': 'Règles', 'ok': 'COMPRIS', 'cancel': 'ANNULER', 'save': 'SAUVER',
        'rename_title': 'Renommer', 'planeswalker': 'Planeswalker',
        'rules_text': 'Compteur de vie MTG.\n\n• Choisissez 20 (Standard) ou 40 (Commander).\n• Utilisez les boutons -5/-1/+1/+5.\n• Appuyez sur le nom pour renommer.',
      },
      'it': { 'title': 'Magic: The Gathering', 'start_life': 'Formato', 'players': 'Giocatori', 'reset': 'Reset', 'rules_title': 'Regole', 'ok': 'CAPITO', 'cancel': 'ANNULLA', 'save': 'SALVA', 'rename_title': 'Rinomina', 'planeswalker': 'Planeswalker', 'rules_text': 'Contatore vita MTG.\n\n• Scegli 20 o 40.\n• Usa i pulsanti -5/-1/+1/+5.\n• Tocca il nome per rinominare.' },
      'es': { 'title': 'Magic: The Gathering', 'start_life': 'Formato', 'players': 'Jugadores', 'reset': 'Reiniciar', 'rules_title': 'Reglas', 'ok': 'ENTENDIDO', 'cancel': 'CANCELAR', 'save': 'GUARDAR', 'rename_title': 'Renombrar', 'planeswalker': 'Planeswalker', 'rules_text': 'Contador de vida MTG.\n\n• Elige 20 o 40.\n• Usa botones -5/-1/+1/+5.\n• Toca el nombre para renombrar.' },
      'pt': { 'title': 'Magic: The Gathering', 'start_life': 'Formato', 'players': 'Jogadores', 'reset': 'Reiniciar', 'rules_title': 'Regras', 'ok': 'ENTENDIDO', 'cancel': 'CANCELAR', 'save': 'SALVAR', 'rename_title': 'Renomear', 'planeswalker': 'Planeswalker', 'rules_text': 'Contador de vida MTG.\n\n• Escolha 20 ou 40.\n• Use botões -5/-1/+1/+5.\n• Toque no nome para renomear.' },
      'nl': { 'title': 'Magic: The Gathering', 'start_life': 'Formaat', 'players': 'Spelers', 'reset': 'Reset', 'rules_title': 'Regels', 'ok': 'BEGREPEN', 'cancel': 'ANNULEREN', 'save': 'OPSLAAN', 'rename_title': 'Wijzigen', 'planeswalker': 'Planeswalker', 'rules_text': 'MTG Levensteller.\n\n• Kies 20 of 40.\n• Gebruik -5/-1/+1/+5 knoppen.\n• Tik op de naam om te wijzigen.' },
      'pl': { 'title': 'Magic: The Gathering', 'start_life': 'Format', 'players': 'Graczy', 'reset': 'Reset', 'rules_title': 'Zasady', 'ok': 'ZROZUMIAŁEM', 'cancel': 'ANULUJ', 'save': 'ZAPISZ', 'rename_title': 'Zmień nazwę', 'planeswalker': 'Planeswalker', 'rules_text': 'Licznik życia MTG.\n\n• Wybierz 20 lub 40.\n• Użyj przycisków -5/-1/+1/+5.\n• Dotknij nazwy, aby zmienić.' },
      'tr': { 'title': 'Magic: The Gathering', 'start_life': 'Format', 'players': 'Oyuncular', 'reset': 'Sıfırla', 'rules_title': 'Kurallar', 'ok': 'ANLADIM', 'cancel': 'İPTAL', 'save': 'KAYDET', 'rename_title': 'İsim Değiştir', 'planeswalker': 'Planeswalker', 'rules_text': 'MTG Can Sayacı.\n\n• 20 veya 40 seçin.\n• -5/-1/+1/+5 kullanın.\n• İsme dokunarak değiştirin.' },
      'id': { 'title': 'Magic: The Gathering', 'start_life': 'Format', 'players': 'Pemain', 'reset': 'Reset', 'rules_title': 'Aturan', 'ok': 'MENGERTI', 'cancel': 'BATAL', 'save': 'SIMPAN', 'rename_title': 'Ubah Nama', 'planeswalker': 'Planeswalker', 'rules_text': 'Penghitung nyawa MTG.\n\n• Pilih 20 atau 40.\n• Gunakan tombol -5/-1/+1/+5.\n• Ketuk nama untuk mengubah.' },
      'sv': { 'title': 'Magic: The Gathering', 'start_life': 'Format', 'players': 'Spelare', 'reset': 'Återställ', 'rules_title': 'Regler', 'ok': 'FÖRSTÅTT', 'cancel': 'AVBRYT', 'save': 'SPARA', 'rename_title': 'Byt namn', 'planeswalker': 'Planeswalker', 'rules_text': 'MTG Livräknare.\n\n• Välj 20 eller 40.\n• Använd -5/-1/+1/+5 knappar.\n• Tryck på namnet för att byta.' },
      'hr': { 'title': 'Magic: The Gathering', 'start_life': 'Format', 'players': 'Igrača', 'reset': 'Reset', 'rules_title': 'Pravila', 'ok': 'RAZUMIJEM', 'cancel': 'ODUSTANI', 'save': 'SPREMI', 'rename_title': 'Promijeni ime', 'planeswalker': 'Planeswalker', 'rules_text': 'MTG Brojač života.\n\n• Odaberi 20 ili 40.\n• Koristi tipke -5/-1/+1/+5.\n• Dodirni ime za promjenu.' },
      'ru': { 'title': 'Magic: The Gathering', 'start_life': 'Формат', 'players': 'Игроков', 'reset': 'Сброс', 'rules_title': 'Правила', 'ok': 'ПОНЯТНО', 'cancel': 'ОТМЕНА', 'save': 'СОХРАНИТЬ', 'rename_title': 'Переименовать', 'planeswalker': 'Planeswalker', 'rules_text': 'Счетчик жизней MTG.\n\n• Выберите 20 или 40.\n• Используйте кнопки -5/-1/+1/+5.\n• Нажмите на имя, чтобы изменить.' },
      'ja': { 'title': 'マジック：ザ・ギャザリング', 'start_life': 'フォーマット', 'players': 'プレイヤー', 'reset': 'リセット', 'rules_title': 'ルール', 'ok': '了解', 'cancel': 'キャンセル', 'save': '保存', 'rename_title': '名前を変更', 'planeswalker': 'プレインズウォーカー', 'rules_text': 'MTGライフカウンター。\n\n• 20または40を選択。\n• -5/-1/+1/+5ボタンを使用。\n• 名前をタップして変更。' },
      'ko': { 'title': '매직: 더 개더링', 'start_life': '포맷', 'players': '플레이어', 'reset': '초기화', 'rules_title': '규칙', 'ok': '확인', 'cancel': '취소', 'save': '저장', 'rename_title': '이름 변경', 'planeswalker': '플레인즈워커', 'rules_text': 'MTG 라이프 카운터.\n\n• 20 또는 40 선택.\n• -5/-1/+1/+5 버튼 사용.\n• 이름을 탭하여 변경.' },
      'zh': { 'title': '万智牌', 'start_life': '赛制', 'players': '玩家', 'reset': '重置', 'rules_title': '规则', 'ok': '明白了', 'cancel': '取消', 'save': '保存', 'rename_title': '重命名', 'planeswalker': '鹏洛客', 'rules_text': 'MTG 生命计数器。\n\n• 选择 20 或 40。\n• 使用 -5/-1/+1/+5 按钮。\n• 点击名字重命名。' },
      'hi': { 'title': 'मैजिक: द गैदरिंग', 'start_life': 'प्रारूप', 'players': 'खिलाड़ी', 'reset': 'रीसेट', 'rules_title': 'नियम', 'ok': 'समझ गया', 'cancel': 'रद्द करें', 'save': 'सहेजें', 'rename_title': 'नाम बदलें', 'planeswalker': 'प्लेनस्वॉकर', 'rules_text': 'MTG लाइफ काउंटर।\n\n• 20 या 40 चुनें।\n• -5/-1/+1/+5 बटन का उपयोग करें।\n• नाम बदलने के लिए टैप करें।' },
      'bn': { 'title': 'ম্যাজিক: দ্য গ্যাদারিং', 'start_life': 'ফরম্যাট', 'players': 'খেলোয়াড়', 'reset': 'রিসেট', 'rules_title': 'নিয়ম', 'ok': 'বুঝেছি', 'cancel': 'বাতিল', 'save': 'সংরক্ষণ', 'rename_title': 'নাম পরিবর্তন', 'planeswalker': 'প্লেনসওয়াকার', 'rules_text': 'MTG লাইফ কাউন্টার।\n\n• ২০ বা ৪০ নির্বাচন করুন।\n• -৫/-১/+১/+৫ বোতাম ব্যবহার করুন।\n• নাম পরিবর্তন করতে ট্যাপ করুন।' },
      'ar': { 'title': 'ماجيك: ذا جاذرنج', 'start_life': 'التنسيق', 'players': 'اللاعبين', 'reset': 'إعادة تعيين', 'rules_title': 'قواعد', 'ok': 'فهمت', 'cancel': 'إلغاء', 'save': 'حفظ', 'rename_title': 'تغيير الاسم', 'planeswalker': 'بلينزووكر', 'rules_text': 'عداد حياة MTG.\n\n• اختر 20 أو 40.\n• استخدم أزرار -5/-1/+1/+5.\n• اضغط على الاسم لتغييره.' },
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
        'name': '${_t('planeswalker')} ${index + 1}',
        'life': startLife,
      });
      _activeMenu = 0;
    });
  }

  void _updateLife(int index, int amount) {
    HapticFeedback.selectionClick();
    setState(() {
      players[index]['life'] += amount;
      _activeMenu = 0;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: primaryColor)),
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
    return GestureDetector(
      onTap: () {
        if (_activeMenu != 0) setState(() => _activeMenu = 0);
      },
      child: Scaffold(
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildConfigButton(
                          icon: Icons.favorite,
                          label: startLife == 20 ? "Standard" : "Commander",
                          title: _t('start_life'),
                          isActive: _activeMenu == 1,
                          onTap: () => setState(() => _activeMenu = _activeMenu == 1 ? 0 : 1),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildConfigButton(
                          icon: Icons.groups,
                          label: "$playerCount",
                          title: _t('players'),
                          isActive: _activeMenu == 2,
                          onTap: () => setState(() => _activeMenu = _activeMenu == 2 ? 0 : 2),
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

                  // --- INLINE SCHIEBEREGLER / AUSWAHL ---
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _activeMenu != 0 ? 70 : 0,
                    margin: EdgeInsets.only(top: _activeMenu != 0 ? 15 : 0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _activeMenu == 1
                            ? _buildLifeOptions()
                            : (_activeMenu == 2 ? _buildPlayerOptions() : []),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- GAME AREA ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: playerCount == 2
                    ? _buildTwoPlayerLayout()
                    : _buildGridPlayerLayout(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLifeOptions() {
    // Bei MTG gibt es in der Regel primär 20 (Standard/Modern) und 40 (Commander).
    // Wir bieten auch 30 (Brawl) an.
    final options = [20, 30, 40];
    return options.map((val) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ChoiceChip(
        label: Text("$val", style: TextStyle(color: startLife == val ? Colors.black : Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        selected: startLife == val,
        selectedColor: primaryColor,
        backgroundColor: surfaceColor,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        onSelected: (_) {
          setState(() {
            startLife = val;
            _activeMenu = 0;
            _resetGame();
          });
        },
      ),
    )).toList();
  }

  List<Widget> _buildPlayerOptions() {
    // Bei MTG Commander sind 3 bis 6 Spieler üblich
    return [2, 3, 4, 5, 6].map((val) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ChoiceChip(
        label: Text("$val", style: TextStyle(color: playerCount == val ? Colors.black : Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        selected: playerCount == val,
        selectedColor: primaryColor,
        backgroundColor: surfaceColor,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        onSelected: (_) {
          setState(() {
            playerCount = val;
            _activeMenu = 0;
            _resetGame();
          });
        },
      ),
    )).toList();
  }

  Widget _buildConfigButton({required IconData icon, required String label, required String title, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 60,
        decoration: BoxDecoration(
          color: isActive ? primaryColor.withAlpha(40) : surfaceColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isActive ? primaryColor : primaryColor.withAlpha(50), width: isActive ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 12), // NEU: Padding links vom Icon
            Icon(icon, color: primaryColor, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isActive ? primaryColor : Colors.grey, fontSize: 10)),
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                ],
              ),
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
          child: _MtgCard(
            name: players[0]['name'],
            life: players[0]['life'],
            color: primaryColor,
            onChanged: (val) => _updateLife(0, val),
            onRename: () => _showRenameDialog(0),
          ),
        ),
        const SizedBox(height: 15),
        // P2
        Expanded(
          child: _MtgCard(
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
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: playerCount > 4 ? 0.7 : 0.85, // Bei 5-6 Spielern Karten etwas höher strecken
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: playerCount,
      itemBuilder: (context, index) {
        return _MtgCard(
          name: players[index]['name'],
          life: players[index]['life'],
          color: primaryColor,
          onChanged: (val) => _updateLife(index, val),
          onRename: () => _showRenameDialog(index),
        );
      },
    );
  }
}

// --- KARTE WIDGET FÜR MTG ---
class _MtgCard extends StatelessWidget {
  final String name;
  final int life;
  final Color color;
  final Function(int) onChanged;
  final VoidCallback onRename;

  const _MtgCard({required this.name, required this.life, required this.color, required this.onChanged, required this.onRename});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF30363B),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Name (klickbar)
          GestureDetector(
            onTap: onRename,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: Text(name, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Icon(Icons.edit, size: 14, color: color.withOpacity(0.5)),
                ],
              ),
            ),
          ),

          // Life
          Expanded(
            child: Center(
              child: Text(
                  "$life",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 80, height: 1.0)
              ),
            ),
          ),

          // MTG spezifische Buttons (Bottom)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(-5),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(23)),
                  child: Container(
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(23)),
                    ),
                    child: const Center(child: Text("-5", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
              Container(width: 1, height: 60, color: Colors.white10),
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(-1),
                  child: Container(
                    height: 60,
                    color: Colors.black26,
                    child: const Center(child: Text("-1", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
              Container(width: 1, height: 60, color: Colors.white10),
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(1),
                  child: Container(
                    height: 60,
                    color: Colors.black26,
                    child: const Center(child: Text("+1", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
              Container(width: 1, height: 60, color: Colors.white10),
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(5),
                  borderRadius: const BorderRadius.only(bottomRight: Radius.circular(23)),
                  child: Container(
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.only(bottomRight: Radius.circular(23)),
                    ),
                    child: const Center(child: Text("+5", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
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