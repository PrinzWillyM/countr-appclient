import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';

// Importiere deine Spiele hier
import 'games/fuck_the_neighbor.dart';
import 'games/standard_counter.dart';
import 'games/ten_thousand.dart';
import 'games/yazzee.dart';
import 'games/life_tracker.dart';
import 'games/magic_the_gathering.dart';
import 'games/pokemon_tcg.dart';
import 'games/jassen.dart';
import 'games/darts.dart';
import 'games/tournament.dart';

// --- KONSTANTEN ---
const Color brandYellow = Color(0xFFEBCB63);
const Color darkBackground = Color(0xFF222629);
const Color darkSurface = Color(0xFF30363B);
const Color textDark = Color(0xFF1B1F22);

// --- GLOBALER STATE FÜR SPRACHE ---
final ValueNotifier<Locale> appLocaleNotifier = ValueNotifier(const Locale('de'));

// --- TRANSLATION DATA ---
class AppTranslations {
  static final Map<String, Map<String, String>> _values = {
    'de': {
      'slogan': 'Ein Zähler für alle Spiele.',
      'game_cards': 'Karten', 'game_dice': 'Würfel', 'game_utility': 'Tools', 'game_other': 'Sonstiges',
      'filter_all': 'Alle', 'filter_fav': 'Favoriten', 'no_games_found': 'Keine Spiele gefunden',
      'no_favs': 'Noch keine Favoriten', 'empty': 'LEER', 'start': 'STARTEN', 'mail': 'MAIL SENDEN',
      'suggestion_btn': 'Spiel vorschlagen', 'made_with': 'Made with ♥️ in Switzerland',
      'info_title': 'Info & Einstellungen', 'about_title': 'Über Countr',
      'about_text': 'Countr ist ein kostenloses Hobby-Projekt. Einfach, werbefrei und ohne Tracking.',
      'impressum_title': 'Impressum & Kontakt', 'address': 'Sportlerweg 10\n8360 Eschlikon',
      'feedback_hint': 'Feedback ist herzlich willkommen!', 'language_title': 'Sprache / Language',
      'player_suffix': 'Spieler', 'heart_clicks': 'Mal auf das Herz geklickt',
      'hidden_games_title': 'Ausgeblendete Spiele', 'hidden_games_empty': 'Keine ausgeblendeten Spiele',
      'restore': 'Wiederherstellen',
      'msg_hidden': 'Spiel ausgeblendet',
      'msg_fav_added': 'Zu Favoriten hinzugefügt',
      'msg_fav_removed': 'Aus Favoriten entfernt',
      'game_title_std': 'Standard Counter',
      'game_title_tourney': 'Turnier',
      'game_title_life': 'Life Tracker',
      'game_title_jass': 'Jass (Schieber)',
      'game_title_ftn': 'Fuck the Neighbor',
      'game_title_mtg': 'Magic: The Gathering',
      'game_title_pkm': 'Pokémon TCG',
      'game_title_darts': 'Darts X01',
      'game_title_yazzee': 'Yazzee',
      'game_title_10k': '10\'000 (Farkle)',
    },
    'en': {
      'slogan': 'One counter for all games.',
      'game_cards': 'Cards', 'game_dice': 'Dice', 'game_utility': 'Tools', 'game_other': 'Other',
      'filter_all': 'All', 'filter_fav': 'Favorites', 'no_games_found': 'No games found',
      'no_favs': 'No favorites yet', 'empty': 'EMPTY', 'start': 'START', 'mail': 'SEND MAIL',
      'suggestion_btn': 'Suggest a Game', 'made_with': 'Made with ♥️ in Switzerland',
      'info_title': 'Info & Settings', 'about_title': 'About Countr',
      'about_text': 'Countr is a free hobby project. Simple, ad-free and no tracking.',
      'impressum_title': 'Imprint & Contact', 'address': 'Sportlerweg 10\n8360 Eschlikon\nSwitzerland',
      'feedback_hint': 'Feedback is very welcome!', 'language_title': 'Language',
      'player_suffix': 'Players', 'heart_clicks': 'Times clicked on the heart',
      'hidden_games_title': 'Hidden Games', 'hidden_games_empty': 'No hidden games',
      'restore': 'Restore',
      'msg_hidden': 'Game hidden',
      'msg_fav_added': 'Added to favorites',
      'msg_fav_removed': 'Removed from favorites',
      'game_title_std': 'Standard Counter',
      'game_title_tourney': 'Tournament',
      'game_title_life': 'Life Tracker',
      'game_title_jass': 'Jass (Schieber)',
      'game_title_ftn': 'Fuck the Neighbor',
      'game_title_mtg': 'Magic: The Gathering',
      'game_title_pkm': 'Pokémon TCG',
      'game_title_darts': 'Darts X01',
      'game_title_yazzee': 'Yazzee',
      'game_title_10k': '10\'000 (Farkle)',
    },
    'fr': {
      'slogan': 'Un compteur pour tous les jeux.',
      'game_cards': 'Cartes', 'game_dice': 'Dés', 'game_utility': 'Outils', 'game_other': 'Divers',
      'filter_all': 'Tous', 'filter_fav': 'Favoris', 'no_games_found': 'Aucun jeu trouvé',
      'no_favs': 'Pas encore de favoris', 'empty': 'VIDE', 'start': 'DÉMARRER', 'mail': 'ENVOYER MAIL',
      'suggestion_btn': 'Suggérer un jeu', 'made_with': 'Fait avec ♥️ en Suisse',
      'info_title': 'Info & Réglages', 'about_title': 'À propos', 'about_text': 'Projet hobby gratuit. Simple et sans publicité.',
      'impressum_title': 'Mentions légales', 'address': 'Sportlerweg 10\n8360 Eschlikon\nSuisse',
      'feedback_hint': 'Vos retours sont les bienvenus!', 'language_title': 'Langue',
      'player_suffix': 'Joueurs', 'heart_clicks': 'Fois cliqué sur le cœur',
      'hidden_games_title': 'Jeux masqués', 'hidden_games_empty': 'Aucun jeu masqué',
      'restore': 'Restaurer',
      'msg_hidden': 'Jeu masqué',
      'msg_fav_added': 'Ajouté aux favoris',
      'msg_fav_removed': 'Retiré des favoris',
      'game_title_std': 'Compteur Standard',
      'game_title_tourney': 'Tournoi',
      'game_title_life': 'Compteur de Vie',
      'game_title_jass': 'Jass (Chibre)',
      'game_title_ftn': 'Fuck the Neighbor',
      'game_title_mtg': 'Magic: The Gathering',
      'game_title_pkm': 'Pokémon TCG',
      'game_title_darts': 'Fléchettes X01',
      'game_title_yazzee': 'Yazzee',
      'game_title_10k': '10\'000 (Farkle)',
    },
    'it': { 'slogan': 'Un contatore per tutti i giochi.', 'heart_clicks': 'Volte cliccato sul cuore', 'hidden_games_title': 'Giochi nascosti', 'restore': 'Ripristina', 'msg_hidden': 'Gioco nascosto', 'msg_fav_added': 'Aggiunto ai preferiti', 'msg_fav_removed': 'Rimosso dai preferiti', 'game_title_std': 'Contatore Standard', 'game_title_tourney': 'Torneo', 'game_title_life': 'Contatore Vita', 'game_title_jass': 'Jass', 'game_title_ftn': 'Fuck the Neighbor', 'game_title_mtg': 'Magic: The Gathering', 'game_title_pkm': 'Pokémon TCG', 'game_title_darts': 'Freccette X01', 'game_title_yazzee': 'Yazzee', 'game_title_10k': '10\'000 (Farkle)' },
    'es': { 'slogan': 'Un contador para todos los juegos.', 'heart_clicks': 'Veces pulsado el corazón', 'hidden_games_title': 'Juegos ocultos', 'restore': 'Restaurar', 'msg_hidden': 'Juego oculto', 'msg_fav_added': 'Añadido a favoritos', 'msg_fav_removed': 'Eliminado de favoritos', 'game_title_std': 'Contador Estándar', 'game_title_tourney': 'Torneo', 'game_title_life': 'Contador de Vida', 'game_title_jass': 'Jass', 'game_title_ftn': 'Fuck the Neighbor', 'game_title_mtg': 'Magic: The Gathering', 'game_title_pkm': 'Pokémon TCG', 'game_title_darts': 'Dardos X01', 'game_title_yazzee': 'Yazzee', 'game_title_10k': '10\'000 (Farkle)' },
    'pt': { 'slogan': 'Um contador para todos os jogos.', 'heart_clicks': 'Vezes clicado no coração', 'hidden_games_title': 'Jogos ocultos', 'restore': 'Restaurar', 'msg_hidden': 'Jogo oculto', 'msg_fav_added': 'Adicionado aos favoritos', 'msg_fav_removed': 'Removido dos favoritos', 'game_title_std': 'Contador Padrão', 'game_title_tourney': 'Torneio', 'game_title_life': 'Contador de Vida', 'game_title_jass': 'Jass', 'game_title_ftn': 'Fuck the Neighbor', 'game_title_mtg': 'Magic: The Gathering', 'game_title_pkm': 'Pokémon TCG', 'game_title_darts': 'Dardos X01', 'game_title_yazzee': 'Yazzee', 'game_title_10k': '10\'000 (Farkle)' },
    'nl': { 'slogan': 'Een teller voor alle spellen.', 'heart_clicks': 'Keer op het hart geklikt', 'hidden_games_title': 'Verborgen spellen', 'restore': 'Herstellen', 'msg_hidden': 'Spel verborgen', 'msg_fav_added': 'Toegevoegd aan favorieten', 'msg_fav_removed': 'Verwijderd uit favorieten', 'game_title_std': 'Standaard Teller', 'game_title_tourney': 'Toernooi', 'game_title_life': 'Levensteller', 'game_title_jass': 'Jass', 'game_title_ftn': 'Fuck the Neighbor', 'game_title_mtg': 'Magic: The Gathering', 'game_title_pkm': 'Pokémon TCG', 'game_title_darts': 'Darts X01', 'game_title_yazzee': 'Yazzee', 'game_title_10k': '10\'000 (Farkle)' },
    'pl': { 'slogan': 'Jeden licznik do wszystkich gier.', 'heart_clicks': 'Razy kliknięto w serce', 'hidden_games_title': 'Ukryte gry', 'restore': 'Przywróć', 'msg_hidden': 'Gra ukryta', 'msg_fav_added': 'Dodano do ulubionych', 'msg_fav_removed': 'Usunięto z ulubionych', 'game_title_std': 'Standardowy Licznik', 'game_title_tourney': 'Turniej', 'game_title_life': 'Licznik Życia', 'game_title_jass': 'Jass', 'game_title_ftn': 'Fuck the Neighbor', 'game_title_mtg': 'Magic: The Gathering', 'game_title_pkm': 'Pokémon TCG', 'game_title_darts': 'Rzutki X01', 'game_title_yazzee': 'Yazzee', 'game_title_10k': '10\'000 (Farkle)' },
    'tr': { 'slogan': 'Tüm oyunlar için bir sayaç.', 'heart_clicks': 'Kalbe tıklanma sayısı', 'hidden_games_title': 'Gizli Oyunlar', 'restore': 'Geri Yükle', 'msg_hidden': 'Oyun gizlendi', 'msg_fav_added': 'Favorilere eklendi', 'msg_fav_removed': 'Favorilerden kaldırıldı', 'game_title_std': 'Standart Sayaç', 'game_title_tourney': 'Turnuva', 'game_title_life': 'Can Sayacı', 'game_title_jass': 'Jass', 'game_title_ftn': 'Fuck the Neighbor', 'game_title_mtg': 'Magic: The Gathering', 'game_title_pkm': 'Pokémon TCG', 'game_title_darts': 'Dart X01', 'game_title_yazzee': 'Yazzee', 'game_title_10k': '10\'000 (Farkle)' },
    'id': { 'slogan': 'Satu penghitung untuk semua game.', 'heart_clicks': 'Kali hati diklik', 'hidden_games_title': 'Game Tersembunyi', 'restore': 'Pulihkan', 'msg_hidden': 'Game disembunyikan', 'msg_fav_added': 'Ditambahkan ke favorit', 'msg_fav_removed': 'Dihapus dari favorit', 'game_title_std': 'Penghitung Standar', 'game_title_tourney': 'Turnamen', 'game_title_life': 'Pelacak Nyawa', 'game_title_jass': 'Jass', 'game_title_ftn': 'Fuck the Neighbor', 'game_title_mtg': 'Magic: The Gathering', 'game_title_pkm': 'Pokémon TCG', 'game_title_darts': 'Darts X01', 'game_title_yazzee': 'Yazzee', 'game_title_10k': '10\'000 (Farkle)' },
    'sv': { 'slogan': 'En räknare för alla spel.', 'heart_clicks': 'Gånger klickat på hjärtat', 'hidden_games_title': 'Dolda spel', 'restore': 'Återställ', 'msg_hidden': 'Spel dolt', 'msg_fav_added': 'Tillagd i favoriter', 'msg_fav_removed': 'Borttagen från favoriter', 'game_title_std': 'Standardräknare', 'game_title_tourney': 'Turnering', 'game_title_life': 'Livräknare', 'game_title_jass': 'Jass', 'game_title_ftn': 'Fuck the Neighbor', 'game_title_mtg': 'Magic: The Gathering', 'game_title_pkm': 'Pokémon TCG', 'game_title_darts': 'Dart X01', 'game_title_yazzee': 'Yazzee', 'game_title_10k': '10\'000 (Farkle)' },
    'hr': { 'slogan': 'Jedan brojač za sve igre.', 'heart_clicks': 'Puta kliknuto na srce', 'hidden_games_title': 'Skrivene igre', 'restore': 'Vrati', 'msg_hidden': 'Igra skrivena', 'msg_fav_added': 'Dodano u favorite', 'msg_fav_removed': 'Uklonjeno iz favorita', 'game_title_std': 'Standardni Brojač', 'game_title_tourney': 'Turnir', 'game_title_life': 'Praćenje života', 'game_title_jass': 'Jass', 'game_title_ftn': 'Fuck the Neighbor', 'game_title_mtg': 'Magic: The Gathering', 'game_title_pkm': 'Pokémon TCG', 'game_title_darts': 'Pikado X01', 'game_title_yazzee': 'Yazzee', 'game_title_10k': '10\'000 (Farkle)' },
    'ru': { 'slogan': 'Один счетчик для всех игр.', 'heart_clicks': 'Раз нажато на сердце', 'hidden_games_title': 'Скрытые игры', 'restore': 'Восстановить', 'msg_hidden': 'Игра скрыта', 'msg_fav_added': 'Добавлено в избранное', 'msg_fav_removed': 'Удалено из избранного', 'game_title_std': 'Стандартный счетчик', 'game_title_tourney': 'Турнир', 'game_title_life': 'Счетчик жизни', 'game_title_jass': 'Jass', 'game_title_ftn': 'Fuck the Neighbor', 'game_title_mtg': 'Magic: The Gathering', 'game_title_pkm': 'Pokémon TCG', 'game_title_darts': 'Дартс X01', 'game_title_yazzee': 'Yazzee', 'game_title_10k': '10\'000 (Farkle)' },
    'ja': { 'slogan': 'すべてのゲームのためのカウンター。', 'heart_clicks': 'ハートをクリックした回数', 'hidden_games_title': '非表示のゲーム', 'restore': '復元', 'msg_hidden': 'ゲームを非表示にしました', 'msg_fav_added': 'お気に入りに追加しました', 'msg_fav_removed': 'お気に入りから削除しました', 'game_title_std': '標準カウンター', 'game_title_tourney': 'トーナメント', 'game_title_life': 'ライフカウンター', 'game_title_jass': 'Jass', 'game_title_ftn': 'Fuck the Neighbor', 'game_title_mtg': 'Magic: The Gathering', 'game_title_pkm': 'Pokémon TCG', 'game_title_darts': 'ダーツ X01', 'game_title_yazzee': 'Yazzee', 'game_title_10k': '10\'000 (Farkle)' },
    'ko': { 'slogan': '모든 게임을 위한 카운터.', 'heart_clicks': '하트 클릭 횟수', 'hidden_games_title': '숨겨진 게임', 'restore': '복원', 'msg_hidden': '게임 숨김', 'msg_fav_added': '즐겨찾기에 추가됨', 'msg_fav_removed': '즐겨찾기에서 제거됨', 'game_title_std': '기본 카운터', 'game_title_tourney': '토너먼트', 'game_title_life': '라이프 트래커', 'game_title_jass': 'Jass', 'game_title_ftn': 'Fuck the Neighbor', 'game_title_mtg': 'Magic: The Gathering', 'game_title_pkm': 'Pokémon TCG', 'game_title_darts': '다트 X01', 'game_title_yazzee': 'Yazzee', 'game_title_10k': '10\'000 (Farkle)' },
    'zh': { 'slogan': '所有游戏的一个计数器。', 'heart_clicks': '点击爱心次数', 'hidden_games_title': '隐藏的游戏', 'restore': '恢复', 'msg_hidden': '游戏已隐藏', 'msg_fav_added': '已添加到收藏', 'msg_fav_removed': '已从收藏移除', 'game_title_std': '标准计数器', 'game_title_tourney': '锦标赛', 'game_title_life': '生命计数器', 'game_title_jass': 'Jass', 'game_title_ftn': 'Fuck the Neighbor', 'game_title_mtg': 'Magic: The Gathering', 'game_title_pkm': 'Pokémon TCG', 'game_title_darts': '飞镖 X01', 'game_title_yazzee': 'Yazzee', 'game_title_10k': '10\'000 (Farkle)' },
    'hi': { 'slogan': 'सभी खेलों के लिए एक काउंटर।', 'heart_clicks': 'बार दिल पर क्लिक किया', 'hidden_games_title': 'छिपे हुए खेल', 'restore': 'पुनर्स्थापित करें', 'msg_hidden': 'खेल छिपा दिया गया', 'msg_fav_added': 'पसंदीदा में जोड़ा गया', 'msg_fav_removed': 'पसंदीदा से हटाया गया', 'game_title_std': 'मानक काउंटर', 'game_title_tourney': 'टूर्नामेंट', 'game_title_life': 'जीवन ट्रैकर', 'game_title_jass': 'Jass', 'game_title_ftn': 'Fuck the Neighbor', 'game_title_mtg': 'Magic: The Gathering', 'game_title_pkm': 'Pokémon TCG', 'game_title_darts': 'डार्ट्स X01', 'game_title_yazzee': 'Yazzee', 'game_title_10k': '10\'000 (Farkle)' },
    'bn': { 'slogan': 'সমস্ত গেমের জন্য একটি কাউন্টার।', 'heart_clicks': 'হার্টে ক্লিক করার সংখ্যা', 'hidden_games_title': 'লুকানো গেম', 'restore': 'পুনরুদ্ধার করুন', 'msg_hidden': 'গেম লুকানো হয়েছে', 'msg_fav_added': 'প্রিয়তে যোগ করা হয়েছে', 'msg_fav_removed': 'প্রিয় থেকে সরানো হয়েছে', 'game_title_std': 'স্ট্যান্ডার্ড কাউন্টার', 'game_title_tourney': 'টুর্নামেন্ট', 'game_title_life': 'লাইফ ট্র্যাকার', 'game_title_jass': 'Jass', 'game_title_ftn': 'Fuck the Neighbor', 'game_title_mtg': 'Magic: The Gathering', 'game_title_pkm': 'Pokémon TCG', 'game_title_darts': 'ডার্টস X01', 'game_title_yazzee': 'Yazzee', 'game_title_10k': '10\'000 (Farkle)' },
    'ar': { 'slogan': 'عداد واحد لجميع الألعاب.', 'heart_clicks': 'مرات النقر على القلب', 'hidden_games_title': 'الألعاب المخفية', 'restore': 'استعادة', 'msg_hidden': 'تم إخفاء اللعبة', 'msg_fav_added': 'تمت الإضافة للمفضلة', 'msg_fav_removed': 'تمت الإزالة من المفضلة', 'game_title_std': 'العداد القياسي', 'game_title_tourney': 'دورة', 'game_title_life': 'تتبع الحياة', 'game_title_jass': 'Jass', 'game_title_ftn': 'Fuck the Neighbor', 'game_title_mtg': 'Magic: The Gathering', 'game_title_pkm': 'Pokémon TCG', 'game_title_darts': 'سهام X01', 'game_title_yazzee': 'Yazzee', 'game_title_10k': '10\'000 (Farkle)' },
  };

  static String get(String key) {
    String langCode = appLocaleNotifier.value.languageCode;
    if (_values.containsKey(langCode) && _values[langCode]!.containsKey(key)) {
      return _values[langCode]![key]!;
    }
    return _values['de']?[key] ?? key;
  }
}

// --- HELPERS ---
final Map<String, String> languageMap = {
  'de': 'Deutsch', 'en': 'English', 'fr': 'Français', 'it': 'Italiano',
  'es': 'Español', 'pt': 'Português', 'nl': 'Nederlands', 'pl': 'Polski',
  'tr': 'Türkçe', 'id': 'Indonesia', 'sv': 'Svenska', 'hr': 'Hrvatski',
  'ru': 'Русский', 'ja': '日本語', 'ko': '한국어', 'zh': '中文',
  'hi': 'हिन्दी', 'bn': 'বাংলা', 'ar': 'العربية',
};

enum GameCategory { card, dice, utility, other }

extension GameCategoryExtension on GameCategory {
  String get displayName {
    switch (this) {
      case GameCategory.card: return AppTranslations.get('game_cards');
      case GameCategory.dice: return AppTranslations.get('game_dice');
      case GameCategory.utility: return AppTranslations.get('game_utility');
      case GameCategory.other: return AppTranslations.get('game_other');
    }
  }
}

// --- CONFETTI PATH (HERZ) ---
Path drawHeart(Size size) {
  double width = size.width;
  double height = size.height;
  Path path = Path();
  path.moveTo(0.5 * width, 0.4 * height);
  path.cubicTo(0.2 * width, 0.1 * height, -0.25 * width, 0.6 * height, 0.5 * width, height);
  path.cubicTo(1.25 * width, 0.6 * height, 0.8 * width, 0.1 * height, 0.5 * width, 0.4 * height);
  return path;
}

// --- DATEN-MODELL ---
class GameData {
  final String translationKey;
  final IconData icon;
  final Widget Function(BuildContext, Color)? pageBuilder;
  final VoidCallback? onAction;
  final bool isFavoritable;
  final GameCategory category;
  final int minPlayers;
  final int? maxPlayers;

  GameData({
    required this.translationKey,
    required this.icon,
    required this.category,
    this.minPlayers = 1,
    this.maxPlayers,
    this.pageBuilder,
    this.onAction,
    this.isFavoritable = true,
  });

  String get title => AppTranslations.get(translationKey);
  String get id => translationKey;

  String get playerRangeText {
    String suffix = AppTranslations.get('player_suffix');
    if (maxPlayers == null) return "$minPlayers+ $suffix";
    if (minPlayers == maxPlayers) return "$minPlayers $suffix";
    return "$minPlayers - $maxPlayers $suffix";
  }
}

// --- SPIEL LISTE ---
List<GameData> get globalGameList => [
  GameData(translationKey: 'game_title_std', icon: Icons.onetwothree, category: GameCategory.utility, minPlayers: 1, maxPlayers: null,
      pageBuilder: (c, color) => StandardCounterGame(themeColor: color)),

  GameData(translationKey: 'game_title_tourney', icon: Icons.emoji_events, category: GameCategory.utility, minPlayers: 2, maxPlayers: null,
      pageBuilder: (c, color) => const TournamentGame()),

  GameData(translationKey: 'game_title_life', icon: Icons.favorite, category: GameCategory.utility, minPlayers: 2, maxPlayers: 6,
      pageBuilder: (c, color) => const LifeTrackerGame()),

  GameData(translationKey: 'game_title_jass', icon: Icons.edit_note, category: GameCategory.card, minPlayers: 4, maxPlayers: 4,
      pageBuilder: (c, color) => const JassenGame()),

  GameData(translationKey: 'game_title_ftn', icon: Icons.style, category: GameCategory.card, minPlayers: 3, maxPlayers: 9,
      pageBuilder: (c, color) => const FuckTheNeighborGame()),

  GameData(translationKey: 'game_title_mtg', icon: Icons.auto_fix_high, category: GameCategory.card, minPlayers: 2, maxPlayers: 6,
      pageBuilder: (c, color) => const MagicTheGatheringGame()),

  GameData(translationKey: 'game_title_pkm', icon: Icons.catching_pokemon, category: GameCategory.card, minPlayers: 2, maxPlayers: 2,
      pageBuilder: (c, color) => const PokemonTCGGame()),

  GameData(translationKey: 'game_title_darts', icon: Icons.track_changes, category: GameCategory.other, minPlayers: 1, maxPlayers: 8,
      pageBuilder: (c, color) => const DartsGame()),

  GameData(translationKey: 'game_title_yazzee', icon: Icons.casino, category: GameCategory.dice, minPlayers: 1, maxPlayers: 6,
      pageBuilder: (c, color) => const YazzeeGame()),

  GameData(translationKey: 'game_title_10k', icon: Icons.grain, category: GameCategory.dice, minPlayers: 2, maxPlayers: 8,
      pageBuilder: (c, color) => const TenThousandGame()),

  GameData(translationKey: 'suggestion_btn', icon: Icons.help_outline, category: GameCategory.other, onAction: () async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'siro@duschletta.me',
      query: 'subject=Countr Feedback',
    );
    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      // Error handling
    }
  }, isFavoritable: false),
];


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  String? savedLang = prefs.getString('language_code');

  if (savedLang != null) {
    appLocaleNotifier.value = Locale(savedLang);
  } else {
    Locale systemLocale = PlatformDispatcher.instance.locale;
    if (languageMap.containsKey(systemLocale.languageCode)) {
      appLocaleNotifier.value = Locale(systemLocale.languageCode);
    } else {
      appLocaleNotifier.value = const Locale('de');
    }
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocaleNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Countr',
          locale: locale,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: darkBackground,
            colorScheme: const ColorScheme(
              brightness: Brightness.dark,
              surface: darkSurface,
              onSurface: Color(0xFFD8DEE9),
              primary: brandYellow,
              onPrimary: textDark,
              secondary: brandYellow,
              onSecondary: textDark,
              tertiary: brandYellow,
              onTertiary: textDark,
              error: Color(0xFFEB6B6B),
              onError: textDark,
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  late ConfettiController _confettiController;
  int _selectedIndex = 0;
  GameCategory? _selectedCategory;
  bool _showFavoritesOnly = false;
  List<String> _favoriteIds = [];
  List<String> _hiddenGameIds = [];

  final Color activeColor = brandYellow;

  @override
  void initState() {
    super.initState();
    int startPage = 1210;
    _pageController = PageController(viewportFraction: 0.85, initialPage: startPage);
    _selectedIndex = startPage;

    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _loadPreferences();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteIds = prefs.getStringList('favorites') ?? [];
      _hiddenGameIds = prefs.getStringList('hidden_games') ?? [];
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          msg,
          style: const TextStyle(color: Colors.white)
      ),
      backgroundColor: darkSurface,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _toggleFavorite(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteIds.contains(gameId)) {
        _favoriteIds.remove(gameId);
        _showSnack(AppTranslations.get('msg_fav_removed'));
      } else {
        _favoriteIds.add(gameId);
        _showSnack(AppTranslations.get('msg_fav_added'));
      }
    });
    await prefs.setStringList('favorites', _favoriteIds);
  }

  Future<void> _hideGame(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (!_hiddenGameIds.contains(gameId)) {
        _hiddenGameIds.add(gameId);
      }
    });
    await prefs.setStringList('hidden_games', _hiddenGameIds);
    _showSnack(AppTranslations.get('msg_hidden'));

    Future.delayed(const Duration(milliseconds: 300), () => _resetCarousel());
  }

  Future<void> _handleHeartClick() async {
    _confettiController.stop();
    _confettiController.play();

    final prefs = await SharedPreferences.getInstance();
    int currentClicks = prefs.getInt('heart_clicks') ?? 0;
    await prefs.setInt('heart_clicks', currentClicks + 1);

    setState(() {});
  }

  int _compareCategories(GameCategory a, GameCategory b) {
    const order = [GameCategory.utility, GameCategory.card, GameCategory.dice, GameCategory.other];
    return order.indexOf(a).compareTo(order.indexOf(b));
  }

  // Diese Liste wird dynamisch generiert, damit die Texte (Translation) aktuell sind
  List<GameData> _getGamesList() {
    return [
      GameData(translationKey: 'game_title_std', icon: Icons.onetwothree, category: GameCategory.utility, minPlayers: 1, maxPlayers: null,
          pageBuilder: (c, color) => StandardCounterGame(themeColor: color)),

      GameData(translationKey: 'game_title_tourney', icon: Icons.emoji_events, category: GameCategory.utility, minPlayers: 2, maxPlayers: null,
          pageBuilder: (c, color) => const TournamentGame()),

      GameData(translationKey: 'game_title_life', icon: Icons.favorite, category: GameCategory.utility, minPlayers: 2, maxPlayers: 6,
          pageBuilder: (c, color) => const LifeTrackerGame()),

      GameData(translationKey: 'game_title_jass', icon: Icons.edit_note, category: GameCategory.card, minPlayers: 4, maxPlayers: 4,
          pageBuilder: (c, color) => JassenGame()),

      GameData(translationKey: 'game_title_ftn', icon: Icons.style, category: GameCategory.card, minPlayers: 3, maxPlayers: 9,
          pageBuilder: (c, color) => const FuckTheNeighborGame()),

      GameData(translationKey: 'game_title_mtg', icon: Icons.auto_fix_high, category: GameCategory.card, minPlayers: 2, maxPlayers: 6,
          pageBuilder: (c, color) => const MagicTheGatheringGame()),

      GameData(translationKey: 'game_title_pkm', icon: Icons.catching_pokemon, category: GameCategory.card, minPlayers: 2, maxPlayers: 2,
          pageBuilder: (c, color) => const PokemonTCGGame()),

      GameData(translationKey: 'game_title_darts', icon: Icons.track_changes, category: GameCategory.other, minPlayers: 1, maxPlayers: 8,
          pageBuilder: (c, color) => DartsGame(themeColor: color)),

      GameData(translationKey: 'game_title_yazzee', icon: Icons.casino, category: GameCategory.dice, minPlayers: 1, maxPlayers: 6,
          pageBuilder: (c, color) => const YazzeeGame()),

      GameData(translationKey: 'game_title_10k', icon: Icons.grain, category: GameCategory.dice, minPlayers: 2, maxPlayers: 8,
          pageBuilder: (c, color) => const TenThousandGame()),

      GameData(translationKey: 'suggestion_btn', icon: Icons.help_outline, category: GameCategory.other, onAction: () async {
        final Uri emailLaunchUri = Uri(
          scheme: 'mailto',
          path: 'siro@duschletta.me',
          query: 'subject=Countr Feedback',
        );
        try {
          await launchUrl(emailLaunchUri);
        } catch (e) {
          // Error handling
        }
      }, isFavoritable: false),
    ];
  }

  List<GameData> get _sortedAndFilteredGames {
    List<GameData> baseList = _getGamesList();

    baseList = baseList.where((g) => !_hiddenGameIds.contains(g.id)).toList();

    if (_selectedCategory != null) {
      baseList = baseList.where((g) => g.category == _selectedCategory).toList();
    }
    if (_showFavoritesOnly) {
      baseList = baseList.where((g) => _favoriteIds.contains(g.id)).toList();
    }

    if (_selectedCategory == null && !_showFavoritesOnly) {
      final favs = baseList.where((g) => _favoriteIds.contains(g.id)).toList();
      final nonFavs = baseList.where((g) => !_favoriteIds.contains(g.id)).toList();

      favs.sort((a, b) => _compareCategories(a.category, b.category));
      nonFavs.sort((a, b) => _compareCategories(a.category, b.category));

      return [...favs, ...nonFavs];
    }

    baseList.sort((a, b) => _compareCategories(a.category, b.category));
    return baseList;
  }

  int _getGameCount({GameCategory? category, bool favoritesOnly = false}) {
    return _getGamesList().where((g) {
      if (_hiddenGameIds.contains(g.id)) return false;
      if (favoritesOnly && !_favoriteIds.contains(g.id)) return false;
      if (category != null && g.category != category) return false;
      return true;
    }).length;
  }

  void _resetCarousel() {
    if (_pageController.hasClients) {
      int resetPage = 1210;
      _pageController.jumpToPage(resetPage);
      setState(() {
        _selectedIndex = resetPage;
      });
    }
  }

  void _handleButtonPress(List<GameData> currentGames) {
    if (currentGames.isEmpty) return;

    final actualIndex = _selectedIndex % currentGames.length;
    final selectedItem = currentGames[actualIndex];

    if (selectedItem.pageBuilder != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => selectedItem.pageBuilder!(context, activeColor)),
      );
    } else if (selectedItem.onAction != null) {
      selectedItem.onAction!();
    }
  }

  void _openSettings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const InfoScreen()));
    _loadPreferences();
    // NACH Rückkehr aus Settings: Reset auf Standard Counter (erste Seite)
    _resetCarousel();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocaleNotifier,
      builder: (context, locale, child) {
        final colors = Theme.of(context).colorScheme;

        final allGames = _getGamesList();
        final currentGames = _sortedAndFilteredGames;

        GameData? activeGame;
        if (currentGames.isNotEmpty) {
          activeGame = currentGames[_selectedIndex % currentGames.length];
        }

        return Scaffold(
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(40, 80, 40, 0),
                          child: Image.asset(
                            'assets/countr_logo_text_v.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      flex: 7,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 30),
                            child: Text(
                              AppTranslations.get('slogan'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: colors.onSurface.withAlpha(150),
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 1.1
                              ),
                            ),
                          ),

                          Container(
                            width: double.infinity,
                            height: 50,
                            margin: const EdgeInsets.only(bottom: 20),
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              children: [
                                _buildFilterChip(
                                  "${AppTranslations.get('filter_all')} (${_getGameCount()})",
                                  _selectedCategory == null && !_showFavoritesOnly,
                                      () {
                                    setState(() { _showFavoritesOnly = false; _selectedCategory = null; _resetCarousel(); });
                                  },
                                ),
                                const SizedBox(width: 10),
                                _buildFilterChip(
                                  "${AppTranslations.get('filter_fav')} (${_getGameCount(favoritesOnly: true)})",
                                  _showFavoritesOnly,
                                      () {
                                    setState(() { _showFavoritesOnly = true; _selectedCategory = null; _resetCarousel(); });
                                  },
                                  icon: Icons.favorite,
                                ),
                                const SizedBox(width: 10),
                                _buildFilterChip(
                                  "${AppTranslations.get('game_utility')} (${_getGameCount(category: GameCategory.utility)})",
                                  _selectedCategory == GameCategory.utility,
                                      () {
                                    setState(() { _selectedCategory = GameCategory.utility; _showFavoritesOnly = false; _resetCarousel(); });
                                  },
                                ),
                                const SizedBox(width: 10),
                                _buildFilterChip(
                                  "${AppTranslations.get('game_cards')} (${_getGameCount(category: GameCategory.card)})",
                                  _selectedCategory == GameCategory.card,
                                      () {
                                    setState(() { _selectedCategory = GameCategory.card; _showFavoritesOnly = false; _resetCarousel(); });
                                  },
                                ),
                                const SizedBox(width: 10),
                                _buildFilterChip(
                                  "${AppTranslations.get('game_dice')} (${_getGameCount(category: GameCategory.dice)})",
                                  _selectedCategory == GameCategory.dice,
                                      () {
                                    setState(() { _selectedCategory = GameCategory.dice; _showFavoritesOnly = false; _resetCarousel(); });
                                  },
                                ),
                                const SizedBox(width: 10),
                                _buildFilterChip(
                                  "${AppTranslations.get('game_other')} (${_getGameCount(category: GameCategory.other)})",
                                  _selectedCategory == GameCategory.other,
                                      () {
                                    setState(() { _selectedCategory = GameCategory.other; _showFavoritesOnly = false; _resetCarousel(); });
                                  },
                                ),
                              ],
                            ),
                          ),

                          if (currentGames.isEmpty)
                            SizedBox(
                              height: 280,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, size: 60, color: colors.onSurface.withAlpha(77)),
                                    const SizedBox(height: 10),
                                    Text(
                                      _showFavoritesOnly ? AppTranslations.get('no_favs') : AppTranslations.get('no_games_found'),
                                      style: TextStyle(color: colors.onSurface.withAlpha(128)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 280,
                              child: PageView.builder(
                                key: ValueKey(locale.languageCode),
                                clipBehavior: Clip.none,
                                controller: _pageController,
                                itemCount: currentGames.length == 1 ? 1 : null,
                                onPageChanged: (index) {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final actualIndex = index % currentGames.length;
                                  final game = currentGames[actualIndex];
                                  final isSelected = index == _selectedIndex;
                                  final isFav = _favoriteIds.contains(game.id);

                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: isSelected ? 0 : 20),
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: isSelected ? Border.all(color: activeColor, width: 3) : Border.all(color: Colors.transparent, width: 3),
                                      boxShadow: isSelected ? [BoxShadow(color: activeColor.withAlpha(102), blurRadius: 20)] : [],
                                    ),
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(game.icon, size: 70, color: activeColor),
                                              const SizedBox(height: 15),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                child: Text(
                                                  game.title,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(color: colors.onSurface, fontSize: 20, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              if (game.category != GameCategory.other)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 5),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                                                    child: Text(
                                                      game.playerRangeText,
                                                      style: TextStyle(color: colors.onSurface.withAlpha(153), fontSize: 12),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (game.isFavoritable)
                                          Positioned(
                                            top: 10, right: 10,
                                            child: GestureDetector(
                                              onTap: () => _toggleFavorite(game.id),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                                                child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? colors.error : colors.onSurface.withAlpha(128), size: 24),
                                              ),
                                            ),
                                          ),
                                        if (game.isFavoritable)
                                          Positioned(
                                            top: 10, left: 10,
                                            child: GestureDetector(
                                              onTap: () => _hideGame(game.id),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                                                child: Icon(Icons.visibility_off, color: colors.onSurface.withAlpha(128), size: 24),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          SizedBox(
                            width: 220,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: activeGame != null ? () => _handleButtonPress(currentGames) : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: activeGame != null ? activeColor : colors.surface,
                                foregroundColor: colors.onPrimary,
                                elevation: 5,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                activeGame == null ? AppTranslations.get('empty') : (activeGame.pageBuilder != null ? AppTranslations.get('start') : AppTranslations.get('mail')),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Text(
                              AppTranslations.get('made_with'),
                              style: TextStyle(color: colors.onSurface.withAlpha(77), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                top: 70,
                right: 20,
                child: GestureDetector(
                  onTap: _openSettings,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: darkSurface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: brandYellow, width: 1.5),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          appLocaleNotifier.value.languageCode.toUpperCase(),
                          style: const TextStyle(
                              color: brandYellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 16
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(width: 1, height: 18, color: brandYellow.withAlpha(128)),
                        const SizedBox(width: 8),
                        const Icon(Icons.info_outline, color: brandYellow, size: 22),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 70,
                left: 20,
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: darkSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: brandYellow, width: 1.5),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _handleHeartClick,
                      splashColor: brandYellow.withAlpha(100),
                      highlightColor: brandYellow.withAlpha(50),
                      child: const Icon(Icons.favorite, color: brandYellow, size: 24),
                    ),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 90, left: 40),
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    createParticlePath: drawHeart,
                    colors: const [Colors.red, Colors.pink, Colors.purple, Colors.orange],
                    numberOfParticles: 20,
                    gravity: 0.3,
                    emissionFrequency: 0.05,
                    minBlastForce: 10,
                    maxBlastForce: 25,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, {IconData? icon}) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? colors.primary : Colors.transparent, width: 1),
          boxShadow: isSelected ? [BoxShadow(color: colors.primary.withAlpha(77), blurRadius: 8)] : [],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isSelected ? colors.onPrimary : colors.onSurface.withAlpha(179)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(color: isSelected ? colors.onPrimary : colors.onSurface.withAlpha(179), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// --- INFO SCREEN ---
class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  int _heartClicks = 0;
  List<String> _hiddenGameIds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _heartClicks = prefs.getInt('heart_clicks') ?? 0;
      _hiddenGameIds = prefs.getStringList('hidden_games') ?? [];
    });
  }

  Future<void> _restoreGame(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hiddenGameIds.remove(gameId);
    });
    await prefs.setStringList('hidden_games', _hiddenGameIds);
  }

  Future<void> _changeLanguage(BuildContext context, String code) async {
    appLocaleNotifier.value = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocaleNotifier,
      builder: (context, locale, child) {
        String currentCode = locale.languageCode;

        // Hidden Games Liste dynamisch bauen, um Übersetzung zu nutzen
        final hiddenGamesList = _getHiddenGamesList(context).where((g) => _hiddenGameIds.contains(g.id)).toList();

        return Scaffold(
          backgroundColor: darkBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: brandYellow,
            title: Text(AppTranslations.get('info_title')),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppTranslations.get('language_title'), style: const TextStyle(color: brandYellow, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.8,
                        children: languageMap.entries.map((entry) {
                          bool isSelected = currentCode == entry.key;
                          return _langChip(entry.key.toUpperCase(), entry.value, isSelected, () => _changeLanguage(context, entry.key));
                        }).toList(),
                      );
                    }
                ),

                const Divider(color: Colors.white24, height: 40),

                Text(AppTranslations.get('about_title'), style: const TextStyle(color: brandYellow, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  AppTranslations.get('about_text'),
                  style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                ),

                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: darkSurface,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10)
                  ),
                  child: Row(
                    children: [
                      Text("$_heartClicks", style: const TextStyle(color: brandYellow, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          AppTranslations.get('heart_clicks'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.favorite, color: Colors.red, size: 24),
                    ],
                  ),
                ),

                // --- AUSGEBLENDETE SPIELE SEKTION ---
                const Divider(color: Colors.white24, height: 40),
                Text(AppTranslations.get('hidden_games_title'), style: const TextStyle(color: brandYellow, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                if (hiddenGamesList.isEmpty)
                  Text(AppTranslations.get('hidden_games_empty'), style: TextStyle(color: Colors.white.withAlpha(100), fontStyle: FontStyle.italic))
                else
                  ...hiddenGamesList.map((game) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: darkSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(game.icon, color: Colors.white70, size: 20),
                        const SizedBox(width: 15),
                        Expanded(child: Text(game.title, style: const TextStyle(color: Colors.white))),
                        TextButton(
                          onPressed: () => _restoreGame(game.id),
                          child: Text(AppTranslations.get('restore'), style: const TextStyle(color: brandYellow)),
                        )
                      ],
                    ),
                  )),


                const Divider(color: Colors.white24, height: 40),

                Text(AppTranslations.get('impressum_title'), style: const TextStyle(color: brandYellow, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _infoRow(Icons.person, "Siro Duschletta"),
                const SizedBox(height: 10),
                _infoRow(Icons.location_on, AppTranslations.get('address')),
                const SizedBox(height: 10),
                _infoRow(Icons.email, "siro@duschletta.me"),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    AppTranslations.get('feedback_hint'),
                    style: TextStyle(color: brandYellow.withAlpha(128), fontStyle: FontStyle.italic),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // Hilfsmethode, um die Liste der ausgeblendeten Spiele mit korrekter Sprache zu generieren
  List<GameData> _getHiddenGamesList(BuildContext context) {
    // Da wir die Liste nur für die Namen brauchen, reichen diese Infos
    return [
      GameData(translationKey: 'game_title_std', icon: Icons.onetwothree, category: GameCategory.utility),
      GameData(translationKey: 'game_title_tourney', icon: Icons.emoji_events, category: GameCategory.utility),
      GameData(translationKey: 'game_title_life', icon: Icons.favorite, category: GameCategory.utility),
      GameData(translationKey: 'game_title_jass', icon: Icons.edit_note, category: GameCategory.card),
      GameData(translationKey: 'game_title_ftn', icon: Icons.style, category: GameCategory.card),
      GameData(translationKey: 'game_title_mtg', icon: Icons.auto_fix_high, category: GameCategory.card),
      GameData(translationKey: 'game_title_pkm', icon: Icons.catching_pokemon, category: GameCategory.card),
      GameData(translationKey: 'game_title_darts', icon: Icons.track_changes, category: GameCategory.other),
      GameData(translationKey: 'game_title_yazzee', icon: Icons.casino, category: GameCategory.dice),
      GameData(translationKey: 'game_title_10k', icon: Icons.grain, category: GameCategory.dice),
    ];
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 15),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15))),
      ],
    );
  }

  Widget _langChip(String code, String name, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? brandYellow : darkSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? brandYellow : Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(code, style: TextStyle(color: isSelected ? textDark : brandYellow, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(name, style: TextStyle(color: isSelected ? textDark.withAlpha(204) : Colors.white54, fontSize: 12), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}