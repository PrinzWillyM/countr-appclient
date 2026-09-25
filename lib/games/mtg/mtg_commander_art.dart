import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Artwork eines Commanders (Scryfall "art_crop"). Laut Scryfall-Richtlinien müssen
/// Künstler und Copyright dort sichtbar sein, wo das Artwork gezeigt wird.
class MtgCommanderArt {
  final String id;
  final String name;
  final String artUrl;
  final String artist;

  const MtgCommanderArt({required this.id, required this.name, required this.artUrl, required this.artist});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'art': artUrl, 'artist': artist};

  static MtgCommanderArt? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'], name = json['name'], art = json['art'];
    if (id is! String || name is! String || art is! String) return null;
    return MtgCommanderArt(id: id, name: name, artUrl: art, artist: json['artist'] as String? ?? '');
  }

  /// Aus einer Scryfall-Karte. Doppelseitige Karten haben die Bilder pro Seite.
  static MtgCommanderArt? fromScryfall(Map<String, dynamic> card) {
    final faces = card['card_faces'] as List?;
    final front = faces != null && faces.isNotEmpty ? Map<String, dynamic>.from(faces.first as Map) : null;
    final images = (card['image_uris'] ?? front?['image_uris']) as Map?;
    final art = images?['art_crop'];
    if (art is! String || card['id'] is! String) return null;
    return MtgCommanderArt(
      id: card['id'] as String,
      name: card['name'] as String? ?? '',
      artUrl: art,
      artist: (card['artist'] ?? front?['artist']) as String? ?? '',
    );
  }

  String get credit => artist.isEmpty ? '™ & © Wizards of the Coast' : '$artist · ™ & © Wizards of the Coast';
}

enum MtgSearchError { offline, rateLimited, unknown }

class MtgSearchException implements Exception {
  final MtgSearchError error;
  const MtgSearchException(this.error);
}

/// Minimaler Scryfall-Client für die Commander-Suche.
/// Regeln: https://scryfall.com/docs/api (User-Agent + Accept, max. 2 Suchen/Sekunde).
class ScryfallClient {
  static const _host = 'api.scryfall.com';
  static const _minInterval = Duration(milliseconds: 550);

  final http.Client _http;
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  ScryfallClient({http.Client? client}) : _http = client ?? http.Client();

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        // Im Browser darf/soll der User-Agent nicht überschrieben werden
        if (!kIsWeb) 'User-Agent': 'Countr/1.0',
      };

  /// Sucht Karten, die Commander sein dürfen, beliebteste (EDHREC) zuerst.
  Future<List<MtgCommanderArt>> searchCommanders(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    // Scryfall erlaubt nur 2 Suchanfragen pro Sekunde - notfalls kurz warten
    final wait = _minInterval - DateTime.now().difference(_lastRequest);
    if (wait > Duration.zero) await Future.delayed(wait);
    _lastRequest = DateTime.now();

    final uri = Uri.https(_host, '/cards/search', {'q': '$q is:commander', 'order': 'edhrec', 'unique': 'cards'});
    final http.Response response;
    try {
      response = await _http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const MtgSearchException(MtgSearchError.offline);
    } catch (_) {
      throw const MtgSearchException(MtgSearchError.offline);
    }

    if (response.statusCode == 404) return const []; // Scryfall: keine Treffer
    if (response.statusCode == 429) throw const MtgSearchException(MtgSearchError.rateLimited);
    if (response.statusCode != 200) throw const MtgSearchException(MtgSearchError.unknown);

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return [
      for (final card in (body['data'] as List? ?? const []))
        ?MtgCommanderArt.fromScryfall(Map<String, dynamic>.from(card as Map)),
    ];
  }

  void close() => _http.close();
}

/// Zuletzt verwendete Commander, damit man nicht jedes Mal neu suchen muss.
class MtgRecentCommanders {
  static const _key = 'mtg_recent_commanders';
  static const maxEntries = 12;

  static Future<List<MtgCommanderArt>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return [for (final e in jsonDecode(raw) as List) ?MtgCommanderArt.fromJson(e)];
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(List<MtgCommanderArt> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final a in list) a.toJson()]));
  }

  /// Setzt [art] an die erste Stelle (ohne Duplikate) und kürzt auf [maxEntries].
  static Future<List<MtgCommanderArt>> add(List<MtgCommanderArt> current, MtgCommanderArt art) async {
    final next = [art, ...current.where((a) => a.id != art.id)].take(maxEntries).toList();
    await _save(next);
    return next;
  }

  static Future<List<MtgCommanderArt>> remove(List<MtgCommanderArt> current, MtgCommanderArt art) async {
    final next = current.where((a) => a.id != art.id).toList();
    await _save(next);
    return next;
  }
}

/// Baut das Bild für ein Artwork. In Tests austauschbar (dort gibt es weder Netz noch Datei-Cache).
Widget Function(String url, {BoxFit fit}) mtgArtImageBuilder = _defaultArtImage;

Widget _defaultArtImage(String url, {BoxFit fit = BoxFit.cover}) {
  return CachedNetworkImage(
    imageUrl: url,
    fit: fit,
    fadeInDuration: const Duration(milliseconds: 250),
    placeholder: (_, _) => const ColoredBox(color: Color(0xFF2A2E33)),
    // Offline und noch nicht im Cache: einfach dunkel bleiben, die Kachel funktioniert weiter
    errorWidget: (_, _, _) => const ColoredBox(color: Color(0xFF2A2E33), child: Center(child: Icon(Icons.image_not_supported, color: Colors.white24))),
  );
}
