import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class MediaStreamOption {
  final StreamInfo streamInfo;
  final String format;
  final String qualityLabel;
  final int bitrate; // in kbps
  final int totalBytes;
  final String sizeFormatted;
  final bool isVideo;
  final String? videoResolution;

  const MediaStreamOption({
    required this.streamInfo,
    required this.format,
    required this.qualityLabel,
    required this.bitrate,
    required this.totalBytes,
    required this.sizeFormatted,
    this.isVideo = false,
    this.videoResolution,
  });
}

// Backward compatibility alias
typedef AudioStreamOption = MediaStreamOption;

class SearchResultItem {
  final String id;
  final String title;
  final String author;
  final Duration? duration;
  final String thumbnailUrl;

  const SearchResultItem({
    required this.id,
    required this.title,
    required this.author,
    required this.duration,
    required this.thumbnailUrl,
  });

  String get durationFormatted {
    if (duration == null) return '--:--';
    final minutes = (duration!.inSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (duration!.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class MediaService {
  static final MediaService instance = MediaService._internal();
  MediaService._internal();

  final YoutubeExplode _yt = YoutubeExplode();

  YoutubeExplode get yt => _yt;

  /// Fast initialization without heavy WebViews
  Future<void> initialize() async {
    // Lightweight no-op for fast performance
  }

  /// Extracts the VideoId from user input (URL or raw ID)
  String? parseVideoId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    try {
      final videoId = VideoId(trimmed);
      return videoId.value;
    } catch (_) {
      // Fallback manual regex for various YouTube URL forms
      final regExp = RegExp(
        r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=|shorts\/|live\/))([a-zA-Z0-9_-]{11})',
      );
      final match = regExp.firstMatch(trimmed);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
      if (trimmed.length == 11 &&
          RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) {
        return trimmed;
      }
      return null;
    }
  }

  final Map<String, Video> _videoCache = {};
  final Map<String, StreamManifest> _manifestCache = {};
  final Map<String, List<MediaStreamOption>> _videoOptionsCache = {};
  final Map<String, List<MediaStreamOption>> _audioOptionsCache = {};

  /// Fetches real metadata for a video with caching
  Future<Video> getVideoMetadata(String videoId) async {
    if (_videoCache.containsKey(videoId)) {
      return _videoCache[videoId]!;
    }
    final video = await _yt.videos.get(VideoId(videoId));
    _videoCache[videoId] = video;
    return video;
  }

  /// Rapidly fetches video metadata and video stream options in parallel.
  Future<({Video video, List<MediaStreamOption> videoOptions})> getVideoAndStreams(
    String videoId,
  ) async {
    final results = await Future.wait([
      getVideoMetadata(videoId),
      getVideoStreams(videoId),
    ]);

    return (
      video: results[0] as Video,
      videoOptions: results[1] as List<MediaStreamOption>,
    );
  }

  /// Rapidly fetches video metadata, audio streams, and video streams in parallel.
  Future<({
    Video video,
    List<MediaStreamOption> audioOptions,
    List<MediaStreamOption> videoOptions,
  })> getVideoAndAllStreams(String videoId) async {
    final results = await Future.wait([
      getVideoMetadata(videoId),
      getAudioStreams(videoId),
      getVideoStreams(videoId),
    ]);

    return (
      video: results[0] as Video,
      audioOptions: results[1] as List<MediaStreamOption>,
      videoOptions: results[2] as List<MediaStreamOption>,
    );
  }

  /// Returns a playable direct audio URL for online playback, preferring highest bitrate audio stream.
  Future<String?> getBestAudioStreamUrl(String videoId) async {
    try {
      final audioOptions = await getAudioStreams(videoId);
      if (audioOptions.isNotEmpty) {
        return audioOptions.first.streamInfo.url.toString();
      }
      final videoOptions = await getVideoStreams(videoId);
      if (videoOptions.isNotEmpty) {
        return videoOptions.first.streamInfo.url.toString();
      }
    } catch (e) {
      debugPrint('[MediaService] Error getting best audio stream url: $e');
    }
    return null;
  }

  /// Fetches real stream manifest trying fastest clients first
  Future<StreamManifest> getStreamManifest(String videoId) async {
    if (_manifestCache.containsKey(videoId)) {
      return _manifestCache[videoId]!;
    }

    StreamManifest? manifest;

    // Try default clients first with a 4s timeout (fastest for muxed MP4 streams)
    try {
      manifest = await _yt.videos.streamsClient
          .getManifest(VideoId(videoId))
          .timeout(const Duration(seconds: 4));
      if (manifest.muxed.isNotEmpty || manifest.audioOnly.isNotEmpty) {
        _manifestCache[videoId] = manifest;
        return manifest;
      }
    } catch (e) {
      debugPrint('[MediaService] Default manifest client attempt note: $e');
    }

    // If default didn't have muxed streams, try android / sdkless clients
    final clientAttempts = <List<YoutubeApiClient>>[
      [YoutubeApiClient.androidSdkless],
      [YoutubeApiClient.android],
      [YoutubeApiClient.ios],
    ];

    for (final clients in clientAttempts) {
      try {
        manifest = await _yt.videos.streamsClient
            .getManifest(VideoId(videoId), ytClients: clients)
            .timeout(const Duration(seconds: 4));

        if (manifest.muxed.isNotEmpty || manifest.audioOnly.isNotEmpty) {
          _manifestCache[videoId] = manifest;
          return manifest;
        }
      } catch (e) {
        debugPrint('[MediaService] Fallback client attempt note: $e');
      }
    }

    final finalManifest =
        await _yt.videos.streamsClient.getManifest(VideoId(videoId));
    _manifestCache[videoId] = finalManifest;
    return finalManifest;
  }

  /// Fetches real available audio streams from the manifest.
  Future<List<MediaStreamOption>> getAudioStreams(String videoId) async {
    if (_audioOptionsCache.containsKey(videoId)) {
      return _audioOptionsCache[videoId]!;
    }

    StreamManifest manifest;
    try {
      manifest = await getStreamManifest(videoId);
    } catch (e) {
      debugPrint('[MediaService] Error getting manifest for audio: $e');
      return [];
    }

    final audioStreams = manifest.audioOnly.sortByBitrate().reversed.toList();
    final List<MediaStreamOption> options = [];
    final Set<String> seenQualities = {};

    for (final stream in audioStreams) {
      final container = stream.container.name.toUpperCase();
      final bitrate = stream.bitrate.kiloBitsPerSecond.round();
      final key = '$container-$bitrate';

      if (!seenQualities.contains(key)) {
        seenQualities.add(key);
        final mb = stream.size.totalBytes / (1024 * 1024);
        options.add(
          MediaStreamOption(
            streamInfo: stream,
            format: container == 'MP4' ? 'M4A AUDIO' : '$container AUDIO',
            qualityLabel: '$bitrate KBPS',
            bitrate: bitrate,
            totalBytes: stream.size.totalBytes,
            sizeFormatted: mb > 0 ? '${mb.toStringAsFixed(1)} MB' : 'Audio',
            isVideo: false,
          ),
        );
      }
    }

    options.sort((a, b) => b.bitrate.compareTo(a.bitrate));
    _audioOptionsCache[videoId] = options;
    return options;
  }

  /// Fetches real available video streams (muxed video+audio MP4s).
  /// Muxed streams are standalone video files containing both video and audio.
  Future<List<MediaStreamOption>> getVideoStreams(String videoId) async {
    if (_videoOptionsCache.containsKey(videoId)) {
      return _videoOptionsCache[videoId]!;
    }

    StreamManifest manifest;
    try {
      manifest = await getStreamManifest(videoId);
    } catch (e) {
      debugPrint('[MediaService] Error getting manifest for video: $e');
      return [];
    }

    final muxedStreams = manifest.muxed.sortByVideoQuality().reversed.toList();
    final List<MediaStreamOption> options = [];
    final Set<String> seenQualities = {};

    for (final stream in muxedStreams) {
      final qualityLabel = stream.qualityLabel.toUpperCase();
      if (!seenQualities.contains(qualityLabel)) {
        seenQualities.add(qualityLabel);
        final mb = stream.size.totalBytes / (1024 * 1024);
        options.add(
          MediaStreamOption(
            streamInfo: stream,
            format: 'MP4 VIDEO',
            qualityLabel: qualityLabel,
            bitrate: stream.bitrate.kiloBitsPerSecond.round(),
            totalBytes: stream.size.totalBytes,
            sizeFormatted: mb > 0 ? '${mb.toStringAsFixed(1)} MB' : 'Video',
            isVideo: true,
            videoResolution:
                '${stream.videoResolution.width}x${stream.videoResolution.height}',
          ),
        );
      }
    }

    _videoOptionsCache[videoId] = options;
    return options;
  }

  /// Searches YouTube and returns real results
  Future<List<SearchResultItem>> searchVideos(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final searchResults = await _yt.search.search(trimmed);
    final List<SearchResultItem> items = [];

    for (final video in searchResults) {
      items.add(
        SearchResultItem(
          id: video.id.value,
          title: video.title,
          author: video.author,
          duration: video.duration,
          thumbnailUrl: video.thumbnails.mediumResUrl,
        ),
      );
    }

    return items;
  }

  void dispose() {
    _yt.close();
  }
}
