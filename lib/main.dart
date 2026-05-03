import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'firebase_options.dart';
import 'l10n/app_locale.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/map_screen.dart';
import 'screens/add_event_screen.dart';
import 'screens/my_submissions_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Google Maps Android renderer — tile rendering fix
  final mapsImpl = GoogleMapsFlutterPlatform.instance;
  if (mapsImpl is GoogleMapsFlutterAndroid) {
    mapsImpl.useAndroidViewSurface = false;
  }

  // Localization initialize - Sinhala + English
  FlutterLocalization.instance.init(
    mapLocales: [
      MapLocale('en', AppLocale.EN),
      MapLocale('si', AppLocale.SI),
    ],
    initLanguageCode: 'en',
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const WesakApp());
}

/// App root widget - localization + theme setup
class WesakApp extends StatefulWidget {
  const WesakApp({super.key});

  @override
  State<WesakApp> createState() => _WesakAppState();
}

class _WesakAppState extends State<WesakApp> {
  @override
  void initState() {
    super.initState();
    // Language change ෙකදී MaterialApp rebuild - locale update
    FlutterLocalization.instance.onTranslatedLanguage = _onTranslatedLanguage;
  }

  void _onTranslatedLanguage(Locale? locale) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dansal Go',
      debugShowCheckedModeBanner: false,
      // Localization delegates + supported locales
      supportedLocales: FlutterLocalization.instance.supportedLocales,
      localizationsDelegates: FlutterLocalization.instance.localizationsDelegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8F00),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(nextScreen: AppShell()),
    );
  }
}

/// App shell - bottom navigation
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  int _mapVisitCount = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      MapScreen(key: ValueKey(_mapVisitCount)),
      const AddEventScreen(),
      const MySubmissionsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: const Color(0xFF211F3F),
            indicatorColor: const Color(0xFF1A6FE8),
            surfaceTintColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                );
              }
              return const TextStyle(color: Colors.white54, fontSize: 11);
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Colors.white);
              }
              return const IconThemeData(color: Colors.white54);
            }),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              if (index == 1) _mapVisitCount++;
              _selectedIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: AppLocale.navHome.getString(context),
            ),
            NavigationDestination(
              icon: const Icon(Icons.map_outlined),
              selectedIcon: const Icon(Icons.map),
              label: AppLocale.navMap.getString(context),
            ),
            NavigationDestination(
              icon: const Icon(Icons.add_circle_outline),
              selectedIcon: const Icon(Icons.add_circle),
              label: AppLocale.navAdd.getString(context),
            ),
            NavigationDestination(
              icon: const Icon(Icons.list_alt_outlined),
              selectedIcon: const Icon(Icons.list_alt),
              label: AppLocale.navMyEvents.getString(context),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: AppLocale.navProfile.getString(context),
            ),
          ],
        ),
      ),
    );
  }
}
