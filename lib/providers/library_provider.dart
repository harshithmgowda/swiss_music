import 'package:flutter/foundation.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../services/storage_service.dart';

class LibraryProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService.instance;

  List<Song> _songs = [];
  List<Playlist> _playlists = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<Song> get songs => List.unmodifiable(_songs);
  List<Playlist> get playlists => List.unmodifiable(_playlists);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isEmpty => _songs.isEmpty;

  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Scan and verify actual physical files exist on disk
      _songs = await _storageService.scanAndCleanLibrary();
      // 2. Load verified playlists
      _playlists = await _storageService.getAllPlaylists();
    } catch (e) {
      _errorMessage = 'Failed to load local library: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    try {
      _songs = await _storageService.scanAndCleanLibrary();
      _playlists = await _storageService.getAllPlaylists();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to refresh library: $e';
      notifyListeners();
    }
  }

  void addDownloadedSong(Song song) {
    // Avoid duplicate additions
    _songs.removeWhere((s) => s.id == song.id);
    _songs.insert(0, song);
    notifyListeners();
  }

  Future<void> deleteSong(String songId) async {
    try {
      await _storageService.deleteSong(songId);
      _songs.removeWhere((s) => s.id == songId);
      // Also reload playlists as song may have been in a playlist
      _playlists = await _storageService.getAllPlaylists();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete song: $e';
      notifyListeners();
    }
  }

  Future<void> createPlaylist(String name) async {
    if (name.trim().isEmpty) return;
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      await _storageService.createPlaylist(id, name.trim());
      _playlists = await _storageService.getAllPlaylists();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to create playlist: $e';
      notifyListeners();
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _storageService.deletePlaylist(playlistId);
      _playlists.removeWhere((p) => p.id == playlistId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete playlist: $e';
      notifyListeners();
    }
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    try {
      await _storageService.addSongToPlaylist(playlistId, songId);
      _playlists = await _storageService.getAllPlaylists();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add song to playlist: $e';
      notifyListeners();
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      await _storageService.removeSongFromPlaylist(playlistId, songId);
      _playlists = await _storageService.getAllPlaylists();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to remove song from playlist: $e';
      notifyListeners();
    }
  }
}
