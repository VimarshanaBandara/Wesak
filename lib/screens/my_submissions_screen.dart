import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../l10n/app_locale.dart';
import '../models/event_model.dart';
import '../services/firestore_service.dart';
import '../widgets/wesak_app_bar.dart';
import 'event_detail_screen.dart';

/// My Submissions screen - current user ගේ submitted events
class MySubmissionsScreen extends StatelessWidget {
  const MySubmissionsScreen({super.key});

  static final _firestoreService = FirestoreService();

  static const _dark = Color(0xFF1A0533);
  static const _purple = Color(0xFF6A0080);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: WesakAppBar(
          title: AppLocale.submissionsTitle.getString(context)),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          final user = authSnapshot.data;

          if (user == null) {
            return _buildSignInPrompt(context);
          }

          return StreamBuilder<List<EventModel>>(
            stream: _firestoreService.getUserEventsStream(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}'));
              }

              final events = snapshot.data ?? [];

              if (events.isEmpty) {
                return _buildEmptyState(context);
              }

              final pending =
                  events.where((e) => e.status == 'pending').length;
              final approved =
                  events.where((e) => e.status == 'approved').length;
              final rejected =
                  events.where((e) => e.status == 'rejected').length;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildStatsHeader(
                        context, pending, approved, rejected, events.length),
                  ),
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

  Widget _buildStatsHeader(BuildContext context, int pending, int approved,
      int rejected, int total) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  Text(
                    AppLocale.submissionsYour.getString(context),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    total == 1
                        ? context.formatString(
                            AppLocale.submissionsCountSingle, [total])
                        : context.formatString(
                            AppLocale.submissionsCountPlural, [total]),
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
              _statBadge(context, pending.toString(),
                  AppLocale.submissionsPending.getString(context),
                  const Color(0xFFFFA000)),
              const SizedBox(width: 10),
              _statBadge(context, approved.toString(),
                  AppLocale.submissionsLive.getString(context),
                  const Color(0xFF2E7D32)),
              const SizedBox(width: 10),
              _statBadge(context, rejected.toString(),
                  AppLocale.submissionsRejected.getString(context),
                  const Color(0xFFC62828)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBadge(
      BuildContext context, String count, String label, Color color) {
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

  Widget _buildSignInPrompt(BuildContext context) {
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
            child: const Icon(Icons.lock_outline,
                size: 38, color: _purple),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocale.addSignInRequired.getString(context),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocale.addGoToProfile.getString(context),
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
          Text(
            AppLocale.submissionsNoEvents.getString(context),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocale.submissionsAddHint.getString(context),
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

  static const _statusColors = {
    'pending': Color(0xFFFFA000),
    'approved': Color(0xFF2E7D32),
    'rejected': Color(0xFFC62828),
  };
  static const _statusBg = {
    'pending': Color(0xFFFFF8E1),
    'approved': Color(0xFFE8F5E9),
    'rejected': Color(0xFFFFEBEE),
  };
  static const _statusIcons = {
    'pending': Icons.hourglass_top_rounded,
    'approved': Icons.check_circle_rounded,
    'rejected': Icons.cancel_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final statusColor =
        _statusColors[event.status] ?? _statusColors['pending']!;
    final statusBg = _statusBg[event.status] ?? _statusBg['pending']!;
    final statusIcon =
        _statusIcons[event.status] ?? _statusIcons['pending']!;
    final gradients =
        _typeGradients[event.type] ?? [Colors.grey, Colors.grey];
    final typeIcon = _typeIcons[event.type] ?? Icons.event;
    final typeLabel = AppLocale.typeLabel(context, event.type);
    final statusLabel = AppLocale.statusLabel(context, event.status);

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
              child:
                  Icon(typeIcon, color: Colors.white, size: 26),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            color: statusBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon,
                                  size: 11, color: statusColor),
                              const SizedBox(width: 3),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
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
