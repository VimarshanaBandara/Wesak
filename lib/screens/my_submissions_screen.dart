import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/event_model.dart';
import '../services/firestore_service.dart';
import '../widgets/wesak_app_bar.dart';
import 'event_detail_screen.dart';

/// My Submissions screen - current user ගේ submitted events
/// Pending, approved, rejected status badge real-time show කරනවා
class MySubmissionsScreen extends StatelessWidget {
  const MySubmissionsScreen({super.key});

  static final _firestoreService = FirestoreService();

  static const _dark = Color(0xFF1A0533);
  static const _purple = Color(0xFF6A0080);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: const WesakAppBar(title: 'My Submissions'),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          final user = authSnapshot.data;

          if (user == null) {
            return _buildSignInPrompt();
          }

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
                return _buildEmptyState();
              }

              // Count badges
              final pending =
                  events.where((e) => e.status == 'pending').length;
              final approved =
                  events.where((e) => e.status == 'approved').length;
              final rejected =
                  events.where((e) => e.status == 'rejected').length;

              return CustomScrollView(
                slivers: [
                  // Stats header
                  SliverToBoxAdapter(
                    child: _buildStatsHeader(
                        pending, approved, rejected, events.length),
                  ),

                  // List
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SubmissionCard(event: events[index]),
                        ),
                        childCount: events.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(
      int pending, int approved, int rejected, int total) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_dark, _purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _dark.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_note,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Submissions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$total event${total == 1 ? '' : 's'} submitted',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statBadge(pending.toString(), 'Pending',
                  const Color(0xFFFFA000)),
              const SizedBox(width: 10),
              _statBadge(approved.toString(), 'Live',
                  const Color(0xFF2E7D32)),
              const SizedBox(width: 10),
              _statBadge(rejected.toString(), 'Rejected',
                  const Color(0xFFC62828)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline, size: 38, color: _purple),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sign in required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Go to Profile tab to sign in',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add_circle_outline,
                size: 42, color: _purple.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 20),
          const Text(
            'No submissions yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add an event from the Add tab',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final EventModel event;

  const _SubmissionCard({required this.event});

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

  static const _statusConfig = {
    'pending': _StatusConfig(
      label: 'Pending',
      icon: Icons.hourglass_top_rounded,
      color: Color(0xFFFFA000),
      bg: Color(0xFFFFF8E1),
    ),
    'approved': _StatusConfig(
      label: 'Live',
      icon: Icons.check_circle_rounded,
      color: Color(0xFF2E7D32),
      bg: Color(0xFFE8F5E9),
    ),
    'rejected': _StatusConfig(
      label: 'Rejected',
      icon: Icons.cancel_rounded,
      color: Color(0xFFC62828),
      bg: Color(0xFFFFEBEE),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final status =
        _statusConfig[event.status] ?? _statusConfig['pending']!;
    final gradients =
        _typeGradients[event.type] ?? [Colors.grey, Colors.grey];
    final typeIcon = _typeIcons[event.type] ?? Icons.event;
    final typeLabel = _typeLabels[event.type] ?? event.type;

    return GestureDetector(
      onTap: () {
        if (event.status == 'approved') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EventDetailScreen(event: event)),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Type color bar + icon
            Container(
              width: 64,
              height: 80,
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
              child: Icon(typeIcon, color: Colors.white, size: 26),
            ),

            // Content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + status badge row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            event.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A0533),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: status.bg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(status.icon,
                                  size: 11, color: status.color),
                              const SizedBox(width: 3),
                              Text(
                                status.label,
                                style: TextStyle(
                                  color: status.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Type + city
                    Row(
                      children: [
                        Text(
                          typeLabel,
                          style: TextStyle(
                              fontSize: 12, color: gradients.first),
                        ),
                        Text(
                          '  •  ',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 12),
                        ),
                        Expanded(
                          child: Text(
                            event.city,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Chevron (only for approved)
            if (event.status == 'approved')
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right,
                    color: Colors.grey[300], size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusConfig {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  const _StatusConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
  });
}
