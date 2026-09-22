import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Generic "continue last game" persistence.
///
/// Each game screen serializes its own state to a JSON-safe Map and calls
/// [save] whenever something meaningful changes. On app start, [getResumableGameId]
/// tells the home screen which game (if any) was left mid-session so it can
/// offer to reload it. A game calls [clear] itself once it reaches an explicit
/// "reset" / "quit" / "new game" action - just backgrounding or force-closing
/// the app never clears it.
class GamePersistence {
  static const _statePrefix = 'ongoing_state_';
  static const _activeGameKey = 'ongoing_active_game';

  static Future<void> save(String gameId, Map<String, dynamic> state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_statePrefix$gameId', jsonEncode(state));
    await prefs.setString(_activeGameKey, gameId);
  }

  static Future<Map<String, dynamic>?> load(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_statePrefix$gameId');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_statePrefix$gameId');
    if (prefs.getString(_activeGameKey) == gameId) {
      await prefs.remove(_activeGameKey);
    }
  }

  /// The id of the most recently saved game, if its state is still present.
  static Future<String?> getResumableGameId() async {
    final prefs = await SharedPreferences.getInstance();
    final gameId = prefs.getString(_activeGameKey);
    if (gameId == null) return null;
    if (!prefs.containsKey('$_statePrefix$gameId')) return null;
    return gameId;
  }
}
