import 'package:flutter/material.dart';
import 'package:fountain_tech_test/data/podcast_index_dot_org.dart';
import 'package:fountain_tech_test/domain/account.dart';
import 'package:fountain_tech_test/main.dart';
import 'package:fountain_tech_test/view/episode_page.dart';

class PodcastEpisodeListItemTile extends StatelessWidget {
  final PodcastEpisode episode;
  final AudioPlayer audioPlayer;
  final Account account;
  const PodcastEpisodeListItemTile({
    required this.episode,
    required this.audioPlayer,
    required this.account,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => EpisodePage(
              episode: episode,
              audioPlayer: audioPlayer,
              account: account,
            ),
          ),
        );
      },
      title: Text(
        episodeAndDate(episode),
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),
          Text(
            episode.title(),
            style: TextStyle(
              color: PlatformBrightness.isLightMode(context)
                  ? Colors.black
                  : Colors.white,
              fontSize: 16,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(
            height: 5,
          ),
          Row(
            children: [
              PlayAndPauseButton(
                episode: episode,
                audioPlayer: audioPlayer,
              ),
              const SizedBox(width: 6),
              if (episode.duration() != null) Text(duration(episode)),
            ],
          ),
        ],
      ),
    );
  }

  String episodeAndDate(PodcastEpisode episode) {
    final hasEpNum = episode.episodeNum() != null;
    final date = episode.datePublished().toUpperCase().split(",")[0];
    return hasEpNum
        ? "Ep. " + episode.episodeNum().toString() + " · " + date
        : date;
  }

  String duration(PodcastEpisode episode) {
    final minutes = (episode.duration()! / 60);
    final shouldShowHourDisplay = minutes >= 60;
    return (shouldShowHourDisplay
        ? formatDurationAsHours(minutes)
        : formatDurationAsMinutes(minutes));
  }

  String formatDurationAsMinutes(num minutes) {
    final _minutes = minutes.round();
    return _minutes.toString() + " minute" + (_minutes > 1 ? "s" : "");
  }

  String formatDurationAsHours(num minutes) {
    final hours = (minutes / 60).floor();
    return hours.toString() +
        " hour" +
        (hours > 1 ? "s " : " ") +
        formatDurationAsMinutes(minutes - (hours * 60));
  }
}
