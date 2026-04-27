import 'package:flutter/material.dart';

/// Custom Wesak AppBar - Wesak theme gradient + logo left
/// සියලු screens ෙකදී consistent look
class WesakAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  const WesakAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBackButton,
      backgroundColor: Colors.transparent,
      elevation: 3,
      shadowColor: Colors.black45,
      centerTitle: true,
      // Logo ට extra width
      leadingWidth: 72,

      flexibleSpace: Container(
        color: const Color(0xFF1A0533),
      ),

      // Logo left - bigger with minimal padding
      leading: showBackButton
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 2, 4),
              child: Image.asset(
                'assets/app_bar_image.png',
                fit: BoxFit.contain,
              ),
            ),

      iconTheme: const IconThemeData(color: Colors.white),

      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: Colors.black54,
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),

      actions: actions,
    );
  }
}
