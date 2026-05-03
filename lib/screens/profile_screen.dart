import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../l10n/app_locale.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/wesak_app_bar.dart';
import 'admin/admin_screen.dart';

/// Profile screen - user info, Google Sign-In, language switcher, admin panel
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static final _auth = AuthService();
  static final _userService = UserService();

  static const _purple = Color(0xFF6A0080);
  static const _saffron = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: WesakAppBar(title: AppLocale.profileTitle.getString(context)),
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
        _buildHeader(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: _purple.withValues(alpha: 0.12),
                child: const Icon(Icons.person, size: 40, color: _purple),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocale.profileGuest.getString(context),
                style: const TextStyle(
                  color: Color(0xFF1A0533),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocale.profileGuestSubtitle.getString(context),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Sign in button
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.login, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    AppLocale.profileSignIn.getString(context),
                    style: const TextStyle(
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: _purple, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        AppLocale.profileAdminBadge.getString(context),
                        style: const TextStyle(
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
              if (isAdmin) ...[
                _sectionLabel(AppLocale.profileAdmin.getString(context)),
                _tile(
                  icon: Icons.admin_panel_settings,
                  iconBg: _purple,
                  title: AppLocale.profileAdminPanel.getString(context),
                  subtitle: AppLocale.profileAdminSubtitle.getString(context),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _sectionLabel(AppLocale.profileSettings.getString(context)),
              _buildSettingsCard(context,
                  onDeleteAccount: () => _confirmDeleteAccount(context)),
              const SizedBox(height: 20),

              _sectionLabel(AppLocale.profileAccount.getString(context)),
              _tile(
                icon: Icons.logout,
                iconBg: Colors.redAccent,
                title: AppLocale.profileSignOut.getString(context),
                onTap: () => _auth.signOut(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // ── Header banner ────────────────────────────────────────────────────────
  Widget _buildHeader({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
      child: child,
    );
  }

  // ── Settings card ────────────────────────────────────────────────────────
  Widget _buildSettingsCard(BuildContext context,
      {VoidCallback? onDeleteAccount}) {
    final langCode = Localizations.localeOf(context).languageCode;
    final langSubtitle = langCode == 'si'
        ? AppLocale.profileLangSi.getString(context)
        : AppLocale.profileLangEn.getString(context);

    return Column(
      children: [
        _tile(
          icon: Icons.language,
          iconBg: const Color(0xFF1565C0),
          title: AppLocale.profileLanguage.getString(context),
          subtitle: langSubtitle,
          onTap: () => _showLanguagePicker(context),
        ),
        const SizedBox(height: 8),
        _tile(
          icon: Icons.notifications_outlined,
          iconBg: _saffron,
          title: AppLocale.profileNotifications.getString(context),
          subtitle: AppLocale.profileManageAlerts.getString(context),
          onTap: () {},
        ),
        if (onDeleteAccount != null) ...[
          const SizedBox(height: 8),
          _tile(
            icon: Icons.delete_forever_outlined,
            iconBg: Colors.red,
            title: AppLocale.profileDeleteAccount.getString(context),
            onTap: onDeleteAccount,
          ),
        ],
        const SizedBox(height: 8),
        _tile(
          icon: Icons.info_outline,
          iconBg: _purple,
          title: AppLocale.profileAbout.getString(context),
          subtitle: AppLocale.profileAboutSubtitle.getString(context),
          onTap: () {},
        ),
      ],
    );
  }

  // ── Language picker bottom sheet ─────────────────────────────────────────
  void _showLanguagePicker(BuildContext context) {
    final currentLang = Localizations.localeOf(context).languageCode;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Text(
                AppLocale.profileSelectLang.getString(context),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A0533),
                ),
              ),
              const SizedBox(height: 16),

              // English option
              _langOption(
                context: context,
                flag: '🇬🇧',
                label: 'English',
                langCode: 'en',
                selected: currentLang == 'en',
              ),
              const SizedBox(height: 10),

              // Sinhala option
              _langOption(
                context: context,
                flag: '🇱🇰',
                label: 'සිංහල',
                langCode: 'si',
                selected: currentLang == 'si',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _langOption({
    required BuildContext context,
    required String flag,
    required String label,
    required String langCode,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        FlutterLocalization.instance.translate(langCode);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1565C0).withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF1565C0)
                : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? const Color(0xFF1565C0)
                      : const Color(0xFF1A0533),
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF1565C0), size: 20),
          ],
        ),
      ),
    );
  }

  // ── Single tile ──────────────────────────────────────────────────────────
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
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  // ── Section label ────────────────────────────────────────────────────────
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

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocale.profileDeleteConfirmTitle.getString(context),
            style: const TextStyle(
                color: Color(0xFF1A0533), fontWeight: FontWeight.bold)),
        content: Text(AppLocale.profileDeleteConfirmMsg.getString(context),
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocale.adminCancel.getString(context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocale.profileDeleteConfirmBtn.getString(context),
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _auth.deleteAccount();
    } catch (e) {
      if (context.mounted && '$e' != 'Exception: cancelled') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              context.formatString(AppLocale.commonSignInFailed, ['$e'])),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _signIn(BuildContext context) async {
    try {
      await _auth.signInWithGoogle();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.formatString(AppLocale.commonSignInFailed, ['$e']),
            ),
          ),
        );
      }
    }
  }
}
