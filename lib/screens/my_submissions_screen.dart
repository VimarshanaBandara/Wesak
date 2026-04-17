import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/event_model.dart';
import '../services/firestore_service.dart';
import '../widgets/wesak_app_bar.dart';

/// My Submissions screen - current user ගේ submitted events
/// Pending, approved, rejected status badge real-time show කරනවා
class MySubmissionsScreen extends StatelessWidget {
  const MySubmissionsScreen({super.key});

  static final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WesakAppBar(title: 'My Submissions'),
      // Auth state check - login නැතිනම් prompt show
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          final user = authSnapshot.data;

          if (user == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Please sign in to view your submissions'),
                  SizedBox(height: 8),
                  Text(
                    'Go to Profile tab to sign in',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Logged in - user ගේ events Firestore stream
          return StreamBuilder<List<EventModel>>(
            stream: _firestoreService.getUserEventsStream(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final events = snapshot.data ?? [];

              if (events.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_note, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No submissions yet'),
                      SizedBox(height: 8),
                      Text(
                        'Add an event from the Add tab',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _SubmissionCard(event: events[index]),
              );
            },
          );
        },
      ),
    );
  }
}

/// Single submission card with real-time status badge
class _SubmissionCard extends StatelessWidget {
  final EventModel event;

  const _SubmissionCard({required this.event});

  static const Map<String, Color> _statusColors = {
    'pending': Colors.orange,
    'approved': Colors.green,
    'rejected': Colors.red,
  };

  static const Map<String, String> _statusLabels = {
    'pending': '⏳ Pending',
    'approved': '✅ Live',
    'rejected': '❌ Rejected',
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[event.status] ?? Colors.grey;
    final label = _statusLabels[event.status] ?? event.status;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.event_note),
        title: Text(event.name),
        subtitle: Text('${event.type} • ${event.city}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () {
          // TODO: Open event detail / edit screen
        },
      ),
    );
  }
}
