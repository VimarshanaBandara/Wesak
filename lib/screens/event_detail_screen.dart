import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart' show Share;
import 'package:url_launcher/url_launcher.dart';

import '../models/event_model.dart';

/// Full-page Event Detail Screen
/// Photos gallery, directions, share button
class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  int _currentPhoto = 0;
  final _pageController = PageController();

  static const _typeColors = {
    'dansal': Color(0xFFBF360C),
    'thorana': Color(0xFF4A148C),
    'kudu': Color(0xFFF57F17),
    'geetha': Color(0xFF0D47A1),
  };
  static const _typeIcons = {
    'dansal': Icons.restaurant,
    'thorana': Icons.account_balance,
    'kudu': Icons.light_mode,
    'geetha': Icons.music_note,
  };
  static const _typeLabels = {
    'dansal': 'Dansal',
    'thorana': 'Thorana',
    'kudu': 'Wesak Kudu',
    'geetha': 'Bhakthi Geetha',
  };

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color get _typeColor =>
      _typeColors[widget.event.type] ?? const Color(0xFF1A0533);

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final hasPhotos = event.photos.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // ── Header / Photo gallery ─────────────────────────────────
          SliverAppBar(
            expandedHeight: hasPhotos ? 280 : 160,
            pinned: true,
            backgroundColor: _typeColor,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: _shareEvent,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.share, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Share',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: hasPhotos
                  ? _buildPhotoGallery(event)
                  : _buildGradientHeader(event),
            ),
          ),

          // ── Content ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main info card
                _buildInfoCard(event),
                const SizedBox(height: 12),

                // Action buttons
                _buildActionButtons(event),
                const SizedBox(height: 12),

                // Photos section (if any)
                if (hasPhotos) ...[
                  _buildPhotosSection(event),
                  const SizedBox(height: 12),
                ],

                // Description
                if (event.description.isNotEmpty) ...[
                  _buildDescriptionCard(event),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Photo gallery (swipeable) ────────────────────────────────────────
  Widget _buildPhotoGallery(EventModel event) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: event.photos.length,
          onPageChanged: (i) => setState(() => _currentPhoto = i),
          itemBuilder: (_, i) => Image.network(
            event.photos[i],
            fit: BoxFit.cover,
            loadingBuilder: (_, child, p) => p == null
                ? child
                : Container(
                    color: _typeColor.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  ),
            errorBuilder: (_, __, ___) => Container(
              color: _typeColor,
              child: const Icon(Icons.broken_image,
                  color: Colors.white54, size: 48),
            ),
          ),
        ),

        // Dark gradient bottom — text readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),
        ),

        // Dots indicator
        if (event.photos.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                event.photos.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentPhoto ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _currentPhoto
                        ? Colors.white
                        : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Gradient header (no photos) ──────────────────────────────────────
  Widget _buildGradientHeader(EventModel event) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A0533),
            _typeColor,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _typeIcons[event.type] ?? Icons.event,
                color: Colors.white,
                size: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main info card ───────────────────────────────────────────────────
  Widget _buildInfoCard(EventModel event) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_typeIcons[event.type] ?? Icons.event,
                    size: 13, color: _typeColor),
                const SizedBox(width: 5),
                Text(
                  _typeLabels[event.type] ?? event.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _typeColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Name
          Text(
            event.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A0533),
              height: 1.2,
            ),
          ),

          // City
          if (event.city.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on,
                      size: 16, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Text(
                  event.city,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Action buttons ───────────────────────────────────────────────────
  Widget _buildActionButtons(EventModel event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Directions button
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _openDirections(event),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0533),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color:
                          const Color(0xFF1A0533).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Get Directions',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Share button
          GestureDetector(
            onTap: _shareEvent,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.share,
                  color: Color(0xFF1A0533), size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── Full photos section ──────────────────────────────────────────────
  Widget _buildPhotosSection(EventModel event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'PHOTOS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${event.photos.length})',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: event.photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _openPhotoViewer(context, event.photos, i),
                child: Hero(
                  tag: 'photo_$i',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      event.photos[i],
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, p) => p == null
                          ? child
                          : Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Description card ─────────────────────────────────────────────────
  Widget _buildDescriptionCard(EventModel event) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ABOUT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────
  Future<void> _openDirections(EventModel event) async {
    final uri = Uri.parse(
      'geo:${event.lat},${event.lng}?q=${event.lat},${event.lng}(${Uri.encodeComponent(event.name)})',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final webUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${event.lat},${event.lng}',
      );
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareEvent() {
    final event = widget.event;
    final text = '🪔 ${event.name}\n'
        '📍 ${event.city.isNotEmpty ? event.city : 'Sri Lanka'}\n'
        '🎉 ${_typeLabels[event.type] ?? event.type}\n\n'
        'Shared via Wesak 2026 App';
    Share.share(text);
  }

  // ── Full-screen photo viewer ─────────────────────────────────────────
  void _openPhotoViewer(
      BuildContext context, List<String> photos, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(photos: photos, initialIndex: initialIndex),
      ),
    );
  }
}

/// Full-screen photo viewer with swipe
class _PhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const _PhotoViewer({required this.photos, required this.initialIndex});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late int _current;
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_current + 1} / ${widget.photos.length}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: Hero(
              tag: 'photo_$i',
              child: Image.network(
                widget.photos[i],
                fit: BoxFit.contain,
                loadingBuilder: (_, child, p) => p == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
