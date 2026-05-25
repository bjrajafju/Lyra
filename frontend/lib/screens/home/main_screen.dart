import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/band_provider.dart';
import '../../models/band_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/context_switcher.dart';
import 'discovery_tab.dart';
import 'search_tab.dart';
import 'library_tab.dart';
import '../profile/user_profile_screen.dart';
import '../band/band_dashboard.dart';
import '../band/song_management_screen.dart';
import '../band/manage_albums_screen.dart';
import '../band/band_layout_editor_screen.dart';
import '../band/manage_members_screen.dart';
import '../band/band_profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static int globalBandIndex = 0;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _bandIndex = 0;

  final _tabs = const [
    DiscoveryTab(),
    SearchTab(),
    LibraryTab(),
    UserProfileScreen()
  ];

  @override
  Widget build(BuildContext context) {
    final bandProvider = context.watch<BandProvider>();
    final isBandContext = bandProvider.isBandContext;
    final selectedBand = bandProvider.selectedBand;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const ProfileContextSwitcher(),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: Container(
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
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isBandContext
                ? _getBandScreen(MainScreen.globalBandIndex, selectedBand!)
                : _tabs[_currentIndex],
          ),
          Consumer<AudioProvider>(
            builder: (context, audio, _) {
              if (audio.currentSong == null) return const SizedBox.shrink();
              return const MiniPlayer();
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: isBandContext ? MainScreen.globalBandIndex : _currentIndex,
        onTap: (index) {
          setState(() {
            if (isBandContext) {
              MainScreen.globalBandIndex = index;
            } else {
              _currentIndex = index;
            }
          });
        },
        type: BottomNavigationBarType.fixed,
        items: isBandContext ? _bandItems() : _userItems(),
      ),
    );
  }

  List<BottomNavigationBarItem> _userItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
      BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
      BottomNavigationBarItem(
        icon: Icon(Icons.library_music),
        label: 'Library',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];
  }

  List<BottomNavigationBarItem> _bandItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
      BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Songs'),
      BottomNavigationBarItem(icon: Icon(Icons.album), label: 'Albums'),
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_customize),
        label: 'Layout',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Members'),
    ];
  }

  Widget _getBandScreen(int index, Band band) {
    switch (index) {
      case 0:
        return const BandDashboard();
      case 1:
        return SongManagementScreen(bandId: band.id);
      case 2:
        return ManageAlbumsScreen(bandId: band.id);
      case 3:
        return BandLayoutEditorScreen(bandId: band.id);
      case 4:
        return ManageMembersScreen(
          bandId: band.id,
          currentUserRole: band.roleInBand ?? 'editor',
        );
      default:
        return const BandDashboard();
    }
  }
}
