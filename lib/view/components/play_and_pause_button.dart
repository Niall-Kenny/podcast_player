import 'package:flutter/material.dart';
import 'package:fountain_tech_test/data/podcast_index_dot_org.dart';
import 'package:fountain_tech_test/domain/audio_player.dart';

class PlayAndPauseButton extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final PodcastEpisode episode;
  const PlayAndPauseButton({
    required this.audioPlayer,
    required this.episode,
    Key? key,
  }) : super(key: key);

  @override
  State<PlayAndPauseButton> createState() => _PlayAndPauseButtonState();
}

class _PlayAndPauseButtonState extends State<PlayAndPauseButton> {
  late final Stream<PodcastEpisode?> _currentEpisodePlaying;

  @override
  void initState() {
    _currentEpisodePlaying = widget.audioPlayer.currentEpisodeStreaming();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ap = widget.audioPlayer;
    final episode = widget.episode;

    return StreamBuilder<PodcastEpisode?>(
        stream: _currentEpisodePlaying,
        builder: (context, snapshot) {
          return InkWell(
            onTap: () async {
              final episodeCurrentlyPaying = snapshot.data;
              final isStreamingEpisodeForThisButton =
                  episodeCurrentlyPaying != null &&
                      ap.isStreamingEpisode(episode: widget.episode);

              if (!isStreamingEpisodeForThisButton) {
                ap.play(episode: episode);
              }
              if (isStreamingEpisodeForThisButton && ap.isPlaying) {
                ap.pause();
              } else {
                ap.play(episode: episode);
              }
              setState(() {});
            },
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(
                buildIcon(ap, episode),
                color: Colors.black,
              ),
            ),
          );
        });
  }

  buildIcon(AudioPlayer ap, PodcastEpisode ep) {
    return ap.isStreamingEpisode(episode: ep)
        ? ap.isPlaying
            ? Icons.pause
            : Icons.play_arrow
        : Icons.play_arrow;
  }
}
