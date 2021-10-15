import 'dart:async';
import 'package:fountain_tech_test/domain/audio_player.dart';
import 'package:fountain_tech_test/view/utils/tiles/podcasts_show_list_tile.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:fountain_tech_test/data/podcast_index_dot_org.dart';
import 'package:fountain_tech_test/domain/account.dart';
import 'package:fountain_tech_test/main.dart';

class DiscoverPage extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final Account account;
  const DiscoverPage({
    required this.audioPlayer,
    required this.account,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14.0),
            child: searchBar(context),
          ),
        ],
      ),
    );
  }

  Widget searchBar(BuildContext context) {
    return InkWell(
      onTap: () {
        showSearch(
            context: context,
            delegate:
                _SearchDelegate(audioPlayer: audioPlayer, account: account));
      },
      child: Container(
        width: double.infinity,
        height: 42,
        decoration: BoxDecoration(
          color: searchBarColor(context),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            SizedBox(width: 18),
            Icon(Icons.search),
            SizedBox(width: 8),
            Text(
              "Search",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Color searchBarColor(BuildContext context) {
    return PlatformBrightness.isLightMode(context)
        ? Colors.grey[300]!
        : Colors.grey[900]!;
  }
}

class _SearchDelegate extends SearchDelegate {
  final Account _account;
  final AudioPlayer _audioPlayer;
  final StreamController<String> _queryController =
      StreamController.broadcast();
  late Widget _searchResults;

  _SearchDelegate({required AudioPlayer audioPlayer, required Account account})
      : _audioPlayer = audioPlayer,
        _account = account {
    _searchResults = _buildSearchList();
  }

  StreamBuilder<List<PodcastShow>> _buildSearchList() {
    final _repo = PodcastIndexDotOrgRepo();

    return StreamBuilder<List<PodcastShow>>(
      stream: _queryController.stream
          .debounceTime(const Duration(milliseconds: 500))
          .asyncMap(_repo.search),
      initialData: const [],
      builder: (context, snapshot) {
        var shows = snapshot.data!;
        return ListView.builder(
          itemCount: shows.length,
          itemBuilder: (context, index) {
            var show = shows[index];
            return PodcastShowListTile(
              show: show,
              audioPlayer: _audioPlayer,
              account: _account,
            );
          },
        );
      },
    );
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
        onPressed: () {
          close(context, null);
        },
        icon: const BackButtonIcon());
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
          onPressed: () {
            query = '';
          },
          icon: const Icon(Icons.clear))
    ];
  }

  @override
  Widget buildResults(BuildContext context) {
    return _searchResults;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    _queryController.add(query);
    return _searchResults;
  }
}
