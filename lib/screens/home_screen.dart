import 'package:flutter/material.dart';

import '../widgets/wesak_app_bar.dart';
import 'event_list_screen.dart';

/// Home screen - welcome banner + event category grid
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Warm cream background - Wesak lantern glow feel
      backgroundColor: const Color(0xFFFFF8EE),
      appBar: const WesakAppBar(title: 'Wesak 2026'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(),
            const SizedBox(height: 24),

            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Browse by Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A0533),
                  letterSpacing: 0.3,
                ),
              ),
            ),

            _buildCategoryGrid(context),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0533), // Deep violet
            Color(0xFF6A0080), // Rich purple
            Color(0xFFBF360C), // Deep saffron
            Color(0xFFE65100), // Saffron orange
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A0080).withValues(alpha: 0.35),
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
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Explore Dansal, Thorana & more near you',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                // Badge row
                Row(
                  children: [
                    _buildBadge(Icons.location_on, 'Find Nearby'),
                    const SizedBox(width: 8),
                    _buildBadge(Icons.verified, 'Verified'),
                  ],
                ),
              ],
            ),
          ),
          // Decorative lantern icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.light_mode,
              color: Colors.amber,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
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
      children: categories.map((cat) => _buildCategoryCard(context, cat)).toList(),
    );
  }

  Widget _buildCategoryCard(BuildContext context, _Category cat) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventListScreen(
            eventType: cat.eventType,
            displayName: cat.name,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: cat.gradientColors,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: cat.gradientColors.last.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Subtle circle decoration top-right
            Positioned(
              top: -14,
              right: -14,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(cat.icon, color: Colors.white, size: 26),
                  ),
                  const Spacer(),
                  Text(
                    cat.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tap to explore',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
