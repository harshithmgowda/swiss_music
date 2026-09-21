import 'package:flutter_test/flutter_test.dart';
import 'package:swiss_music/models/download_task.dart';
import 'package:swiss_music/models/playlist.dart';
import 'package:swiss_music/models/song.dart';
import 'package:swiss_music/services/media_service.dart';

void main() {
  group('Swiss Music Unit Tests', () {
    test('Song model serialization and formatting', () {
      final song = Song(
        id: 'test_123',
        title: 'Swiss Symphony',
        artist: 'Helvetic Orchestra',
        duration: 222, // 3 mins 42 secs
        filePath: '/data/music/test_123_128k.m4a',
        fileSize: 10485760, // 10.0 MB
        format: 'M4A',
        bitrate: 128,
        thumbnailPath: '/data/thumbnails/test_123.jpg',
        downloadDate: '2026-09-20T12:00:00.000Z',
      );

      expect(song.durationFormatted, '03:42');
      expect(song.fileSizeFormatted, '10.0 MB');

      final map = song.toMap();
      expect(map['id'], 'test_123');
      expect(map['title'], 'Swiss Symphony');

      final reconstructed = Song.fromMap(map);
      expect(reconstructed.id, song.id);
      expect(reconstructed.title, song.title);
      expect(reconstructed.duration, song.duration);
    });

    test('Playlist total duration and count calculations', () {
      final song1 = Song(
        id: 's1',
        title: 'Track 1',
        artist: 'Artist 1',
        duration: 60,
        filePath: '/p1',
        fileSize: 1000,
        format: 'M4A',
        bitrate: 128,
        thumbnailPath: '',
        downloadDate: '',
      );

      final song2 = Song(
        id: 's2',
        title: 'Track 2',
        artist: 'Artist 2',
        duration: 120,
        filePath: '/p2',
        fileSize: 2000,
        format: 'M4A',
        bitrate: 128,
        thumbnailPath: '',
        downloadDate: '',
      );

      final playlist = Playlist(
        id: 'pl_1',
        name: 'Focus Sounds',
        createdAt: '2026-09-20',
        songs: [song1, song2],
      );

      expect(playlist.songCount, 2);
      expect(playlist.totalDurationSeconds, 180);
      expect(playlist.totalDurationFormatted, '03:00');
    });

    test('MediaService parses diverse YouTube URL formats', () {
      final mediaService = MediaService.instance;

      // Standard watch URL
      expect(
        mediaService.parseVideoId(
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        'dQw4w9WgXcQ',
      );

      // Short URL
      expect(
        mediaService.parseVideoId('https://youtu.be/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );

      // YouTube Shorts URL
      expect(
        mediaService.parseVideoId('https://www.youtube.com/shorts/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );

      // Direct Video ID
      expect(mediaService.parseVideoId('dQw4w9WgXcQ'), 'dQw4w9WgXcQ');

      // Invalid input
      expect(mediaService.parseVideoId('not_a_valid_url_at_all'), null);
    });

    test('DownloadTask progress and percentage calculation', () {
      const task = DownloadTask(
        id: 'task_1',
        videoId: 'v123',
        title: 'Test Download',
        artist: 'Artist',
        thumbnailUrl: '',
        format: 'M4A',
        bitrate: 128,
        duration: 180,
        totalBytes: 10000000,
        downloadedBytes: 8200000,
        status: DownloadStatus.downloading,
      );

      expect(task.percentageInt, 82);
      expect(task.percentageFormatted, '82%');
      expect(task.progress, closeTo(0.82, 0.01));
    });
  });
}
