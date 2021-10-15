import 'package:flutter/material.dart';
import 'package:fountain_tech_test/data/podcast_index_dot_org.dart';
import 'package:fountain_tech_test/domain/playlist.dart';
import 'package:fountain_tech_test/main.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class PlaylistsPage extends StatelessWidget {
  final Account account;
  final AudioPlayer audioPlayer;
  const PlaylistsPage({
    required this.account,
    required this.audioPlayer,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 30.0, left: 15),
          child: Text(
            "Your Playlists",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
        const SizedBox(
          height: 30,
        ),
        StreamBuilder<List<Playlist>>(
            stream: account.latestPlaylists,
            initialData: const [],
            builder: (context, snapshot) {
              final playlists = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return PlaylistListTile(
                    playlist: playlist,
                    audioPlayer: audioPlayer,
                    account: account,
                  );
                },
              );
            })
      ],
    );
  }
}

class PlaylistListTile extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final Playlist playlist;
  final Account account;

  /// defaults to [PlaylistListTile.defaultOnTap]
  final void Function()? onTap;
  const PlaylistListTile({
    Key? key,
    required this.playlist,
    required this.audioPlayer,
    required this.account,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else {
          defaultOnTap(
            context: context,
            account: account,
            playlist: playlist,
            audioPlayer: audioPlayer,
          );
        }
      },
      leading: createLeading(playlist),
      title: Text(playlist.title),
      subtitle: Text(
        DateFormat("d MMMM y").format(playlist.lastUpdated) +
            " · " +
            playlist.episodes.length.toString() +
            " episodes",
      ),
    );
  }

  Widget createLeading(Playlist playlist) {
    final containsEpisodes = playlist.episodes.isNotEmpty;
    final image = playlist.image();
    final imageIsValid = image.isNotEmpty;

    return imageIsValid && containsEpisodes
        ? Image.network(
            image,
            height: 60,
            width: 60,
            errorBuilder: (_, __, ___) => leadingRandomColorSquare(),
          )
        : leadingRandomColorSquare();
  }

  Widget leadingRandomColorSquare({Widget child = const SizedBox.shrink()}) {
    return Container(
      height: 60,
      width: 60,
      color: Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
          .withOpacity(1.0),
      child: child,
    );
  }

  // navigates to playlistPage
  static defaultOnTap({
    required BuildContext context,
    required Playlist playlist,
    required AudioPlayer audioPlayer,
    required Account account,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SeeAll(
          title: playlist.title,
          emptyState: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text(
                "This playlist is empty.",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 26.0, vertical: 10),
                child: Text(
                  "It looks like you haven't added any items to this playlist yet. Visit the Discover page to search for podcasts.",
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          itemCount: playlist.episodes.length,
          itemBuilder: (context, index) => PodcastListItemTile(
            episode: playlist.episodes[index],
            audioPlayer: audioPlayer,
            account: account,
          ),
        ),
      ),
    );
  }
}
