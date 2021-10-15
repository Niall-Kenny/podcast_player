import 'package:flutter/material.dart';
import 'package:fountain_tech_test/data/podcast_index_dot_org.dart';
import 'package:fountain_tech_test/domain/playlist.dart';
import 'package:fountain_tech_test/fount_test_app_bar.dart';
import 'dart:math' as math;

import 'package:fountain_tech_test/main.dart';
import 'package:fountain_tech_test/view/playlists_page.dart';

class EpisodePage extends StatelessWidget {
  final PodcastEpisode episode;
  final AudioPlayer audioPlayer;
  final Account account;
  final String tag;
  EpisodePage({
    required this.episode,
    required this.audioPlayer,
    required this.account,
    this.tag = '',
    Key? key,
  }) : super(key: key) {
    if (!audioPlayer.isStreamingEpisode(episode: episode)) {
      audioPlayer.load(episode: episode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final episodeImageheight = MediaQuery.of(context).size.height * .4;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: createTextScaleFactor(context),
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(
                flex: 2,
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      (MediaQuery.of(context).size.width - episodeImageheight) /
                          2,
                ),
                child: Hero(
                  tag: tag,
                  child: Image.network(
                    episode.image(),
                    width: episodeImageheight,
                    height: episodeImageheight,
                    errorBuilder: (_, __, ___) =>
                        leadingRandomColorSquare(context: context),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      (MediaQuery.of(context).size.width - episodeImageheight) /
                          2,
                ),
                child: Flexible(
                  child: Text(
                    episode.title(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 5,
                  ),
                ),
              ),
              const Spacer(),
              StreamBuilder<EpisodeAudioPosition>(
                  stream: audioPlayer.episodeAudioPosition(),
                  initialData: EpisodeAudioPosition.initial(),
                  builder: (context, snapshot) {
                    final data = snapshot.data!;

                    var barPercentage = data.position.inSeconds == 0 &&
                            data.episodeDuration.inSeconds == 0
                        ? 0.0
                        : (data.position.inSeconds /
                            (data.episodeDuration.inSeconds));

                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: (MediaQuery.of(context).size.width -
                                    episodeImageheight) /
                                2,
                          ),
                          child: LinearProgressIndicator(
                            value: barPercentage,
                            semanticsLabel: 'Podcast listening durartion',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 8.0,
                            right: 8.0,
                            top: 5,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _printDuration(
                                  data.position,
                                ),
                              ),
                              Text(
                                _printDuration(
                                  Duration(
                                    seconds: data.episodeDuration.inSeconds -
                                        data.position.inSeconds,
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    );
                  }),
              _AudioToolBar(audioPlayer: audioPlayer, episode: episode),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                      onPressed: () async {
                        final playlist = await raiseAddToPlaylistBottomSheet(
                          context: context,
                          account: account,
                        );
                        if (playlist != null) {
                          if (playlist.contains(episode: episode)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: const Duration(seconds: 3),
                                content: Text(
                                  'This episode has already been added to ${playlist.title}',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                            return;
                          }
                          playlist.add(episode: episode);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 3),
                              content: Text(
                                'This episode has been added to ${playlist.title}!',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.more_horiz))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<Playlist?> raiseAddToPlaylistBottomSheet({
    required BuildContext context,
    required Account account,
  }) async {
    return await showModalBottomSheet<Playlist>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: PlatformBrightness.isLightMode(context)
                ? Theme.of(context).scaffoldBackgroundColor
                : Colors.grey[900],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: double.infinity,
                height: 45,
                color: PlatformBrightness.isLightMode(context)
                    ? Colors.grey[300]
                    : Colors.grey[850],
                child: Center(
                  child: Text(
                    "Add to Playlist",
                    style: TextStyle(
                      color: PlatformBrightness.isLightMode(context)
                          ? Colors.black
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Playlist>>(
                    stream: account.latestPlaylists,
                    initialData: const [],
                    builder: (context, snapshot) {
                      final playlists = snapshot.data!;
                      if (playlists.isEmpty) {
                        return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "You haven't created a playlist yet.",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              OutlinedButton(
                                onPressed: () async {
                                  final textController =
                                      TextEditingController();
                                  final playlistName =
                                      await showModalBottomSheet<String>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AddPlaylistBottomSheet(
                                        textController: textController,
                                      );
                                    },
                                  );
                                  if (playlistName != null) {
                                    account.createPlaylist(title: playlistName);
                                  }
                                },
                                child: const Text("Create playlist"),
                              )
                            ]);
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          return PlaylistListTile(
                            playlist: playlist,
                            audioPlayer: audioPlayer,
                            account: account,
                            onTap: () {
                              Navigator.pop(context, playlist);
                            },
                          );
                        },
                      );
                    }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget leadingRandomColorSquare({
    required BuildContext context,
  }) {
    final episodeImageheight = MediaQuery.of(context).size.height * .4;
    return Container(
      height: episodeImageheight,
      width: episodeImageheight,
      color: Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
          .withOpacity(1.0),
    );
  }
}

class _AudioToolBar extends StatefulWidget {
  const _AudioToolBar({
    Key? key,
    required this.audioPlayer,
    required this.episode,
  }) : super(key: key);

  final AudioPlayer audioPlayer;
  final PodcastEpisode episode;

  @override
  State<_AudioToolBar> createState() => _AudioToolBarState();
}

class _AudioToolBarState extends State<_AudioToolBar> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RawMaterialButton(
          onPressed: () {
            widget.audioPlayer.replay(duration: const Duration(seconds: 30));
          },
          elevation: 0,
          child: const Icon(
            Icons.replay_30,
            size: 55.0,
          ),
          padding: const EdgeInsets.all(10.0),
          shape: const CircleBorder(),
        ),
        RawMaterialButton(
          onPressed: () {
            widget.audioPlayer.isPlaying
                ? widget.audioPlayer.pause()
                : widget.audioPlayer.play(episode: widget.episode);
            setState(() {});
          },
          elevation: 0,
          child: Icon(
            widget.audioPlayer.isPlaying ? Icons.pause : Icons.play_arrow,
            size: 55.0,
          ),
          padding: const EdgeInsets.all(10.0),
          shape: const CircleBorder(),
        ),
        RawMaterialButton(
          onPressed: () {
            widget.audioPlayer
                .skipForward(duration: const Duration(seconds: 30));
          },
          elevation: 0,
          child: const Icon(
            Icons.forward_30,
            size: 55.0,
          ),
          padding: const EdgeInsets.all(10.0),
          shape: const CircleBorder(),
        ),
      ],
    );
  }
}

String _printDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
}
