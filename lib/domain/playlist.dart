import 'package:fountain_tech_test/data/podcast_index_dot_org.dart';

class Playlist {
  final String title;
  DateTime lastUpdated;
  final List<PodcastEpisode> episodes = [];
  Playlist({
    required this.title,
  }) : lastUpdated = DateTime.now();

  String image() {
    return episodes.isNotEmpty ? episodes.first.image() : '';
  }

  void add({required PodcastEpisode episode}) {
    if (!contains(episode: episode)) {
      episodes.add(episode);
      lastUpdated = DateTime.now();
    }
  }

  bool contains({required PodcastEpisode episode}) {
    return episodes.any((e) => e.id() == episode.id());
  }
}
