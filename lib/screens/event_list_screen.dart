import 'package:flutter/material.dart';

import '../models/event_model.dart';
import '../services/firestore_service.dart';
import '../widgets/event_card.dart';
import '../widgets/wesak_app_bar.dart';

/// Category filtered event list screen
/// Home screen category card tap ෙකන් open වෙනවා
class EventListScreen extends StatefulWidget {
  /// Filter කරන event type - dansal | thorana | kudu | geetha
  final String eventType;

  /// AppBar title ට show කරන display name
  final String displayName;

  const EventListScreen({
    super.key,
    required this.eventType,
    required this.displayName,
  });

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final _firestoreService = FirestoreService();

  // Stream initState ේ store - rebuild ෙකදී restart නෑ
  late final Stream<List<EventModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _firestoreService.getEventsByTypeStream(widget.eventType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WesakAppBar(title: widget.displayName, showBackButton: true),
      body: StreamBuilder<List<EventModel>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No ${widget.displayName} found',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Be the first to add one!',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                EventCard(event: events[index]),
          );
        },
      ),
    );
  }
}
