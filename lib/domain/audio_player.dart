import 'package:fountain_tech_test/data/podcast_index_dot_org.dart';
import 'package:fountain_tech_test/main.dart';
import 'package:just_audio/just_audio.dart' as JA;
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';

class AudioPlayer {
  final JA.AudioPlayer _player;
  final BehaviorSubject<PodcastEpisode?> _currentEpisodeStream =
      BehaviorSubject.seeded(null);
  bool _playing = false;
  final BehaviorSubject<List<PodcastEpisode>> _history =
      BehaviorSubject.seeded([]);
  AudioPlayer({required JA.AudioPlayer audioPlayer}) : _player = audioPlayer;

  bool get isPlaying => _playing; // ignore native controls for now.

  bool isStreamingEpisode({required PodcastEpisode episode}) {
    return _currentEpisodeStream.value?.id() == episode.id();
  }

  Stream<PodcastEpisode?> currentEpisodeStreaming() {
    return _currentEpisodeStream;
  }

  Future<void> load({required PodcastEpisode episode}) async {
    await _player.setUrl(episode.enclosureUrl());
  }

  void play({required PodcastEpisode episode}) {
    if (!isStreamingEpisode(episode: episode)) {
      _history.add([..._history.value, episode]);
      _currentEpisodeStream.add(episode);
      load(episode: episode);
    }
    _playing = true;
    _player.play();
  }

  Future<void> pause() async {
    _playing = false;
    await _player.pause();
  }

  List<PodcastEpisode> playHistroy() {
    return [..._history.value];
  }

  /// live history updates
  Stream<List<PodcastEpisode>> playHistroyStream() {
    return _history;
  }

  /// live updates of audio positions & states.
  /// - episdode duration
  /// - buffer position (loaded ahead time)
  /// - posistion within current episode
  /// - loading state
  Stream<EpisodeAudioPosition> episodeAudioPosition() {
    return CombineLatestStream.combine4<Duration, Duration, Duration?,
            JA.PlayerState, EpisodeAudioPosition>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        _player.playerStateStream, (a, b, c, d) {
      return EpisodeAudioPosition(
        position: a,
        bufferPosition: b,
        episodeDuration: c ?? Duration.zero,
        playerState: d,
      );
    });
  }

  void skipForward({required Duration duration}) {
    _player.seek(
      Duration(seconds: _player.position.inSeconds + duration.inSeconds),
    );
  }

  void replay({required Duration duration}) {
    _player.seek(
      Duration(seconds: _player.position.inSeconds - duration.inSeconds),
    );
  }

  Future<void> dispose() async {
    await _currentEpisodeStream.close();
    await _player.stop();
    await _player.dispose();
  }
}

class EpisodeAudioPosition {
  final Duration position;
  final Duration bufferPosition;
  final Duration episodeDuration;
  final JA.PlayerState _playerState;
  EpisodeAudioPosition({
    required this.position,
    required this.bufferPosition,
    required this.episodeDuration,
    required JA.PlayerState playerState,
  }) : _playerState = playerState;

  isLoading() {
    final processingState = _playerState.processingState;
    return processingState == JA.ProcessingState.loading ||
        processingState == JA.ProcessingState.buffering;
  }

  factory EpisodeAudioPosition.initial() {
    return EpisodeAudioPosition(
      position: Duration.zero,
      bufferPosition: Duration.zero,
      episodeDuration: Duration.zero,
      playerState: JA.PlayerState(false, JA.ProcessingState.loading),
    );
  }
}
