import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/song.dart';
import 'media_service.dart';
import 'storage_service.dart';

class DownloadCancellationException implements Exception {
  final String message;
  DownloadCancellationException([this.message = 'Download was cancelled.']);
  @override
  String toString() => message;
}

class DownloadService {
  static final DownloadService instance = DownloadService._internal();
  DownloadService._internal();

  final Map<String, bool> _cancellationMap = {};

  void cancelDownload(String taskId) {
    _cancellationMap[taskId] = true;
  }

  bool isCancelled(String taskId) {
    return _cancellationMap[taskId] == true;
  }

  /// Downloads audio or video from YouTube with resilient resuming and multi-client fallback.
  Future<Song> startDownload({
    required String taskId,
    required Video video,
    required MediaStreamOption streamOption,
    required void Function(int downloadedBytes, int totalBytes) onProgress,
  }) async {
    _cancellationMap[taskId] = false;

    final targetDir = streamOption.isVideo
        ? await StorageService.instance.getVideoDirectory()
        : await StorageService.instance.getMusicDirectory();
    final thumbDir = await StorageService.instance.getThumbnailDirectory();

    final isVideo = streamOption.isVideo;
    final successfulExt = isVideo
        ? 'mp4'
        : (streamOption.streamInfo.container.name.toLowerCase() == 'mp4'
            ? 'm4a'
            : streamOption.streamInfo.container.name.toLowerCase());

    final tempFileName = '${video.id.value}_$taskId.tmp';
    final tempFile = File(p.join(targetDir.path, tempFileName));

    try {
      debugPrint('[DL] Starting download for ${video.title} (isVideo=$isVideo, quality=${streamOption.qualityLabel})...');

      // Attempt resilient download of the chosen stream with auto-resume
      bool success = await _downloadWithResume(
        initialStreamInfo: streamOption.streamInfo,
        tempFile: tempFile,
        taskId: taskId,
        videoId: video.id.value,
        totalBytes: streamOption.totalBytes,
        onProgress: onProgress,
      );

      // If chosen stream failed permanently, try alternative streams as fallback
      if (!success && !isCancelled(taskId)) {
        debugPrint('[DL] Chosen stream failed after retries. Attempting fallback client streams...');
        final fallbackManifest = await MediaService.instance.getStreamManifest(video.id.value);
        
        final fallbackCandidates = isVideo
            ? fallbackManifest.muxed.sortByVideoQuality().reversed.toList()
            : fallbackManifest.audioOnly.sortByBitrate().reversed.toList();

        for (final candidate in fallbackCandidates) {
          if (isCancelled(taskId)) {
            throw DownloadCancellationException('Download cancelled by user.');
          }
          if (candidate.tag == streamOption.streamInfo.tag) continue; // Already tried

          debugPrint('[DL] Trying fallback stream tag=${candidate.tag}...');
          // Clean temp file for a new format candidate
          if (await tempFile.exists()) {
            await tempFile.delete();
          }

          success = await _downloadWithResume(
            initialStreamInfo: candidate,
            tempFile: tempFile,
            taskId: taskId,
            videoId: video.id.value,
            totalBytes: candidate.size.totalBytes,
            onProgress: onProgress,
          );

          if (success) break;
        }
      }

      if (isCancelled(taskId)) {
        throw DownloadCancellationException('Download cancelled by user.');
      }

      if (!success) {
        throw Exception(
          'Download failed: YouTube restricted stream delivery for this media. '
          'Please try a different quality or stream.',
        );
      }

      // Download thumbnail
      final thumbFile = File(p.join(thumbDir.path, '${video.id.value}.jpg'));
      String localThumbPath = '';
      try {
        final res = await http
            .get(Uri.parse(video.thumbnails.mediumResUrl))
            .timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          await thumbFile.writeAsBytes(res.bodyBytes);
          localThumbPath = thumbFile.path;
        }
      } catch (_) {}

      // Finalize file
      final bitrate = streamOption.bitrate;
      final qualityTag = isVideo
          ? streamOption.qualityLabel.replaceAll(' ', '_')
          : '${bitrate}k';
      final finalFileName = '${video.id.value}_$qualityTag.$successfulExt';
      final finalFile = File(p.join(targetDir.path, finalFileName));

      if (await finalFile.exists()) await finalFile.delete();
      await tempFile.rename(finalFile.path);

      final actualSize = await finalFile.length();
      debugPrint('[DL] ✓ Download complete: $actualSize bytes → ${finalFile.path}');

      final song = Song(
        id: video.id.value,
        title: video.title,
        artist: video.author,
        duration: video.duration?.inSeconds ?? 0,
        filePath: finalFile.path,
        fileSize: actualSize,
        format: isVideo
            ? 'MP4 VIDEO (${streamOption.qualityLabel})'
            : successfulExt.toUpperCase(),
        bitrate: bitrate,
        thumbnailPath: localThumbPath,
        downloadDate: DateTime.now().toIso8601String(),
      );

      await StorageService.instance.insertSong(song);
      return song;
    } catch (e) {
      if (await tempFile.exists()) {
        try { await tempFile.delete(); } catch (_) {}
      }
      rethrow;
    } finally {
      _cancellationMap.remove(taskId);
    }
  }

  /// Downloads stream with open-ended HTTP range requests and resilient resume.
  /// If the connection drops or stalls, it NEVER resets to 0%; it appends to the
  /// existing file and sends Range: bytes=$downloadedBytes- to continue smoothly.
  Future<bool> _downloadWithResume({
    required StreamInfo initialStreamInfo,
    required File tempFile,
    required String taskId,
    required String videoId,
    required int totalBytes,
    required void Function(int downloadedBytes, int totalBytes) onProgress,
  }) async {
    int downloadedBytes = 0;
    if (await tempFile.exists()) {
      downloadedBytes = await tempFile.length();
    }

    Uri currentUrl = initialStreamInfo.url;
    int retryCount = 0;
    const maxRetries = 6;
    const userAgent =
        'com.google.ios.youtube/20.10.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)';

    while (downloadedBytes < totalBytes || totalBytes <= 0) {
      if (isCancelled(taskId)) {
        throw DownloadCancellationException('Download cancelled by user.');
      }

      final client = http.Client();
      IOSink? sink;

      try {
        sink = tempFile.openWrite(mode: FileMode.append);

        final req = http.Request('GET', currentUrl);
        if (downloadedBytes > 0) {
          req.headers['Range'] = 'bytes=$downloadedBytes-';
        }
        req.headers['User-Agent'] = userAgent;

        final streamedResponse =
            await client.send(req).timeout(const Duration(seconds: 15));

        if (streamedResponse.statusCode != 200 &&
            streamedResponse.statusCode != 206) {
          debugPrint(
            '[DL] HTTP ${streamedResponse.statusCode} at $downloadedBytes bytes',
          );
          await sink.flush();
          await sink.close();
          sink = null;
          client.close();

          // If URL expired (403/410), refresh manifest URL and continue from current byte
          if (streamedResponse.statusCode == 403 ||
              streamedResponse.statusCode == 410) {
            debugPrint('[DL] Stream URL expired. Refreshing manifest...');
            try {
              final freshManifest =
                  await MediaService.instance.getStreamManifest(videoId);
              final matchingStream = freshManifest.streams.firstWhere(
                (s) => s.tag == initialStreamInfo.tag,
                orElse: () => initialStreamInfo,
              );
              currentUrl = matchingStream.url;
            } catch (err) {
              debugPrint('[DL] Manifest refresh error: $err');
            }
          }

          retryCount++;
          if (retryCount > maxRetries) {
            return false;
          }
          await Future.delayed(Duration(milliseconds: 600 * retryCount));
          continue;
        }

        int bytesReceivedInConnection = 0;
        await for (final chunk in streamedResponse.stream) {
          if (isCancelled(taskId)) {
            throw DownloadCancellationException('Download cancelled by user.');
          }

          sink.add(chunk);
          downloadedBytes += chunk.length;
          bytesReceivedInConnection += chunk.length;
          onProgress(downloadedBytes, totalBytes);
        }

        await sink.flush();
        await sink.close();
        sink = null;
        client.close();

        // Check if finished
        if (totalBytes > 0 &&
            downloadedBytes >= (totalBytes * 0.98).toInt()) {
          debugPrint('[DL] ✓ Stream download reached total size: $downloadedBytes / $totalBytes');
          break;
        }

        if (totalBytes <= 0 && bytesReceivedInConnection > 0) {
          break;
        }

        // Connection closed before reaching total size; wait and resume from current downloadedBytes
        retryCount++;
        if (retryCount > maxRetries) {
          debugPrint('[DL] Exceeded max retries ($maxRetries). Downloaded: $downloadedBytes / $totalBytes');
          break;
        }
        debugPrint('[DL] Connection ended at $downloadedBytes / $totalBytes. Resuming (retry $retryCount)...');
        await Future.delayed(const Duration(milliseconds: 500));
      } on DownloadCancellationException {
        if (sink != null) {
          try { await sink.flush(); } catch (_) {}
          try { await sink.close(); } catch (_) {}
        }
        client.close();
        rethrow;
      } catch (e) {
        debugPrint('[DL] Stream read error: $e at $downloadedBytes bytes');
        if (sink != null) {
          try { await sink.flush(); } catch (_) {}
          try { await sink.close(); } catch (_) {}
          sink = null;
        }
        client.close();

        retryCount++;
        if (retryCount > maxRetries) {
          break;
        }
        await Future.delayed(Duration(milliseconds: 800 * retryCount));
      }
    }

    final finalLength = await tempFile.length();
    final isComplete = finalLength > 50 * 1024 &&
        (totalBytes <= 0 || finalLength >= (totalBytes * 0.90).toInt());
    return isComplete;
  }
}
