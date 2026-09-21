import 'song.dart';

class Playlist {
  final String id;
  final String name;
  final String createdAt;
  final List<Song> songs;

  const Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
    this.songs = const [],
  });

  int get songCount => songs.length;

  int get totalDurationSeconds {
    return songs.fold(0, (sum, song) => sum + song.duration);
  }

  String get totalDurationFormatted {
    final minutes = (totalDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalDurationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'createdAt': createdAt};
  }

  factory Playlist.fromMap(
    Map<String, dynamic> map, {
    List<Song> songs = const [],
  }) {
    return Playlist(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Untitled Playlist',
      createdAt: map['createdAt'] as String? ?? '',
      songs: songs,
    );
  }

  Playlist copyWith({
    String? id,
    String? name,
    String? createdAt,
    List<Song>? songs,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      songs: songs ?? this.songs,
    );
  }
}

class PlaylistSong {
  final String playlistId;
  final String songId;
  final int sortOrder;

  const PlaylistSong({
    required this.playlistId,
    required this.songId,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {'playlistId': playlistId, 'songId': songId, 'sortOrder': sortOrder};
  }

  factory PlaylistSong.fromMap(Map<String, dynamic> map) {
    return PlaylistSong(
      playlistId: map['playlistId'] as String,
      songId: map['songId'] as String,
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }
}
