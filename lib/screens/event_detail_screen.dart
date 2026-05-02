import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart' show Share;
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_locale.dart';
import '../models/event_model.dart';

enum _EventStatus { open, upcoming, ended }

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

  Color get _typeColor => _typeColors[event.type] ?? const Color(0xFF1A0533);

  List<Color> get _typeGradient =>
      _typeGradients[event.type] ??
      [const Color(0xFF1A0533), const Color(0xFF4A148C)];

  _EventStatus get _status {
    final now = DateTime.now();
    if (now.isBefore(event.startTime)) return _EventStatus.upcoming;
    if (now.isAfter(event.endTime)) return _EventStatus.ended;
    return _EventStatus.open;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFF8),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildTimeCard(),
                if (event.rating > 0) ...[
                  const SizedBox(height: 12),
                  _buildRatingCard(context),
                ],
                if (event.foodItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildFoodItemsCard(),
                ],
                if (event.photos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildPhotosSection(context),
                ],
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDescriptionCard(context),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // ── Sliver hero app bar ────────────────────────────────────────────────────

  Widget _buildSliverAppBar(BuildContext context) {
    final hasPhoto = event.photos.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: _typeGradient.first,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _CircleButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: _CircleButton(
            icon: Icons.share_rounded,
            onTap: () => _shareEvent(context),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background: first photo or gradient
            if (hasPhoto)
              Image.network(
                event.photos.first,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _gradientBox(),
              )
            else
              _gradientBox(),
            // Bottom gradient overlay for text readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
            ),
            // Event info overlay at bottom of hero
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _typeBadge(context),
                      if (event.verified) _verifiedBadge(),
                      _statusBadge(context),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black45)],
                    ),
                  ),
                  if (event.city.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 13, color: Colors.white70),
                        const SizedBox(width: 3),
                        Text(
                          event.city,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientBox() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _typeGradient,
          ),
        ),
      );

  Widget _typeBadge(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_typeIcons[event.type] ?? Icons.event,
                size: 11, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              AppLocale.typeLabel(context, event.type),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
      );

  Widget _verifiedBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded,
                size: 11, color: Colors.greenAccent.shade100),
            const SizedBox(width: 3),
            Text(
              'Verified',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.greenAccent.shade100),
            ),
          ],
        ),
      );

  Widget _statusBadge(BuildContext context) {
    late final Color color;
    late final String label;
    late final IconData icon;

    if (_status == _EventStatus.open) {
      color = Colors.greenAccent;
      label = AppLocale.detailOpenNow.getString(context);
      icon = Icons.radio_button_checked_rounded;
    } else if (_status == _EventStatus.upcoming) {
      color = Colors.orangeAccent;
      label = AppLocale.detailUpcoming.getString(context);
      icon = Icons.schedule_rounded;
    } else {
      color = Colors.white54;
      label = AppLocale.detailEnded.getString(context);
      icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: color),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
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

  Widget _timeCell(IconData icon, String label, String value) => Expanded(
        child: Column(
          children: [
            Icon(icon, size: 16, color: _typeColor),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A0533)),
                textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _divider() =>
      Container(width: 1, height: 34, color: const Color(0xFFEEEEEE));

  // ── Rating card ────────────────────────────────────────────────────────────

  Widget _buildRatingCard(BuildContext context) {
    final stars = event.rating.clamp(0.0, 5.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.star_rounded,
                  size: 14, color: Colors.amber),
            ),
            const SizedBox(width: 10),
            Text(
              AppLocale.detailRating.getString(context),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A0533)),
            ),
            const Spacer(),
            Row(
              children: List.generate(5, (i) {
                if (i < stars.floor()) {
                  return const Icon(Icons.star_rounded,
                      size: 16, color: Colors.amber);
                } else if (i < stars) {
                  return const Icon(Icons.star_half_rounded,
                      size: 16, color: Colors.amber);
                } else {
                  return const Icon(Icons.star_outline_rounded,
                      size: 16, color: Colors.amber);
                }
              }),
            ),
            const SizedBox(width: 6),
            Text(
              stars.toStringAsFixed(1),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber),
            ),
          ],
        ),
      ),
    );
  }

  // ── Food items card ────────────────────────────────────────────────────────

  Widget _buildFoodItemsCard() {
    final items = event.foodItems
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.restaurant_rounded,
                      size: 13, color: _typeColor),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Food Items',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A0533)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: items
                  .map((item) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _typeColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _typeColor.withValues(alpha: 0.22)),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                              fontSize: 11,
                              color: _typeColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Photos section (horizontal scroll) ────────────────────────────────────

  Widget _buildPhotosSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocale.detailPhotos.getString(context),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A0533)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${event.photos.length}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _typeColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: event.photos.length,
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () => _openPhotoViewer(context, i),
              child: Padding(
                padding: EdgeInsets.only(
                    right: i < event.photos.length - 1 ? 10 : 0),
                child: Hero(
                  tag: 'photo_$i',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      event.photos[i],
                      width: 130,
                      height: 140,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, p) => p == null
                          ? child
                          : Container(
                              width: 130,
                              height: 140,
                              color: Colors.grey[100],
                              child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            ),
                      errorBuilder: (_, _, _) => Container(
                        width: 130,
                        height: 140,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image,
                            color: Colors.grey, size: 28),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Description card ───────────────────────────────────────────────────────

  Widget _buildDescriptionCard(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
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
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.info_outline_rounded,
                        size: 13, color: _typeColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocale.detailAbout.getString(context),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A0533)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.description,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.6),
              ),
            ],
          ),
        ),
      );

  // ── Sticky bottom bar ──────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _openDirections,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: _typeGradient),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _typeColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppLocale.detailGetDirections.getString(context),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _shareEvent(context),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: _typeColor.withValues(alpha: 0.2)),
                  ),
                  child:
                      Icon(Icons.share_rounded, color: _typeColor, size: 20),
                ),
              ),
            ],
          ),
        ),
      );

  // ── Actions ────────────────────────────────────────────────────────────────

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

// ── Circle button for hero overlay ────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
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
