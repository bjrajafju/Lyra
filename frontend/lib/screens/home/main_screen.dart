import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mini_player.dart';
import 'discovery_tab.dart';
import 'search_tab.dart';
import 'library_tab.dart';
import '../profile/user_profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _tabs = const [DiscoveryTab(), SearchTab(), LibraryTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF00C853)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'LYRA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _tabs[_currentIndex]),
          Consumer<AudioProvider>(
            builder: (context, audio, _) {
              if (audio.currentSong == null) return const SizedBox.shrink();
              return const MiniPlayer();
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}
