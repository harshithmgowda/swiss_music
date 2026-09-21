import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import '../services/audio_player_service.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayerService _playerService = AudioPlayerService.instance;

  PlayerState _playerState = PlayerState(false, ProcessingState.idle);
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;

  final List<StreamSubscription> _subscriptions = [];

  Song? get currentSong => _playerService.currentSong;
  bool get isPlaying => _playerState.playing;
  bool get isBuffering =>
      _playerState.processingState == ProcessingState.buffering ||
      _playerState.processingState == ProcessingState.loading;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  bool get isShuffle => _isShuffle;
  LoopMode get loopMode => _loopMode;
  List<Song> get queue => _playerService.queue;
  int get currentIndex => _playerService.currentIndex;

  bool get hasActiveTrack => currentSong != null;

  String get positionFormatted {
    final minutes = (_position.inSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_position.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get durationFormatted {
    final minutes = (_duration.inSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get progressFraction {
    if (_duration.inMilliseconds == 0) return 0.0;
    final val = _position.inMilliseconds / _duration.inMilliseconds;
    return val.clamp(0.0, 1.0);
  }

  void init() {
    _subscriptions.add(
      _playerService.playerStateStream.listen((state) {
        _playerState = state;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _playerService.positionStream.listen((pos) {
        _position = pos;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _playerService.durationStream.listen((dur) {
        _duration = dur ?? Duration.zero;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _playerService.currentIndexStream.listen((_) {
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _playerService.volumeStream.listen((vol) {
        _volume = vol;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _playerService.shuffleModeEnabledStream.listen((shuf) {
        _isShuffle = shuf;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _playerService.loopModeStream.listen((loop) {
        _loopMode = loop;
        notifyListeners();
      }),
    );
  }

  Future<void> playSong(Song song, {List<Song>? fullQueue}) async {
    final targetQueue = fullQueue ?? [song];
    final index = targetQueue.indexWhere((s) => s.id == song.id);
    await _playerService.setQueue(
      targetQueue,
      initialIndex: index >= 0 ? index : 0,
    );
  }

  Future<void> playAtIndex(int index) async {
    await _playerService.playAtIndex(index);
  }

  Future<void> togglePlayPause() async {
    await _playerService.togglePlayPause();
  }

  Future<void> seek(Duration newPosition) async {
    await _playerService.seek(newPosition);
  }

  Future<void> playNext() async {
    await _playerService.playNext();
  }

  Future<void> playPrevious() async {
    await _playerService.playPrevious();
  }

  Future<void> setVolume(double newVolume) async {
    await _playerService.setVolume(newVolume);
  }

  Future<void> toggleShuffle() async {
    await _playerService.toggleShuffle();
  }

  Future<void> cycleLoopMode() async {
    await _playerService.cycleLoopMode();
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }
}
