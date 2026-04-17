import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'admin/admin_screen.dart';

/// Profile screen - user info, Google Sign-In, admin panel
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static final _auth = AuthService();
  static final _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      // Auth state ට listen කරනවා
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges,
        builder: (context, authSnapshot) {
          final user = authSnapshot.data;

          if (user == null) {
            // Not logged in
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileHeader(context, null),
                const SizedBox(height: 24),
                _buildSettingsSection(context, false),
              ],
            );
          }

          // Logged in - role stream ට listen කරනවා
          return StreamBuilder<String>(
            stream: _userService.getUserRoleStream(user.uid),
            builder: (context, roleSnapshot) {
              final isAdmin = roleSnapshot.data == 'admin';

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildProfileHeader(context, user),
                  const SizedBox(height: 24),

                  // Admin panel button - role == 'admin' නම් විතරක් show
                  if (isAdmin) ...[
                    _buildAdminButton(context),
                    const SizedBox(height: 16),
                  ],

                  _buildSettingsSection(context, isAdmin),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Admin Panel ට navigate කරන button
  Widget _buildAdminButton(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        leading: Icon(
          Icons.admin_panel_settings,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          'Admin Panel',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text('Review pending event submissions'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminScreen()),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User? user) {
    if (user != null) {
      // Logged in state
      return Column(
        children: [
          CircleAvatar(
            radius: 48,
            // Google profile photo show කරනවා
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? const Icon(Icons.person, size: 48)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            user.displayName ?? 'User',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            user.email ?? '',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _auth.signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
        ],
      );
    }

    // Logged out state
    return Column(
      children: [
        const CircleAvatar(
          radius: 48,
          child: Icon(Icons.person, size: 48),
        ),
        const SizedBox(height: 12),
        Text(
          'Guest User',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Sign in to add events and track submissions',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _signIn(context),
          icon: const Icon(Icons.login),
          label: const Text('Sign in with Google'),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: const Text('English'),
                onTap: () {
                  // TODO: Language switcher (English / Sinhala)
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                onTap: () {
                  // TODO: Notification preferences
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                onTap: () {
                  // TODO: About screen
                },
              ),
            ],
          ),
        ),
      ],
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
