import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mtg_commander_art.dart';
import 'mtg_i18n.dart';

const Color _bg = Color(0xFF121417);
const Color _field = Color(0xFF23272C);

/// Öffnet die Commander-Suche. Liefert das gewählte Artwork oder null (abgebrochen).
Future<MtgCommanderArt?> showMtgCommanderSearch(
  BuildContext context, {
  required ScryfallClient client,
  required List<MtgCommanderArt> recents,
  required Color accent,
}) {
  return Navigator.of(context).push<MtgCommanderArt>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => MtgCommanderSearchPage(client: client, recents: recents, accent: accent),
  ));
}

class MtgCommanderSearchPage extends StatefulWidget {
  final ScryfallClient client;
  final List<MtgCommanderArt> recents;
  final Color accent;

  const MtgCommanderSearchPage({super.key, required this.client, required this.recents, required this.accent});

  @override
  State<MtgCommanderSearchPage> createState() => _MtgCommanderSearchPageState();
}

class _MtgCommanderSearchPageState extends State<MtgCommanderSearchPage> {
  static const _debounce = Duration(milliseconds: 450);
  static const _minChars = 2;

  final _controller = TextEditingController();
  Timer? _debounceTimer;
  int _generation = 0; // verwirft Antworten auf veraltete Suchanfragen

  bool _loading = false;
  MtgSearchError? _error;
  List<MtgCommanderArt>? _results;

  String get _query => _controller.text.trim();

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounceTimer?.cancel();
    setState(() {}); // Löschen-Knopf ein-/ausblenden
    if (_query.length < _minChars) {
      _generation++;
      setState(() {
        _loading = false;
        _error = null;
        _results = null;
      });
      return;
    }
    _debounceTimer = Timer(_debounce, _search);
  }

  Future<void> _search() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.client.searchCommanders(_query);
      if (!mounted || generation != _generation) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } on MtgSearchException catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = e.error;
        _loading = false;
      });
    }
  }

  void _pick(MtgCommanderArt art) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(art);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: _buildBody())),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text(mtgT('powered_by'), style: const TextStyle(color: Colors.white30, fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: TextField(
              key: const ValueKey('mtg_search_field'),
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                _debounceTimer?.cancel();
                if (_query.length >= _minChars) _search();
              },
              cursorColor: widget.accent,
              style: const TextStyle(color: Colors.white, fontSize: 17),
              decoration: InputDecoration(
                hintText: mtgT('search_hint'),
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: _field,
                prefixIcon: Icon(Icons.search, color: widget.accent),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                        },
                      ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide(color: widget.accent, width: 1.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_query.length < _minChars) return _buildStart();
    if (_loading && _results == null) return const _LoadingGrid(key: ValueKey('loading'));
    if (_error != null) return _buildError(_error!);
    final results = _results ?? const [];
    if (results.isEmpty && !_loading) {
      return _message(key: 'empty', icon: Icons.search_off, text: mtgT('no_results'));
    }
    return Stack(
      key: const ValueKey('results'),
      children: [
        _ArtGrid(arts: results, onPick: _pick),
        if (_loading) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.transparent)),
      ],
    );
  }

  Widget _buildStart() {
    return ListView(
      key: const ValueKey('start'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _field, borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: widget.accent, size: 28),
              const SizedBox(width: 14),
              Expanded(child: Text(mtgT('search_intro'), style: const TextStyle(color: Colors.white70, height: 1.4))),
            ],
          ),
        ),
        if (widget.recents.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 22, bottom: 10, left: 4),
            child: Text(mtgT('recent').toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ),
          _ArtGrid(arts: widget.recents, onPick: _pick, shrinkWrap: true),
        ],
      ],
    );
  }

  Widget _buildError(MtgSearchError error) {
    final (icon, text) = switch (error) {
      MtgSearchError.offline => (Icons.wifi_off, mtgT('offline')),
      MtgSearchError.rateLimited => (Icons.hourglass_top, mtgT('rate_limited')),
      MtgSearchError.unknown => (Icons.error_outline, mtgT('search_error')),
    };
    return _message(
      key: 'error',
      icon: icon,
      text: text,
      action: TextButton.icon(
        onPressed: _search,
        icon: Icon(Icons.refresh, color: widget.accent),
        label: Text(mtgT('retry'), style: TextStyle(color: widget.accent, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _message({required String key, required IconData icon, required String text, Widget? action}) {
    return Center(
      key: ValueKey(key),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white24, size: 64),
            const SizedBox(height: 14),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 16, height: 1.4)),
            if (action != null) ...[const SizedBox(height: 8), action],
          ],
        ),
      ),
    );
  }
}

// Scryfall "art_crop" ist ca. 626 × 457 px
const double _artAspect = 626 / 457;

class _ArtGrid extends StatelessWidget {
  final List<MtgCommanderArt> arts;
  final ValueChanged<MtgCommanderArt> onPick;
  final bool shrinkWrap;

  const _ArtGrid({required this.arts, required this.onPick, this.shrinkWrap = false});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: shrinkWrap ? EdgeInsets.zero : const EdgeInsets.fromLTRB(16, 4, 16, 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: _artAspect,
      ),
      itemCount: arts.length,
      itemBuilder: (context, i) => MtgArtCard(art: arts[i], onTap: () => onPick(arts[i])),
    );
  }
}

/// Artwork-Karte: Bild mit dunklem Verlauf, Name und Künstler (Pflicht laut Scryfall).
class MtgArtCard extends StatelessWidget {
  final MtgCommanderArt art;
  final VoidCallback onTap;
  final bool selected;
  final bool compact;
  final Color? accent;

  const MtgArtCard({super.key, required this.art, required this.onTap, this.selected = false, this.compact = false, this.accent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('mtg_art_${art.id}'),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? (accent ?? Colors.white) : Colors.white12, width: selected ? 3 : 1),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(selected ? 13 : 15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              mtgArtImageBuilder(art.artUrl),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.35, 1],
                    colors: [Colors.transparent, Color(0xE6000000)],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: compact ? 6 : 9,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      art.name,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: compact ? 11 : 14, height: 1.15),
                    ),
                    if (!compact && art.artist.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(children: [
                          const Icon(Icons.brush, size: 11, color: Colors.white60),
                          const SizedBox(width: 4),
                          Expanded(child: Text(art.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 11))),
                        ]),
                      ),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(radius: 11, backgroundColor: accent ?? Colors.white, child: const Icon(Icons.check, size: 15, color: Colors.black)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pulsierende Platzhalter, solange Scryfall antwortet.
class _LoadingGrid extends StatefulWidget {
  const _LoadingGrid({super.key});

  @override
  State<_LoadingGrid> createState() => _LoadingGridState();
}

class _LoadingGridState extends State<_LoadingGrid> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 0.8).animate(_pulse),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 240, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: _artAspect),
        itemCount: 8,
        itemBuilder: (_, _) => DecoratedBox(decoration: BoxDecoration(color: _field, borderRadius: BorderRadius.circular(16))),
      ),
    );
  }
}
