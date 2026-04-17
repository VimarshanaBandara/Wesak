import 'package:flutter/material.dart';

import '../widgets/wesak_app_bar.dart';
import 'event_list_screen.dart';

/// Home screen - welcome banner + event category grid
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WesakAppBar(title: 'Wesak 2026'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top welcome banner
            _buildWelcomeBanner(context),
            const SizedBox(height: 24),

            Text(
              'Browse by Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            // 2x2 category grid
            _buildCategoryGrid(context),
          ],
        ),
      ),
    );
  }

  /// Gradient banner with Sinhala greeting
  Widget _buildWelcomeBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'සුභ වෙසක් !',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Explore Dansal, Thorana & more near you',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    const categories = [
      _Category(name: 'Dansal', eventType: 'dansal', icon: Icons.restaurant, color: Colors.orange),
      _Category(name: 'Thorana', eventType: 'thorana', icon: Icons.account_balance, color: Colors.purple),
      _Category(name: 'Wesak Kudu', eventType: 'kudu', icon: Icons.wb_sunny, color: Color(0xFFFFB300)),
      _Category(name: 'Bhakthi Geetha', eventType: 'geetha', icon: Icons.music_note, color: Colors.blue),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      // Disable grid's own scroll - parent SingleChildScrollView handles it
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: categories
          .map((cat) => _buildCategoryCard(context, cat))
          .toList(),
    );
  }

  Widget _buildCategoryCard(BuildContext context, _Category cat) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventListScreen(
              eventType: cat.eventType,
              displayName: cat.name,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cat.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cat.color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(cat.icon, size: 42, color: cat.color),
            const SizedBox(height: 10),
            Text(
              cat.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cat.color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category tile data
class _Category {
  final String name;
  final String eventType; // Firestore type field value
  final IconData icon;
  final Color color;

  const _Category({
    required this.name,
    required this.eventType,
    required this.icon,
    required this.color,
  });
}
