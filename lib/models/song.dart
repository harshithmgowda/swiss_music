import 'dart:io';

class Song {
  final String id;
  final String title;
  final String artist;
  final int duration; // in seconds
  final String filePath;
  final int fileSize; // in bytes
  final String format;
  final int bitrate; // in kbps
  final String thumbnailPath;
  final String downloadDate;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.filePath,
    required this.fileSize,
    required this.format,
    required this.bitrate,
    required this.thumbnailPath,
    required this.downloadDate,
  });

  bool get fileExists => File(filePath).existsSync();
  bool get thumbnailExists => File(thumbnailPath).existsSync();
  bool get isVideo =>
      format.toUpperCase().contains('VIDEO') ||
      filePath.toLowerCase().endsWith('.mp4');

  String get durationFormatted {
    final minutes = (duration ~/ 60).toString().padLeft(2, '0');
    final seconds = (duration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get fileSizeFormatted {
    final mb = fileSize / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'duration': duration,
      'filePath': filePath,
      'fileSize': fileSize,
      'format': format,
      'bitrate': bitrate,
      'thumbnailPath': thumbnailPath,
      'downloadDate': downloadDate,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Unknown Title',
      artist: map['artist'] as String? ?? 'Unknown Artist',
      duration: map['duration'] as int? ?? 0,
      filePath: map['filePath'] as String? ?? '',
      fileSize: map['fileSize'] as int? ?? 0,
      format: map['format'] as String? ?? 'AUDIO',
      bitrate: map['bitrate'] as int? ?? 128,
      thumbnailPath: map['thumbnailPath'] as String? ?? '',
      downloadDate: map['downloadDate'] as String? ?? '',
    );
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    int? duration,
    String? filePath,
    int? fileSize,
    String? format,
    int? bitrate,
    String? thumbnailPath,
    String? downloadDate,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      format: format ?? this.format,
      bitrate: bitrate ?? this.bitrate,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      downloadDate: downloadDate ?? this.downloadDate,
    );
  }
}
