import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/download_task.dart';
import '../models/song.dart';
import '../services/download_service.dart';
import '../services/media_service.dart';

class DownloadProvider extends ChangeNotifier {
  final DownloadService _downloadService = DownloadService.instance;

  final Map<String, DownloadTask> _tasks = {};

  List<DownloadTask> get activeTasks => _tasks.values
      .where((t) => t.status == DownloadStatus.downloading)
      .toList();

  List<DownloadTask> get allTasks => _tasks.values.toList();

  DownloadTask? getTask(String id) => _tasks[id];

  Future<Song?> startDownload({
    required Video video,
    required MediaStreamOption streamOption,
    required void Function(Song song) onComplete,
  }) async {
    final taskId = '${video.id.value}_${DateTime.now().millisecondsSinceEpoch}';

    final initialTask = DownloadTask(
      id: taskId,
      videoId: video.id.value,
      title: video.title,
      artist: video.author,
      thumbnailUrl: video.thumbnails.mediumResUrl,
      format: streamOption.format,
      bitrate: streamOption.bitrate,
      duration: video.duration?.inSeconds ?? 0,
      totalBytes: streamOption.totalBytes,
      downloadedBytes: 0,
      status: DownloadStatus.downloading,
      isVideo: streamOption.isVideo,
    );

    _tasks[taskId] = initialTask;
    notifyListeners();

    try {
      final song = await _downloadService.startDownload(
        taskId: taskId,
        video: video,
        streamOption: streamOption,
        onProgress: (downloaded, total) {
          final current = _tasks[taskId];
          if (current != null) {
            _tasks[taskId] = current.copyWith(
              downloadedBytes: downloaded,
              totalBytes: total > 0 ? total : current.totalBytes,
              status: DownloadStatus.downloading,
            );
            notifyListeners();
          }
        },
      );

      final completedTask = _tasks[taskId];
      if (completedTask != null) {
        _tasks[taskId] = completedTask.copyWith(
          status: DownloadStatus.completed,
          downloadedBytes: completedTask.totalBytes,
        );
        notifyListeners();
      }

      onComplete(song);
      return song;
    } catch (e) {
      final failedTask = _tasks[taskId];
      if (failedTask != null) {
        final isCancel =
            e is DownloadCancellationException ||
            _downloadService.isCancelled(taskId);
        _tasks[taskId] = failedTask.copyWith(
          status: isCancel ? DownloadStatus.cancelled : DownloadStatus.failed,
          errorMessage: e.toString(),
        );
        notifyListeners();
      }
      return null;
    }
  }

  void cancelDownload(String taskId) {
    _downloadService.cancelDownload(taskId);
    final task = _tasks[taskId];
    if (task != null) {
      _tasks[taskId] = task.copyWith(
        status: DownloadStatus.cancelled,
        errorMessage: 'Download cancelled by user.',
      );
      notifyListeners();
    }
  }

  void clearCompletedTask(String taskId) {
    _tasks.remove(taskId);
    notifyListeners();
  }
}
