import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/add_event_screen.dart';
import 'screens/my_submissions_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  // Flutter engine ready වෙනකම් wait කරනවා - async main ට required
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialize - google-services.json ෙකන් config load කරනවා
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const WesakApp());
}

/// App root widget - sets up theme and MaterialApp
class WesakApp extends StatelessWidget {
  const WesakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wesak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Wesak theme - warm amber/lantern color
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8F00), // Amber 800
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

/// App shell - holds the bottom navigation and switches between main screens
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Currently selected bottom nav tab index
  int _selectedIndex = 0;

  // Map tab ෙකට ආවෙකදී increment කරනවා - fresh MapScreen rebuild trigger
  int _mapVisitCount = 0;

  @override
  Widget build(BuildContext context) {
    // screens list - index ෙකන් current screen select කරනවා
    // MapScreen IndexedStack ෙකන් outside - tab switch ෙකදී fresh rebuild
    // FlutterMap + IndexedStack (Offstage) combination ේ rendering bug fix
    final screens = [
      const HomeScreen(),
      // MapScreen ට key දෙනවා - tab ෙකට ආවෙකදී always fresh FlutterMap
      MapScreen(key: ValueKey(_mapVisitCount)),
      const AddEventScreen(),
      const MySubmissionsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            // Map tab (index 1) ට ආවෙකදී counter increment - fresh rebuild
            if (index == 1) _mapVisitCount++;
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'My Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
