import 'package:flutter/material.dart';

import '../widgets/wesak_app_bar.dart';
import 'event_list_screen.dart';
import 'nearby_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      appBar: WesakAppBar(
        title: 'Wesak 2026',
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
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
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 14),
              child: Text(
                'Browse by Category',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A0533),
                  letterSpacing: 0.3,
                ),
              ),
            ),
            _buildCategoryGrid(context),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0533), Color(0xFF6A0080)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A0533).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'සුභ වෙසක් !',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Explore Dansal, Thorana & more near you',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NearbyScreen()),
                      ),
                      child: _buildBadge(Icons.location_on, 'Find Nearby'),
                    ),
                    const SizedBox(width: 8),
                    _buildBadge(Icons.verified, 'Verified'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.light_mode,
              color: Color(0xFFFFCC40),
              size: 34,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    const categories = [
      _Category(
        name: 'Dansal',
        eventType: 'dansal',
        icon: Icons.restaurant,
        gradientColors: [Color(0xFFBF360C), Color(0xFFFF6D00)],
      ),
      _Category(
        name: 'Thorana',
        eventType: 'thorana',
        icon: Icons.account_balance,
        gradientColors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
      ),
      _Category(
        name: 'Wesak Kudu',
        eventType: 'kudu',
        icon: Icons.light_mode,
        gradientColors: [Color(0xFFF57F17), Color(0xFFFFD600)],
      ),
      _Category(
        name: 'Bhakthi Geetha',
        eventType: 'geetha',
        icon: Icons.music_note,
        gradientColors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.05,
      children: categories
          .map((cat) => _buildCategoryCard(context, cat))
          .toList(),
    );
  }

  Widget _buildCategoryCard(BuildContext context, _Category cat) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              EventListScreen(eventType: cat.eventType, displayName: cat.name),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: cat.gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cat.gradientColors.first.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(cat.icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Text(
                cat.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Tap to explore',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Category {
  final String name;
  final String eventType;
  final IconData icon;
  final List<Color> gradientColors;

  const _Category({
    required this.name,
    required this.eventType,
    required this.icon,
    required this.gradientColors,
  });
}
