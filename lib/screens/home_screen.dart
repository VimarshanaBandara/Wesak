import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../l10n/app_locale.dart';
import '../widgets/wesak_app_bar.dart';
import 'event_list_screen.dart';
import 'nearby_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _bgColor = Color(0xFF13132D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: WesakAppBar(
        title: AppLocale.homeTitle.getString(context),
        subtitle: '${AppLocale.homeGreeting.getString(context)} 🌟✨',
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(context),
            const SizedBox(height: 28),
            _buildCategoryHeader(context),
            const SizedBox(height: 14),
            _buildCategoryGrid(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF211F3F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.light_mode,
              color: Color(0xFFFFD600),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocale.homeGreeting.getString(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocale.homeSubtitle.getString(context),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NearbyScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A6FE8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocale.homeFindNearby.getString(context),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppLocale.homeBrowseCategory.getString(context),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
          child: Text(
            AppLocale.homeSeeAll.getString(context),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9B8FFF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    const categories = [
      _Category(
        eventType: 'dansal',
        icon: Icons.restaurant,
        glowColor: Color(0xFFE55B2D),
        imagePath: 'assets/image_03.jpg',
        imageAlignment: Alignment.centerLeft,
      ),
      _Category(
        eventType: 'thorana',
        icon: Icons.account_balance,
        glowColor: Color(0xFF4A7FE5),
        imagePath: 'assets/image_02.png',
        imageAlignment: Alignment.center,
      ),
      _Category(
        eventType: 'kudu',
        icon: Icons.light_mode,
        glowColor: Color(0xFFF5A623),
        imagePath: 'assets/image_01.jpg',
        imageAlignment: Alignment.topRight,
      ),
      _Category(
        eventType: 'geetha',
        icon: Icons.music_note,
        glowColor: Color(0xFF9B4FDB),
        imagePath: 'assets/image_04.jpg',
        imageAlignment: Alignment.bottomCenter,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.88,
      children: categories
          .map((cat) => _buildCategoryCard(context, cat))
          .toList(),
    );
  }

  Widget _buildCategoryCard(BuildContext context, _Category cat) {
    final displayName = AppLocale.typeLabel(context, cat.eventType);
    final description = AppLocale.typeDesc(context, cat.eventType);

    const double stripHeight = 70.0;
    const double circleSize = 40.0;
    const double circleLeft = 12.0;
    const Color kTitleColor = Color(0xFFFFD600);
    const Color kStripColor = Color(0xFF211F3F);
    const Color kSubtitle   = Color(0xFFA89EC0);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventListScreen(eventType: cat.eventType),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Column: image + dark strip
              Column(
                children: [
                  Expanded(
                    child: Image.asset(
                      cat.imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      alignment: cat.imageAlignment,
                    ),
                  ),
                  Container(
                    height: stripHeight,
                    width: double.infinity,
                    color: kStripColor,
                    padding: const EdgeInsets.only(
                      left: circleLeft + circleSize + 10,
                      right: 10,
                      top: 8,
                      bottom: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: kTitleColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: const TextStyle(
                            color: kSubtitle,
                            fontSize: 11,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Icon circle — straddles the image / strip boundary
              Positioned(
                bottom: stripHeight - circleSize / 2,
                left: circleLeft,
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    color: cat.glowColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(cat.icon, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Category {
  final String eventType;
  final IconData icon;
  final Color glowColor;
  final String imagePath;
  final Alignment imageAlignment;

  const _Category({
    required this.eventType,
    required this.icon,
    required this.glowColor,
    required this.imagePath,
    this.imageAlignment = Alignment.center,
  });
}
