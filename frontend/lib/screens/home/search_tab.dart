import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/song_model.dart';
import '../../widgets/song_card.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  List<Song> songResults = [];
  bool isLoading = false;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() { songResults = []; });
        return;
      }
      
      setState(() { isLoading = true; });
      try {
        final res = await ApiService.get('/search?q=$query');
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          setState(() {
            songResults = (data['songs'] as List).map((s) => Song.fromJson(s)).toList();
          });
        }
      } catch (e) {
        print(e);
      } finally {
        setState(() { isLoading = false; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: const InputDecoration(
              labelText: 'Search songs, artists...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        if (isLoading) const Center(child: CircularProgressIndicator()),
        if (!isLoading && songResults.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: songResults.length,
              itemBuilder: (ctx, i) => SongCard(song: songResults[i]),
            ),
          ),
        if (!isLoading && songResults.isEmpty && _searchController.text.isNotEmpty)
          const Expanded(child: Center(child: Text('No results found.'))),
      ],
    );
  }
}
