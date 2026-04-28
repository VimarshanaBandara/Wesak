import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../../l10n/app_locale.dart';
import '../../models/event_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/wesak_app_bar.dart';

/// Admin Panel - pending events approve/reject
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  static final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WesakAppBar(
        title: AppLocale.adminTitle.getString(context),
        showBackButton: true,
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: _firestoreService.getPendingEventsStream(),
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
                  const Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(AppLocale.adminNoPending.getString(context)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _PendingEventCard(event: events[index]),
          );
        },
      ),
    );
  }
}

class _PendingEventCard extends StatelessWidget {
  final EventModel event;

  const _PendingEventCard({required this.event});

  static final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    AppLocale.typeLabel(context, event.type).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (event.city.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_city,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(event.city,
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),

            if (event.lat != 0.0 && event.lng != 0.0) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${event.lat.toStringAsFixed(4)}, ${event.lng.toStringAsFixed(4)}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],

            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(event.description),
            ],

            if (event.photos.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: event.photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      event.photos[i],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) =>
                          progress == null
                              ? child
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(context),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: Text(
                      AppLocale.adminReject.getString(context),
                      style: const TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _approve(context),
                    icon: const Icon(Icons.check),
                    label:
                        Text(AppLocale.adminApprove.getString(context)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    try {
      await _firestoreService.approveEvent(event.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.formatString(
                  AppLocale.adminApprovedMsg, [event.name]),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocale.adminRejectTitle.getString(context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppLocale.adminReject.getString(context)} "${event.name}"?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText:
                    AppLocale.adminRejectReason.getString(context),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text(AppLocale.adminCancel.getString(context)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child:
                Text(AppLocale.adminReject.getString(context)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await _firestoreService.rejectEvent(
          event.id,
          reason: reasonController.text.trim().isEmpty
              ? null
              : reasonController.text.trim(),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.formatString(
                    AppLocale.adminRejectedMsg, [event.name]),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}
