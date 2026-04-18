import 'package:flutter/material.dart';

import '../models/event_model.dart';
import '../screens/event_detail_screen.dart';

/// Reusable event card - EventListScreen + SearchScreen ෙකදී use කරනවා
class EventCard extends StatelessWidget {
  final EventModel event;
  final double? distanceKm;

  const EventCard({super.key, required this.event, this.distanceKm});

  static const _typeIcons = {
    'dansal': Icons.restaurant,
    'thorana': Icons.account_balance,
    'kudu': Icons.light_mode,
    'geetha': Icons.music_note,
  };

  static const _typeGradients = {
    'dansal': [Color(0xFFBF360C), Color(0xFFFF6D00)],
    'thorana': [Color(0xFF4A148C), Color(0xFF7B1FA2)],
    'kudu': [Color(0xFFF57F17), Color(0xFFFFD600)],
    'geetha': [Color(0xFF0D47A1), Color(0xFF1976D2)],
  };

  static const _typeLabels = {
    'dansal': 'Dansal',
    'thorana': 'Thorana',
    'kudu': 'Wesak Kudu',
    'geetha': 'Bhakthi Geetha',
  };

  @override
  Widget build(BuildContext context) {
    final gradients =
        _typeGradients[event.type] ?? [Colors.grey, Colors.blueGrey];
    final icon = _typeIcons[event.type] ?? Icons.event;
    final typeLabel = _typeLabels[event.type] ?? event.type;
    final hasPhoto = event.photos.isNotEmpty;

    return GestureDetector(
      onTap: () => showDetail(context, event),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left gradient strip + icon
            Container(
              width: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradients,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              constraints: const BoxConstraints(minHeight: 80),
              child: Icon(icon, color: Colors.white, size: 26),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      event.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A0533),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // Type chip + city
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                gradients.first.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: gradients.first,
                            ),
                          ),
                        ),
                        if (event.city.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              event.city,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Description
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        event.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 12),
                      ),
                    ],

                    // Distance badge
                    if (distanceKm != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.near_me,
                              size: 12, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 3),
                          Text(
                            distanceKm! < 1
                                ? '${(distanceKm! * 1000).round()} m away'
                                : '${distanceKm!.toStringAsFixed(1)} km away',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Photo thumbnail
            if (hasPhoto)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    event.photos.first,
                    width: 62,
                    height: 62,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) =>
                        progress == null
                            ? child
                            : Container(
                                width: 62,
                                height: 62,
                                color: Colors.grey[100],
                              ),
                    errorBuilder: (_, _, _) => Container(
                      width: 62,
                      height: 62,
                      color: Colors.grey[100],
                      child: const Icon(Icons.broken_image,
                          color: Colors.grey, size: 20),
                    ),
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right,
                    color: Colors.grey, size: 18),
              ),
          ],
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
