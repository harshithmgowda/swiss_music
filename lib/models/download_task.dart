enum DownloadStatus { pending, downloading, completed, failed, cancelled }

class DownloadTask {
  final String id;
  final String videoId;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final String format;
  final int bitrate; // kbps
  final int duration; // seconds
  final int totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final String? errorMessage;
  final bool isVideo;

  const DownloadTask({
    required this.id,
    required this.videoId,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.format,
    required this.bitrate,
    required this.duration,
    required this.totalBytes,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.pending,
    this.errorMessage,
    this.isVideo = false,
  });

  double get progress {
    if (totalBytes <= 0) return 0.0;
    final p = downloadedBytes / totalBytes;
    return p.clamp(0.0, 1.0);
  }

  int get percentageInt => (progress * 100).toInt();

  String get percentageFormatted => '$percentageInt%';

  String get downloadedMbFormatted {
    final mb = downloadedBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get totalMbFormatted {
    final mb = totalBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get progressSummary =>
      'Downloaded:\n$downloadedMbFormatted / $totalMbFormatted';

  DownloadTask copyWith({
    String? id,
    String? videoId,
    String? title,
    String? artist,
    String? thumbnailUrl,
    String? format,
    int? bitrate,
    int? duration,
    int? totalBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    String? errorMessage,
    bool? isVideo,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      format: format ?? this.format,
      bitrate: bitrate ?? this.bitrate,
      duration: duration ?? this.duration,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isVideo: isVideo ?? this.isVideo,
    );
  }
}
