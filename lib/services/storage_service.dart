import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/playlist.dart';
import '../models/song.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final docDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docDir.path, 'swiss_music.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE songs (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            duration INTEGER NOT NULL,
            filePath TEXT NOT NULL,
            fileSize INTEGER NOT NULL,
            format TEXT NOT NULL,
            bitrate INTEGER NOT NULL,
            thumbnailPath TEXT NOT NULL,
            downloadDate TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE playlists (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS playlist_songs (
            playlistId TEXT NOT NULL,
            songId TEXT NOT NULL,
            sortOrder INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (playlistId, songId),
            FOREIGN KEY (playlistId) REFERENCES playlists (id) ON DELETE CASCADE,
            FOREIGN KEY (songId) REFERENCES songs (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
      onOpen: (db) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<Directory> getMusicDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final musicDir = Directory(p.join(docDir.path, 'music'));
    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }
    return musicDir;
  }

  Future<Directory> getVideoDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final videoDir = Directory(p.join(docDir.path, 'videos'));
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }
    return videoDir;
  }

  Future<Directory> getThumbnailDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final thumbDir = Directory(p.join(docDir.path, 'thumbnails'));
    if (!await thumbDir.exists()) {
      await thumbDir.create(recursive: true);
    }
    return thumbDir;
  }

  /// App Startup: Scan library, verify referenced audio files exist on disk,
  /// prune missing files, and return verified list of songs.
  Future<List<Song>> scanAndCleanLibrary() async {
    final db = await database;
    final List<Map<String, dynamic>> rows = await db.query('songs');
    final List<Song> verifiedSongs = [];

    for (final row in rows) {
      final song = Song.fromMap(row);
      final audioFile = File(song.filePath);
      if (await audioFile.exists()) {
        verifiedSongs.add(song);
      } else {
        // Audio file no longer exists physically, remove invalid reference
        await db.delete('songs', where: 'id = ?', whereArgs: [song.id]);
        await db.delete(
          'playlist_songs',
          where: 'songId = ?',
          whereArgs: [song.id],
        );
        // Also cleanup thumbnail if it exists
        if (song.thumbnailPath.isNotEmpty) {
          final thumbFile = File(song.thumbnailPath);
          if (await thumbFile.exists()) {
            await thumbFile.delete();
          }
        }
      }
    }

    return verifiedSongs;
  }

  // --- SONGS CRUD ---

  Future<void> insertSong(Song song) async {
    final db = await database;
    await db.insert(
      'songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Song>> getAllSongs() async {
    final db = await database;
    final rows = await db.query('songs', orderBy: 'downloadDate DESC');
    return rows.map((r) => Song.fromMap(r)).toList();
  }

  Future<Song?> getSongById(String id) async {
    final db = await database;
    final rows = await db.query('songs', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Song.fromMap(rows.first);
  }

  Future<void> deleteSong(String id) async {
    final song = await getSongById(id);
    if (song != null) {
      // 1. Delete physical audio file
      final audioFile = File(song.filePath);
      if (await audioFile.exists()) {
        try {
          await audioFile.delete();
        } catch (_) {}
      }

      // 2. Delete physical thumbnail
      if (song.thumbnailPath.isNotEmpty) {
        final thumbFile = File(song.thumbnailPath);
        if (await thumbFile.exists()) {
          try {
            await thumbFile.delete();
          } catch (_) {}
        }
      }
    }

    // 3. Remove from database
    final db = await database;
    await db.delete('songs', where: 'id = ?', whereArgs: [id]);
    await db.delete('playlist_songs', where: 'songId = ?', whereArgs: [id]);
  }

  // --- PLAYLISTS CRUD ---

  Future<void> createPlaylist(String id, String name) async {
    final db = await database;
    final playlist = Playlist(
      id: id,
      name: name,
      createdAt: DateTime.now().toIso8601String(),
    );
    await db.insert('playlists', playlist.toMap());
  }

  Future<List<Playlist>> getAllPlaylists() async {
    final db = await database;
    final playlistRows = await db.query('playlists', orderBy: 'createdAt DESC');
    final List<Playlist> playlists = [];

    for (final row in playlistRows) {
      final playlistId = row['id'] as String;
      final songs = await getSongsForPlaylist(playlistId);
      playlists.add(Playlist.fromMap(row, songs: songs));
    }

    return playlists;
  }

  Future<List<Song>> getSongsForPlaylist(String playlistId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT s.* FROM songs s
      INNER JOIN playlist_songs ps ON s.id = ps.songId
      WHERE ps.playlistId = ?
      ORDER BY ps.sortOrder ASC
    ''',
      [playlistId],
    );

    return rows.map((r) => Song.fromMap(r)).toList();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final db = await database;
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as c FROM playlist_songs WHERE playlistId = ?',
      [playlistId],
    );
    final count = Sqflite.firstIntValue(countResult) ?? 0;

    await db.insert('playlist_songs', {
      'playlistId': playlistId,
      'songId': songId,
      'sortOrder': count,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final db = await database;
    await db.delete(
      'playlist_songs',
      where: 'playlistId = ? AND songId = ?',
      whereArgs: [playlistId, songId],
    );
  }

  Future<void> deletePlaylist(String playlistId) async {
    final db = await database;
    await db.delete('playlists', where: 'id = ?', whereArgs: [playlistId]);
    await db.delete(
      'playlist_songs',
      where: 'playlistId = ?',
      whereArgs: [playlistId],
    );
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first['value'] as String?;
    }
    return null;
  }
}
