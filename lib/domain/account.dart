import 'package:fountain_tech_test/data/podcast_index_dot_org.dart';
import 'package:fountain_tech_test/domain/playlist.dart';
import 'package:rxdart/subjects.dart';

class Account {
  final String _name;
  final DateTime _createdOn;
  final BehaviorSubject<List<PodcastShow>> _latestShowFollowing =
      BehaviorSubject.seeded([]);

  final BehaviorSubject<List<Playlist>> _latestPlaylists =
      BehaviorSubject.seeded([]);
  Account(String name)
      : _name = name,
        _createdOn = DateTime.now();

  String get name => _name;
  DateTime get createdOn => _createdOn;

  List<PodcastShow> get following => [..._latestShowFollowing.value];

  Stream<List<PodcastShow>> get latestShowFollowing {
    return _latestShowFollowing;
  }

  bool isFollowing(PodcastShow show) {
    return following.any((s) => s.isTheSameAs(show));
  }

  void follow(PodcastShow show) {
    _latestShowFollowing.add([..._latestShowFollowing.value, show]);
  }

  void unfollow(PodcastShow show) {
    _latestShowFollowing
        .add(following.where((s) => !s.isTheSameAs(show)).toList());
  }

  /// stream of latest playlist collection
  Stream<List<Playlist>> get latestPlaylists {
    return _latestPlaylists;
  }

  createPlaylist({required String title}) {
    _latestPlaylists.add([..._latestPlaylists.value, Playlist(title: title)]);
  }
}
