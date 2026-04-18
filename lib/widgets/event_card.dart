import 'package:flutter/material.dart';

import '../models/event_model.dart';
import '../screens/event_detail_screen.dart';

/// Reusable event card - EventListScreen + SearchScreen ෙකදී use කරනවා
class EventCard extends StatelessWidget {
  final EventModel event;

  const EventCard({super.key, required this.event});

  static const Map<String, IconData> _typeIcons = {
    'dansal': Icons.restaurant,
    'thorana': Icons.account_balance,
    'kudu': Icons.wb_sunny,
    'geetha': Icons.music_note,
  };

  static const Map<String, Color> _typeColors = {
    'dansal': Colors.orange,
    'thorana': Colors.purple,
    'kudu': Color(0xFFFFB300),
    'geetha': Colors.blue,
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[event.type] ?? Colors.grey;
    final icon = _typeIcons[event.type] ?? Icons.event;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => EventCard.showDetail(context, event),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),

              // Event info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (event.city.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text(
                            event.city,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),

              // Photo thumbnail
              if (event.photos.isNotEmpty) ...[
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    event.photos.first,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void showDetail(BuildContext context, EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(event: event),
      ),
    );
  }
}
