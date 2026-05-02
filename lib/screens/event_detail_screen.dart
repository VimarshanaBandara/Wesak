import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart' show Share;
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_locale.dart';
import '../models/event_model.dart';
import '../widgets/wesak_app_bar.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  static const _typeColors = {
    'dansal': Color(0xFFBF360C),
    'thorana': Color(0xFF6A1B9A),
    'kudu': Color(0xFFE65100),
    'geetha': Color(0xFF0D47A1),
  };

  static const _typeGradients = {
    'dansal': [Color(0xFFE64A19), Color(0xFF8D1900)],
    'thorana': [Color(0xFF8E24AA), Color(0xFF1A0533)],
    'kudu': [Color(0xFFFF7043), Color(0xFFBF360C)],
    'geetha': [Color(0xFF1565C0), Color(0xFF002171)],
  };

  static const _typeIcons = {
    'dansal': Icons.restaurant_rounded,
    'thorana': Icons.account_balance_rounded,
    'kudu': Icons.light_mode_rounded,
    'geetha': Icons.music_note_rounded,
  };

  Color get _typeColor =>
      _typeColors[event.type] ?? const Color(0xFF1A0533);

  List<Color> get _typeGradient =>
      _typeGradients[event.type] ??
      [const Color(0xFF1A0533), const Color(0xFF4A148C)];

  @override
  Widget build(BuildContext context) {
    final hasPhotos = event.photos.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF3EFF8),
      appBar: WesakAppBar(
        title: event.name,
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: () => _shareEvent(context),
            icon: const Icon(Icons.share_rounded, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainInfo(context),
            const SizedBox(height: 16),
            _buildTimeCard(),
            const SizedBox(height: 16),
            _buildActionButtons(context),
            if (event.foodItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildFoodItemsCard(),
            ],
            if (hasPhotos) ...[
              const SizedBox(height: 24),
              _buildPhotosSection(context),
            ],
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildDescriptionCard(context),
            ],
          ],
        ),
      ),
    );
  }

  // ── Main info ──────────────────────────────────────────────────────────────

  Widget _buildMainInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _typeBadge(context),
              if (event.verified) ...[
                const SizedBox(width: 8),
                _verifiedBadge(),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            event.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A0533),
              height: 1.2,
            ),
          ),
          if (event.city.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 16, color: _typeColor),
                const SizedBox(width: 4),
                Text(
                  event.city,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
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

  Widget _typeBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _typeGradient),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_typeIcons[event.type] ?? Icons.event,
              size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            AppLocale.typeLabel(context, event.type),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 13, color: Colors.green.shade600),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Time card ──────────────────────────────────────────────────────────────

  Widget _buildTimeCard() {
    final date = DateFormat('MMM d, y').format(event.startTime);
    final start = DateFormat('h:mm a').format(event.startTime);
    final end = DateFormat('h:mm a').format(event.endTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _timeCell(Icons.calendar_today_rounded, 'Date', date),
            _divider(),
            _timeCell(Icons.play_circle_rounded, 'Start', start),
            _divider(),
            _timeCell(Icons.stop_circle_rounded, 'End', end),
          ],
        ),
      ),
    );
  }

  Widget _timeCell(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: _typeColor),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A0533),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 44, color: const Color(0xFFEEEEEE));

  // ── Action buttons ─────────────────────────────────────────────────────────

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openDirections(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _typeGradient),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _typeColor.withValues(alpha: 0.38),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocale.detailGetDirections.getString(context),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _shareEvent(context),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(Icons.share_rounded, color: _typeColor, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  // ── Food items ─────────────────────────────────────────────────────────────

  Widget _buildFoodItemsCard() {
    final items = event.foodItems
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.restaurant_rounded,
                      size: 16, color: _typeColor),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Food Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A0533),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map((item) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _typeColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: _typeColor.withValues(alpha: 0.22)),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 13,
                            color: _typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Photos section ─────────────────────────────────────────────────────────

  Widget _buildPhotosSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocale.detailPhotos.getString(context),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A0533),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${event.photos.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _typeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: event.photos.length,
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () => _openPhotoViewer(context, i),
              child: Hero(
                tag: 'photo_$i',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    event.photos[i],
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, p) => p == null
                        ? child
                        : Container(
                            color: Colors.grey[100],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image,
                          color: Colors.grey, size: 28),
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

  // ── Description card ───────────────────────────────────────────────────────

  Widget _buildDescriptionCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.info_outline_rounded,
                      size: 16, color: _typeColor),
                ),
                const SizedBox(width: 10),
                Text(
                  AppLocale.detailAbout.getString(context),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A0533),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.75,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDirections() async {
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

  void _shareEvent(BuildContext context) {
    final typeLabel = AppLocale.typeLabel(context, event.type);
    final text = '🪔 ${event.name}\n'
        '📍 ${event.city.isNotEmpty ? event.city : 'Sri Lanka'}\n'
        '🎉 $typeLabel\n\n'
        'Shared via Wesak 2026 App';
    Share.share(text);
  }

  void _openPhotoViewer(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _PhotoViewer(photos: event.photos, initialIndex: initialIndex),
      ),
    );
  }
}

// ── Full-screen photo viewer ────────────────────────────────────────────────

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
