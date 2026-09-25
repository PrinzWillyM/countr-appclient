import '../../main.dart';
import 'mtg_i18n_art.dart';
import 'mtg_i18n_extra.dart';

// Übersetzungen für das MTG-Modul. Fehlende Keys fallen auf Englisch zurück.
String mtgT(String key) {
  final lang = appLocaleNotifier.value.languageCode;
  String? lookup(String l) => mtgArtTranslations[l]?[key] ?? mtgExtraTranslations[l]?[key] ?? _dictionary[l]?[key];
  return lookup(lang) ?? lookup('en') ?? key;
}

const Map<String, Map<String, String>> _dictionary = {
  'de': {
    'player': 'Spieler', 'restart': 'Neustart', 'players': 'Spieler', 'layout': 'Anordnung', 'start_life': 'Startleben',
    'high_roll': 'Wer beginnt?', 'dice': 'Würfel', 'help': 'Hilfe', 'exit': 'Beenden',
    'coin': 'Münze', 'heads': 'Kopf', 'tails': 'Zahl', 'tap_to_roll': 'Tippen zum Werfen',
    'poison': 'Gift', 'tax': 'Commander-Steuer', 'energy': 'Energie', 'experience': 'Erfahrung',
    'commander_damage': 'Commander-Schaden', 'counters': 'Marken', 'name': 'Name', 'color': 'Farbe', 'done': 'Fertig',
    'rules_title': 'Anleitung', 'ok': 'VERSTANDEN',
  },
  'en': {
    'player': 'Player', 'restart': 'Restart', 'players': 'Players', 'layout': 'Layout', 'start_life': 'Starting life',
    'high_roll': 'High roll', 'dice': 'Dice', 'help': 'Help', 'exit': 'Exit',
    'coin': 'Coin', 'heads': 'Heads', 'tails': 'Tails', 'tap_to_roll': 'Tap to roll',
    'poison': 'Poison', 'tax': 'Commander tax', 'energy': 'Energy', 'experience': 'Experience',
    'commander_damage': 'Commander damage', 'counters': 'Counters', 'name': 'Name', 'color': 'Color', 'done': 'Done',
    'rules_title': 'Rules', 'ok': 'GOT IT',
  },
  'fr': {
    'player': 'Joueur', 'restart': 'Recommencer', 'players': 'Joueurs', 'layout': 'Disposition', 'start_life': 'Points de vie',
    'high_roll': 'Qui commence ?', 'dice': 'Dés', 'help': 'Aide', 'exit': 'Quitter',
    'coin': 'Pièce', 'heads': 'Face', 'tails': 'Pile', 'tap_to_roll': 'Touchez pour lancer',
    'poison': 'Poison', 'tax': 'Taxe de commandant', 'energy': 'Énergie', 'experience': 'Expérience',
    'commander_damage': 'Blessures de commandant', 'counters': 'Marqueurs', 'name': 'Nom', 'color': 'Couleur', 'done': 'OK',
    'rules_title': 'Règles', 'ok': 'COMPRIS',
  },
  'it': {
    'player': 'Giocatore', 'restart': 'Ricomincia', 'players': 'Giocatori', 'layout': 'Disposizione', 'start_life': 'Punti vita',
    'high_roll': 'Chi inizia?', 'dice': 'Dadi', 'help': 'Aiuto', 'exit': 'Esci',
    'coin': 'Moneta', 'heads': 'Testa', 'tails': 'Croce', 'tap_to_roll': 'Tocca per lanciare',
    'poison': 'Veleno', 'tax': 'Tassa del comandante', 'energy': 'Energia', 'experience': 'Esperienza',
    'commander_damage': 'Danno del comandante', 'counters': 'Segnalini', 'name': 'Nome', 'color': 'Colore', 'done': 'Fatto',
    'rules_title': 'Regole', 'ok': 'CAPITO',
  },
  'es': {
    'player': 'Jugador', 'restart': 'Reiniciar', 'players': 'Jugadores', 'layout': 'Disposición', 'start_life': 'Vidas iniciales',
    'high_roll': '¿Quién empieza?', 'dice': 'Dados', 'help': 'Ayuda', 'exit': 'Salir',
    'coin': 'Moneda', 'heads': 'Cara', 'tails': 'Cruz', 'tap_to_roll': 'Toca para tirar',
    'poison': 'Veneno', 'tax': 'Impuesto de comandante', 'energy': 'Energía', 'experience': 'Experiencia',
    'commander_damage': 'Daño de comandante', 'counters': 'Contadores', 'name': 'Nombre', 'color': 'Color', 'done': 'Listo',
    'rules_title': 'Reglas', 'ok': 'ENTENDIDO',
  },
  'pt': {
    'player': 'Jogador', 'restart': 'Reiniciar', 'players': 'Jogadores', 'layout': 'Disposição', 'start_life': 'Vida inicial',
    'high_roll': 'Quem começa?', 'dice': 'Dados', 'help': 'Ajuda', 'exit': 'Sair',
    'coin': 'Moeda', 'heads': 'Cara', 'tails': 'Coroa', 'tap_to_roll': 'Toque para rolar',
    'poison': 'Veneno', 'tax': 'Taxa de comandante', 'energy': 'Energia', 'experience': 'Experiência',
    'commander_damage': 'Dano de comandante', 'counters': 'Marcadores', 'name': 'Nome', 'color': 'Cor', 'done': 'Pronto',
    'rules_title': 'Regras', 'ok': 'ENTENDIDO',
  },
  'nl': {
    'player': 'Speler', 'restart': 'Opnieuw', 'players': 'Spelers', 'layout': 'Indeling', 'start_life': 'Startleven',
    'high_roll': 'Wie begint?', 'dice': 'Dobbelstenen', 'help': 'Help', 'exit': 'Afsluiten',
    'coin': 'Munt', 'heads': 'Kop', 'tails': 'Munt', 'tap_to_roll': 'Tik om te gooien',
    'poison': 'Gif', 'tax': 'Commander-belasting', 'energy': 'Energie', 'experience': 'Ervaring',
    'commander_damage': 'Commander-schade', 'counters': 'Markers', 'name': 'Naam', 'color': 'Kleur', 'done': 'Klaar',
    'rules_title': 'Regels', 'ok': 'BEGREPEN',
  },
  'pl': {
    'player': 'Gracz', 'restart': 'Od nowa', 'players': 'Gracze', 'layout': 'Układ', 'start_life': 'Życie początkowe',
    'high_roll': 'Kto zaczyna?', 'dice': 'Kości', 'help': 'Pomoc', 'exit': 'Wyjdź',
    'coin': 'Moneta', 'heads': 'Orzeł', 'tails': 'Reszka', 'tap_to_roll': 'Dotknij, aby rzucić',
    'poison': 'Trucizna', 'tax': 'Podatek dowódcy', 'energy': 'Energia', 'experience': 'Doświadczenie',
    'commander_damage': 'Obrażenia dowódcy', 'counters': 'Znaczniki', 'name': 'Nazwa', 'color': 'Kolor', 'done': 'Gotowe',
    'rules_title': 'Zasady', 'ok': 'ZROZUMIAŁEM',
  },
  'tr': {
    'player': 'Oyuncu', 'restart': 'Yeniden başlat', 'players': 'Oyuncular', 'layout': 'Düzen', 'start_life': 'Başlangıç canı',
    'high_roll': 'Kim başlar?', 'dice': 'Zar', 'help': 'Yardım', 'exit': 'Çıkış',
    'coin': 'Yazı tura', 'heads': 'Tura', 'tails': 'Yazı', 'tap_to_roll': 'Atmak için dokun',
    'poison': 'Zehir', 'tax': 'Komutan vergisi', 'energy': 'Enerji', 'experience': 'Deneyim',
    'commander_damage': 'Komutan hasarı', 'counters': 'Sayaçlar', 'name': 'İsim', 'color': 'Renk', 'done': 'Tamam',
    'rules_title': 'Kurallar', 'ok': 'ANLADIM',
  },
  'id': {
    'player': 'Pemain', 'restart': 'Mulai ulang', 'players': 'Pemain', 'layout': 'Tata letak', 'start_life': 'Nyawa awal',
    'high_roll': 'Siapa mulai?', 'dice': 'Dadu', 'help': 'Bantuan', 'exit': 'Keluar',
    'coin': 'Koin', 'heads': 'Angka', 'tails': 'Gambar', 'tap_to_roll': 'Ketuk untuk melempar',
    'poison': 'Racun', 'tax': 'Pajak komandan', 'energy': 'Energi', 'experience': 'Pengalaman',
    'commander_damage': 'Kerusakan komandan', 'counters': 'Penanda', 'name': 'Nama', 'color': 'Warna', 'done': 'Selesai',
    'rules_title': 'Aturan', 'ok': 'MENGERTI',
  },
  'sv': {
    'player': 'Spelare', 'restart': 'Starta om', 'players': 'Spelare', 'layout': 'Layout', 'start_life': 'Startliv',
    'high_roll': 'Vem börjar?', 'dice': 'Tärningar', 'help': 'Hjälp', 'exit': 'Avsluta',
    'coin': 'Mynt', 'heads': 'Krona', 'tails': 'Klave', 'tap_to_roll': 'Tryck för att slå',
    'poison': 'Gift', 'tax': 'Commander-skatt', 'energy': 'Energi', 'experience': 'Erfarenhet',
    'commander_damage': 'Commander-skada', 'counters': 'Markörer', 'name': 'Namn', 'color': 'Färg', 'done': 'Klar',
    'rules_title': 'Regler', 'ok': 'FÖRSTÅTT',
  },
  'hr': {
    'player': 'Igrač', 'restart': 'Ponovo', 'players': 'Igrači', 'layout': 'Raspored', 'start_life': 'Početni život',
    'high_roll': 'Tko počinje?', 'dice': 'Kockice', 'help': 'Pomoć', 'exit': 'Izlaz',
    'coin': 'Novčić', 'heads': 'Glava', 'tails': 'Pismo', 'tap_to_roll': 'Dodirni za bacanje',
    'poison': 'Otrov', 'tax': 'Porez zapovjednika', 'energy': 'Energija', 'experience': 'Iskustvo',
    'commander_damage': 'Šteta zapovjednika', 'counters': 'Žetoni', 'name': 'Ime', 'color': 'Boja', 'done': 'Gotovo',
    'rules_title': 'Pravila', 'ok': 'RAZUMIJEM',
  },
  'ru': {
    'player': 'Игрок', 'restart': 'Заново', 'players': 'Игроки', 'layout': 'Расположение', 'start_life': 'Начальные жизни',
    'high_roll': 'Кто первый?', 'dice': 'Кубики', 'help': 'Помощь', 'exit': 'Выход',
    'coin': 'Монета', 'heads': 'Орёл', 'tails': 'Решка', 'tap_to_roll': 'Нажмите, чтобы бросить',
    'poison': 'Яд', 'tax': 'Налог командира', 'energy': 'Энергия', 'experience': 'Опыт',
    'commander_damage': 'Урон командира', 'counters': 'Счётчики', 'name': 'Имя', 'color': 'Цвет', 'done': 'Готово',
    'rules_title': 'Правила', 'ok': 'ПОНЯТНО',
  },
  'ja': {
    'player': 'プレイヤー', 'restart': 'リスタート', 'players': 'プレイヤー', 'layout': 'レイアウト', 'start_life': '初期ライフ',
    'high_roll': '先攻決め', 'dice': 'ダイス', 'help': 'ヘルプ', 'exit': '終了',
    'coin': 'コイン', 'heads': '表', 'tails': '裏', 'tap_to_roll': 'タップして振る',
    'poison': '毒', 'tax': '統率者税', 'energy': 'エネルギー', 'experience': '経験',
    'commander_damage': '統率者ダメージ', 'counters': 'カウンター', 'name': '名前', 'color': '色', 'done': '完了',
    'rules_title': 'ルール', 'ok': '了解',
  },
  'ko': {
    'player': '플레이어', 'restart': '다시 시작', 'players': '플레이어', 'layout': '배치', 'start_life': '시작 라이프',
    'high_roll': '선공 정하기', 'dice': '주사위', 'help': '도움말', 'exit': '나가기',
    'coin': '동전', 'heads': '앞면', 'tails': '뒷면', 'tap_to_roll': '탭하여 굴리기',
    'poison': '독', 'tax': '커맨더 세금', 'energy': '에너지', 'experience': '경험',
    'commander_damage': '커맨더 피해', 'counters': '카운터', 'name': '이름', 'color': '색상', 'done': '완료',
    'rules_title': '규칙', 'ok': '확인',
  },
  'zh': {
    'player': '玩家', 'restart': '重新开始', 'players': '玩家', 'layout': '布局', 'start_life': '初始生命',
    'high_roll': '谁先手？', 'dice': '骰子', 'help': '帮助', 'exit': '退出',
    'coin': '硬币', 'heads': '正面', 'tails': '反面', 'tap_to_roll': '点击投掷',
    'poison': '中毒', 'tax': '指挥官税', 'energy': '能量', 'experience': '经验',
    'commander_damage': '指挥官伤害', 'counters': '指示物', 'name': '名字', 'color': '颜色', 'done': '完成',
    'rules_title': '规则', 'ok': '明白了',
  },
  'hi': {
    'player': 'खिलाड़ी', 'restart': 'फिर से शुरू', 'players': 'खिलाड़ी', 'layout': 'लेआउट', 'start_life': 'शुरुआती जीवन',
    'high_roll': 'कौन शुरू करेगा?', 'dice': 'पासे', 'help': 'मदद', 'exit': 'बाहर निकलें',
    'coin': 'सिक्का', 'heads': 'चित', 'tails': 'पट', 'tap_to_roll': 'फेंकने के लिए टैप करें',
    'poison': 'विष', 'tax': 'कमांडर टैक्स', 'energy': 'ऊर्जा', 'experience': 'अनुभव',
    'commander_damage': 'कमांडर डैमेज', 'counters': 'काउंटर', 'name': 'नाम', 'color': 'रंग', 'done': 'हो गया',
    'rules_title': 'नियम', 'ok': 'समझ गया',
  },
  'bn': {
    'player': 'খেলোয়াড়', 'restart': 'আবার শুরু', 'players': 'খেলোয়াড়', 'layout': 'বিন্যাস', 'start_life': 'শুরুর জীবন',
    'high_roll': 'কে শুরু করবে?', 'dice': 'পাশা', 'help': 'সাহায্য', 'exit': 'বের হন',
    'coin': 'কয়েন', 'heads': 'হেড', 'tails': 'টেল', 'tap_to_roll': 'ছুড়তে ট্যাপ করুন',
    'poison': 'বিষ', 'tax': 'কমান্ডার ট্যাক্স', 'energy': 'শক্তি', 'experience': 'অভিজ্ঞতা',
    'commander_damage': 'কমান্ডার ড্যামেজ', 'counters': 'কাউন্টার', 'name': 'নাম', 'color': 'রং', 'done': 'সম্পন্ন',
    'rules_title': 'নিয়ম', 'ok': 'বুঝেছি',
  },
};
