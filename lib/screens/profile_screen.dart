import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/wesak_app_bar.dart';
import 'admin/admin_screen.dart';

/// Profile screen - user info, Google Sign-In, admin panel
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static final _auth = AuthService();
  static final _userService = UserService();

  // Wesak theme colors
  static const _purple = Color(0xFF6A0080);
  static const _saffron = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const WesakAppBar(title: 'Profile'),
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges,
        builder: (context, authSnapshot) {
          final user = authSnapshot.data;

          if (user == null) {
            return _buildGuestView(context);
          }

          return StreamBuilder<String>(
            stream: _userService.getUserRoleStream(user.uid),
            builder: (context, roleSnapshot) {
              final isAdmin = roleSnapshot.data == 'admin';
              return _buildLoggedInView(context, user, isAdmin);
            },
          );
        },
      ),
    );
  }

  // ── Guest view ──────────────────────────────────────────────────────────
  Widget _buildGuestView(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Header
        _buildHeader(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: _purple.withValues(alpha: 0.12),
                child: const Icon(Icons.person, size: 40, color: _purple),
              ),
              const SizedBox(height: 12),
              const Text(
                'Guest User',
                style: TextStyle(
                  color: Color(0xFF1A0533),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sign in to add events & track submissions',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Sign in button - prominent
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () => _signIn(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _saffron,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _saffron.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Sign in with Google',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSettingsCard(context),
        ),
      ],
    );
  }

  // ── Logged-in view ──────────────────────────────────────────────────────
  Widget _buildLoggedInView(BuildContext context, User user, bool isAdmin) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Header
        _buildHeader(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                backgroundColor: _purple.withValues(alpha: 0.12),
                child: user.photoURL == null
                    ? const Icon(Icons.person, size: 40, color: _purple)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                user.displayName ?? 'User',
                style: const TextStyle(
                  color: Color(0xFF1A0533),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email ?? '',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (isAdmin) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _purple.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: _purple, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Administrator',
                        style: TextStyle(
                          color: _purple,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin panel tile
              if (isAdmin) ...[
                _sectionLabel('Admin'),
                _tile(
                  icon: Icons.admin_panel_settings,
                  iconBg: _purple,
                  title: 'Admin Panel',
                  subtitle: 'Review pending submissions',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _sectionLabel('Settings'),
              _buildSettingsCard(context),
              const SizedBox(height: 20),

              _sectionLabel('Account'),
              _tile(
                icon: Icons.logout,
                iconBg: Colors.redAccent,
                title: 'Sign Out',
                onTap: () => _auth.signOut(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // ── Reusable header banner ──────────────────────────────────────────────
  Widget _buildHeader({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
      child: child,
    );
  }

  // ── Settings card ───────────────────────────────────────────────────────
  Widget _buildSettingsCard(BuildContext context) {
    return Column(
      children: [
        _tile(
          icon: Icons.language,
          iconBg: const Color(0xFF1565C0),
          title: 'Language',
          subtitle: 'English',
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _tile(
          icon: Icons.notifications_outlined,
          iconBg: _saffron,
          title: 'Notifications',
          subtitle: 'Manage alerts',
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _tile(
          icon: Icons.info_outline,
          iconBg: _purple,
          title: 'About',
          subtitle: 'Wesak 2026 · v1.0.0',
          onTap: () {},
        ),
      ],
    );
  }

  // ── Single tile ─────────────────────────────────────────────────────────
  Widget _tile({
    required IconData icon,
    required Color iconBg,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A0533),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section label ───────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Future<void> _signIn(BuildContext context) async {
    try {
      await _auth.signInWithGoogle();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    }
  }
}
