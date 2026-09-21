import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/song.dart';

class AudioPlayerService {
  static final AudioPlayerService instance = AudioPlayerService._internal();
  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();

  List<Song> _queue = [];
  int _currentIndex = -1;

  AudioPlayer get player => _player;
  List<Song> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  Song? get currentSong {
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      return _queue[_currentIndex];
    }
    return null;
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<bool> get shuffleModeEnabledStream => _player.shuffleModeEnabledStream;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  Stream<double> get volumeStream => _player.volumeStream;

  void init() {
    // Listen to index changes from just_audio
    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _queue.length) {
        _currentIndex = index;
      }
    });

    // Handle playback completion: automatically go to next if applicable
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_player.loopMode == LoopMode.one) {
          _player.seek(Duration.zero);
          _player.play();
        } else if (_currentIndex < _queue.length - 1) {
          playNext();
        } else if (_player.loopMode == LoopMode.all) {
          playAtIndex(0);
        }
      }
    });
  }

  AudioSource _createAudioSource(Song song) {
    Uri? artUri;
    if (song.thumbnailPath.isNotEmpty) {
      if (song.thumbnailPath.startsWith('http://') ||
          song.thumbnailPath.startsWith('https://')) {
        artUri = Uri.tryParse(song.thumbnailPath);
      } else if (File(song.thumbnailPath).existsSync()) {
        artUri = Uri.file(song.thumbnailPath);
      }
    }

    if (song.isOnline ||
        song.filePath.startsWith('http://') ||
        song.filePath.startsWith('https://')) {
      return AudioSource.uri(
        Uri.parse(song.filePath),
        tag: MediaItem(
          id: song.id,
          album: 'Swiss Online Stream',
          title: song.title,
          artist: song.artist,
          artUri: artUri,
          duration: Duration(seconds: song.duration),
        ),
      );
    }

    return AudioSource.file(
      song.filePath,
      tag: MediaItem(
        id: song.id,
        album: 'Swiss Offline Music',
        title: song.title,
        artist: song.artist,
        artUri: artUri,
        duration: Duration(seconds: song.duration),
      ),
    );
  }

  /// Sets a new playlist / queue of verified local songs and begins playback at index
  Future<void> setQueue(List<Song> songs, {int initialIndex = 0}) async {
    if (songs.isEmpty) return;

    _queue = List.from(songs);
    _currentIndex = initialIndex.clamp(0, _queue.length - 1);

    final sources = _queue.map((s) => _createAudioSource(s)).toList();

    try {
      await _player.setAudioSources(
        sources,
        initialIndex: _currentIndex,
        initialPosition: Duration.zero,
      );
      await _player.play();
    } catch (e) {
      debugPrint('Error loading audio source: $e');
      rethrow;
    }
  }

  /// Plays a single song immediately
  Future<void> playSong(Song song) async {
    final index = _queue.indexWhere((s) => s.id == song.id);
    if (index >= 0) {
      await playAtIndex(index);
    } else {
      await setQueue([song], initialIndex: 0);
    }
  }

  Future<void> playAtIndex(int index) async {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      await _player.seek(Duration.zero, index: index);
      await _player.play();
    }
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> playNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
      await _player.play();
    } else if (_currentIndex < _queue.length - 1) {
      await playAtIndex(_currentIndex + 1);
    } else if (_player.loopMode == LoopMode.all && _queue.isNotEmpty) {
      await playAtIndex(0);
    }
  }

  Future<void> playPrevious() async {
    // If we are more than 3 seconds into the song, restart it
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      await _player.play();
    } else if (_currentIndex > 0) {
      await playAtIndex(_currentIndex - 1);
    }
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> toggleShuffle() async {
    final enable = !_player.shuffleModeEnabled;
    await _player.setShuffleModeEnabled(enable);
  }

  Future<void> cycleLoopMode() async {
    switch (_player.loopMode) {
      case LoopMode.off:
        await _player.setLoopMode(LoopMode.all);
        break;
      case LoopMode.all:
        await _player.setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        await _player.setLoopMode(LoopMode.off);
        break;
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
