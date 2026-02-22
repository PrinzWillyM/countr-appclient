import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _currentLang = 'en';
  JassMode? _selectedMode;

  // Schieber State
  int team1Score = 0;
  int team2Score = 0;
  List<Map<String, int>> history = [];
  String _currentInput = "";
  bool _isWeisMode = false; // Wenn true: Punkte werden direkt addiert (kein Split)

  // Differenzler State
  bool _diffGameStarted = false;
  List<Map<String, dynamic>> diffPlayers = [];
  final TextEditingController _nameController = TextEditingController();

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
        'rules_text': 'Wähle deinen Modus:\n\n• Schieber: Gib die Punkte eines Teams ein. Der Rest von 157 geht automatisch an das andere Team.\n\nFür Weisen (Bonus): Aktiviere den Stern-Button. Dann werden Punkte direkt addiert.\n\n• Differenzler: Füge Spieler hinzu. In jeder Runde sagt man Punkte an und trägt danach das Resultat ein.',
        'add_hint': 'Name',
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
        'rules_text': 'Choose mode:\n\n• Schieber: Enter points for one team, remainder of 157 goes to the other.\n\nFor Bonus (Weis): Toggle the Star button. Points are added directly.\n\n• Differenzler: Add players. Predict score, then enter result.',
        'add_hint': 'Name',
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
        'rules_text': 'Mode :\n\n• Chibre : Entrez les points, le reste (sur 157) va à l\'autre équipe.\n\nPour les Annonces : Activez l\'étoile. Les points sont ajoutés directement.\n\n• Differenzler : Ajoutez des joueurs. Prédisez, puis notez le résultat.',
        'add_hint': 'Nom',
      },
      // Short versions for other languages (fallback logic applies)
      'it': { 'title': 'Jass', 'mode_schieber': 'Schieber', 'desc_schieber': 'Squadra vs Squadra.', 'mode_diff': 'Differenzler', 'desc_diff': 'Predizione punti.', 'team1': 'Noi', 'team2': 'Loro', 'weis_mode': 'Bonus', 'start': 'AVVIA', 'add_player': 'Aggiungi', 'penalty': 'Penalità' },
      'es': { 'title': 'Jass', 'mode_schieber': 'Schieber', 'desc_schieber': 'Equipo vs Equipo.', 'mode_diff': 'Differenzler', 'desc_diff': 'Predicción de puntos.', 'team1': 'Nosotros', 'team2': 'Ellos', 'weis_mode': 'Bono', 'start': 'INICIAR', 'add_player': 'Añadir', 'penalty': 'Penalización' },
      'pt': { 'title': 'Jass', 'mode_schieber': 'Schieber', 'desc_schieber': 'Equipe vs Equipe.', 'mode_diff': 'Differenzler', 'desc_diff': 'Previsão de pontos.', 'team1': 'Nós', 'team2': 'Eles', 'weis_mode': 'Bônus', 'start': 'INICIAR', 'add_player': 'Adicionar', 'penalty': 'Penalidade' },
      'nl': { 'title': 'Jassen', 'mode_schieber': 'Schieber', 'desc_schieber': 'Team vs Team.', 'mode_diff': 'Differenzler', 'desc_diff': 'Punten voorspellen.', 'team1': 'Wij', 'team2': 'Zij', 'weis_mode': 'Bonus', 'start': 'STARTEN', 'add_player': 'Toevoegen', 'penalty': 'Straf' },
      'pl': { 'title': 'Jass', 'mode_schieber': 'Schieber', 'desc_schieber': 'Drużyna vs Drużyna.', 'mode_diff': 'Differenzler', 'desc_diff': 'Przewidywanie punktów.', 'team1': 'My', 'team2': 'Oni', 'weis_mode': 'Bonus', 'start': 'START', 'add_player': 'Dodaj', 'penalty': 'Kara' },
      'tr': { 'title': 'Jass', 'mode_schieber': 'Schieber', 'desc_schieber': 'Takım vs Takım.', 'mode_diff': 'Differenzler', 'desc_diff': 'Puan tahmini.', 'team1': 'Biz', 'team2': 'Onlar', 'weis_mode': 'Bonus', 'start': 'BAŞLAT', 'add_player': 'Ekle', 'penalty': 'Ceza' },
      'id': { 'title': 'Jass', 'mode_schieber': 'Schieber', 'desc_schieber': 'Tim vs Tim.', 'mode_diff': 'Differenzler', 'desc_diff': 'Prediksi poin.', 'team1': 'Kami', 'team2': 'Mereka', 'weis_mode': 'Bonus', 'start': 'MULAI', 'add_player': 'Tambah', 'penalty': 'Hukuman' },
      'sv': { 'title': 'Jass', 'mode_schieber': 'Schieber', 'desc_schieber': 'Lag mot Lag.', 'mode_diff': 'Differenzler', 'desc_diff': 'Poängförutsägelse.', 'team1': 'Vi', 'team2': 'Dem', 'weis_mode': 'Bonus', 'start': 'STARTA', 'add_player': 'Lägg till', 'penalty': 'Straff' },
      'hr': { 'title': 'Jass', 'mode_schieber': 'Schieber', 'desc_schieber': 'Tim protiv Tima.', 'mode_diff': 'Differenzler', 'desc_diff': 'Predviđanje bodova.', 'team1': 'Mi', 'team2': 'Oni', 'weis_mode': 'Bonus', 'start': 'POKRENI', 'add_player': 'Dodaj', 'penalty': 'Kazna' },
      'ru': { 'title': 'Ясс', 'mode_schieber': 'Шибер', 'desc_schieber': 'Команда на команду.', 'mode_diff': 'Дифференцлер', 'desc_diff': 'Прогноз очков.', 'team1': 'Мы', 'team2': 'Они', 'weis_mode': 'Бонус', 'start': 'НАЧАТЬ', 'add_player': 'Добавить', 'penalty': 'Штраф' },
      'ja': { 'title': 'ヤス', 'mode_schieber': 'シーバー', 'desc_schieber': 'チーム対チーム。', 'mode_diff': 'ディフェレンツラー', 'desc_diff': 'ポイント予測。', 'team1': '私たち', 'team2': '彼ら', 'weis_mode': 'ボーナス', 'start': '開始', 'add_player': '追加', 'penalty': 'ペナルティ' },
      'ko': { 'title': '야스', 'mode_schieber': '쉬버', 'desc_schieber': '팀 대 팀.', 'mode_diff': '디퍼렌즐러', 'desc_diff': '점수 예측.', 'team1': '우리', 'team2': '그들', 'weis_mode': '보너스', 'start': '시작', 'add_player': '추가', 'penalty': '벌칙' },
      'zh': { 'title': '雅斯', 'mode_schieber': '席伯', 'desc_schieber': '团队对团队。', 'mode_diff': '差异赛', 'desc_diff': '分数预测。', 'team1': '我们', 'team2': '他们', 'weis_mode': '奖励', 'start': '开始', 'add_player': '添加', 'penalty': '惩罚' },
      'hi': { 'title': 'जैस', 'mode_schieber': 'शिबर', 'desc_schieber': 'टीम बनाम टीम।', 'mode_diff': 'डिफरेंसलर', 'desc_diff': 'अंक भविष्यवाणी।', 'team1': 'हम', 'team2': 'वे', 'weis_mode': 'बोनस', 'start': 'शुरू', 'add_player': 'जोड़ें', 'penalty': 'जुर्माना' },
      'bn': { 'title': 'জাস', 'mode_schieber': 'শিবার', 'desc_schieber': 'দল বনাম দল।', 'mode_diff': 'ডিফারেন্সলার', 'desc_diff': 'স্কোর পূর্বাভাস।', 'team1': 'আমরা', 'team2': 'তারা', 'weis_mode': 'বোনাস', 'start': 'শুরু', 'add_player': 'যোগ', 'penalty': 'জরিমানা' },
      'ar': { 'title': 'جاس', 'mode_schieber': 'شيبر', 'desc_schieber': 'فريق ضد فريق.', 'mode_diff': 'ديفيرنزلر', 'desc_diff': 'توقع النقاط.', 'team1': 'نحن', 'team2': 'هم', 'weis_mode': 'مكافأة', 'start': 'بدء', 'add_player': 'إضافة', 'penalty': 'عقوبة' },
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

    if (_isWeisMode) {
      // Weis Modus: Punkte werden direkt dem Team gutgeschrieben (kein Split von 157)
      if (isTeam1) t1Add = points;
      else t2Add = points;
    } else {
      // Stich Modus: Normales Jassen, Split von 157
      // Alles > 157 (z.B. Match 257) zählt voll, kein Split
      if (points <= 157) {
        if (isTeam1) {
          t1Add = points;
          t2Add = 157 - points;
        } else {
          t2Add = points;
          t1Add = 157 - points;
        }
      } else {
        // Matchpunkte (z.B. 157 + 100 = 257)
        if (isTeam1) t1Add = points;
        else t2Add = points;
      }
    }

    setState(() {
      team1Score += t1Add;
      team2Score += t2Add;
      history.add({'t1': t1Add, 't2': t2Add});
      _currentInput = "";
      _isWeisMode = false; // Reset weis mode after entry
    });
  }

  void _undo() {
    if (history.isNotEmpty) {
      var last = history.removeLast();
      setState(() {
        team1Score -= last['t1']!;
        team2Score -= last['t2']!;
      });
    }
  }

  // --- LOGIC: DIFFERENZLER ---

  void _addDiffPlayer() {
    if(_nameController.text.isNotEmpty) {
      setState(() {
        diffPlayers.add({
          'name': _nameController.text,
          'total_penalty': 0,
          'current_target': null, // Ansage
        });
        _nameController.clear();
      });
    }
  }

  void _startDiffGame() {
    if (diffPlayers.length < 2) return;
    setState(() {
      _diffGameStarted = true;
    });
  }

  void _submitDiffScore(int index, int madePoints) {
    var p = diffPlayers[index];
    if (p['current_target'] == null) {
      // Set Ansage
      setState(() {
        p['current_target'] = madePoints; // Reuse parameter as target
      });
    } else {
      // Calc Diff
      int target = p['current_target'];
      int diff = (target - madePoints).abs();
      setState(() {
        p['total_penalty'] += diff;
        p['current_target'] = null; // Reset für nächste Runde
      });
    }
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
          if (_selectedMode != null)
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() {
              _selectedMode = null;
              team1Score=0; team2Score=0; history.clear();
              diffPlayers.clear(); _diffGameStarted = false;
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _modeCard(JassMode.schieber, Icons.edit_note, _t('mode_schieber'), _t('desc_schieber')),
        const SizedBox(height: 15),
        _modeCard(JassMode.differenzler, Icons.track_changes, _t('mode_diff'), _t('desc_diff')),
      ],
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
    return Column(
      children: [
        // Score Display
        Expanded(
          flex: 4,
          child: Row(
            children: [
              _buildTeamColumn(_t('team1'), team1Score),
              Container(width: 2, color: Colors.black26),
              _buildTeamColumn(_t('team2'), team2Score),
            ],
          ),
        ),

        // Input Area
        Container(
          color: surfaceColor,
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              // Weis Toggle & Input Display
              Row(
                children: [
                  // Weis Toggle
                  GestureDetector(
                    onTap: () => setState(() => _isWeisMode = !_isWeisMode),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: _isWeisMode ? primaryColor : Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _isWeisMode ? Colors.white : Colors.transparent)
                      ),
                      child: Icon(Icons.star, color: _isWeisMode ? Colors.black : Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Display Input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              _isWeisMode ? _t('weis_on') : _t('weis_off'),
                              style: TextStyle(color: _isWeisMode ? primaryColor : Colors.grey, fontSize: 12)
                          ),
                          Text(
                            _currentInput.isEmpty ? "0" : _currentInput,
                            style: TextStyle(color: _currentInput.isEmpty ? Colors.white24 : Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Keypad
              _buildKeypad(),
              const SizedBox(height: 10),
              // Assign Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentInput.isEmpty ? null : () => _submitSchieberScore(true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _isWeisMode ? Colors.orange : primaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      child: Text(_t('team1'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.undo, color: Colors.grey),
                    onPressed: history.isEmpty ? null : _undo,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentInput.isEmpty ? null : () => _submitSchieberScore(false),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _isWeisMode ? Colors.orange : primaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      child: Text(_t('team2'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamColumn(String name, int score) {
    return Expanded(
      child: Container(
        color: bgColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(name, style: TextStyle(color: primaryColor, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("$score", style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ["1","2","3"].map(_keyBtn).toList()),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ["4","5","6"].map(_keyBtn).toList()),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ["7","8","9"].map(_keyBtn).toList()),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _iconKeyBtn(Icons.backspace, _backspace),
          _keyBtn("0"),
          const SizedBox(width: 80, height: 50),
        ]),
      ],
    );
  }

  Widget _keyBtn(String label) {
    return SizedBox(
      width: 80, height: 50,
      child: ElevatedButton(
        onPressed: () { HapticFeedback.selectionClick(); _addInput(label); },
        style: ElevatedButton.styleFrom(backgroundColor: activeColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _iconKeyBtn(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 80, height: 50,
      child: ElevatedButton(
        onPressed: () { HapticFeedback.selectionClick(); onTap(); },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.3), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: Icon(icon),
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

    // Game Phase
    return Column(
      children: [
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
            height: 500,
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
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                    mainAxisSpacing: 10, crossAxisSpacing: 10,
                    children: [
                      ...["1","2","3","4","5","6","7","8","9","0"].map((e) => ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: activeColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () => setModalState(() => buffer += e),
                        child: Text(e, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      )),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () => setModalState(() => buffer = ""),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () {
                          int val = int.tryParse(buffer) ?? 0;
                          _submitDiffScore(index, val);
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.check, color: Colors.black),
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
}