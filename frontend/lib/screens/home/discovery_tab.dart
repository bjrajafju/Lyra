import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/song_model.dart';
import '../../services/api_service.dart';
import '../../widgets/song_card.dart';

class DiscoveryTab extends StatefulWidget {
  const DiscoveryTab({super.key});

  @override
  State<DiscoveryTab> createState() => _DiscoveryTabState();
}

class _DiscoveryTabState extends State<DiscoveryTab> {
  List<Song> trending = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDiscovery();
  }

  void fetchDiscovery() async {
    try {
      final res = await ApiService.get('/search/discovery');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          trending = (data['trending'] as List).map((e) => Song.fromJson(e)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Trending Now', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        ...trending.map((song) => SongCard(song: song)),
      ],
    );
  }
}
