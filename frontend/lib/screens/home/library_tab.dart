import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../band/band_dashboard.dart';

class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isArtist = auth.user?.role == 'artist';

    if (isArtist) {
      return const BandDashboard();
    }

    return const Center(child: Text('Your Library (Favorites, Playlists)'));
  }
}
