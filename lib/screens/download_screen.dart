import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/download_task.dart';
import '../models/song.dart';
import '../providers/download_provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../services/media_service.dart';
import '../theme/app_theme.dart';
import '../widgets/real_progress_bar.dart';
import '../widgets/swiss_button.dart';

class DownloadScreen extends StatefulWidget {
  final Video video;
  final MediaStreamOption streamOption;

  const DownloadScreen({
    super.key,
    required this.video,
    required this.streamOption,
  });

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  String? _taskId;
  Song? _completedSong;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDownload();
    });
  }

  void _startDownload() {
    final downloadProvider = context.read<DownloadProvider>();
    final libraryProvider = context.read<LibraryProvider>();

    downloadProvider
        .startDownload(
          video: widget.video,
          streamOption: widget.streamOption,
          onComplete: (song) {
            if (mounted) {
              setState(() {
                _completedSong = song;
              });
              libraryProvider.addDownloadedSong(song);
            }
          },
        )
        .then((song) {
          if (mounted && song != null) {
            setState(() {
              _completedSong = song;
            });
          }
        });

    // Find latest active task for this video
    final active = downloadProvider.activeTasks;
    if (active.isNotEmpty) {
      setState(() {
        _taskId = active.last.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();

    // Retrieve active task
    DownloadTask? task;
    if (_taskId != null) {
      task = downloadProvider.getTask(_taskId!);
    }
    task ??= downloadProvider.allTasks.isNotEmpty
        ? downloadProvider.allTasks.last
        : null;

    final status = task?.status ?? DownloadStatus.pending;
    final isDownloading = status == DownloadStatus.downloading;
    final isCompleted =
        status == DownloadStatus.completed || _completedSong != null;
    final isFailed = status == DownloadStatus.failed;
    final isCancelled = status == DownloadStatus.cancelled;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 16,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Text(
              '04',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(width: 8),
            Text('/', style: TextStyle(fontSize: 12, color: AppTheme.border)),
            SizedBox(width: 8),
            Text(
              'REAL DOWNLOAD',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: AppTheme.text,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // State badge
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  color: isCompleted
                      ? AppTheme.primary
                      : isFailed || isCancelled
                      ? AppTheme.text
                      : AppTheme.badgeBg,
                  child: Text(
                    isCompleted
                        ? 'COMPLETED'
                        : isDownloading
                        ? 'DOWNLOADING'
                        : isCancelled
                        ? 'CANCELLED'
                        : isFailed
                        ? 'FAILED'
                        : 'INITIALIZING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: isCompleted || isFailed || isCancelled
                          ? Colors.white
                          : AppTheme.text,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Title and author
              Text(
                widget.video.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.text,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.video.author.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppTheme.secondary,
                ),
              ),

              const SizedBox(height: 28),

              // Stream Specs Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: AppTheme.solidBorder,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSpecCol('FORMAT', widget.streamOption.format),
                    Container(width: 1, height: 32, color: AppTheme.border),
                    _buildSpecCol(
                      widget.streamOption.isVideo ? 'QUALITY' : 'BITRATE',
                      widget.streamOption.qualityLabel,
                    ),
                    Container(width: 1, height: 32, color: AppTheme.border),
                    _buildSpecCol('TOTAL', widget.streamOption.sizeFormatted),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Real Progress Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: AppTheme.darkBorder,
                ),
                child: RealProgressBar(
                  progress: task?.progress ?? (isCompleted ? 1.0 : 0.0),
                  downloadedBytes:
                      task?.downloadedBytes ??
                      (isCompleted ? widget.streamOption.totalBytes : 0),
                  totalBytes: widget.streamOption.totalBytes,
                  showAscii: true,
                ),
              ),

              if (isFailed && task?.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border.all(color: AppTheme.primary, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DOWNLOAD FAILED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task!.errorMessage!.replaceFirst('Exception: ', ''),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Actions
              if (isDownloading) ...[
                SwissButton(
                  label: 'CANCEL DOWNLOAD',
                  style: SwissButtonStyle.danger,
                  onPressed: () {
                    if (_taskId != null) {
                      downloadProvider.cancelDownload(_taskId!);
                    }
                  },
                ),
              ] else if (isFailed || isCancelled) ...[
                SwissButton(
                  label: 'RETRY DOWNLOAD',
                  style: SwissButtonStyle.primary,
                  onPressed: _startDownload,
                ),
                const SizedBox(height: 10),
                SwissButton(
                  label: 'CLOSE',
                  style: SwissButtonStyle.outline,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ] else if (isCompleted && _completedSong != null) ...[
                SwissButton(
                  label: widget.streamOption.isVideo ? 'PLAY IN APP' : 'PLAY NOW',
                  icon: Icons.play_arrow,
                  style: SwissButtonStyle.primary,
                  onPressed: () {
                    final player = context.read<PlayerProvider>();
                    final library = context.read<LibraryProvider>();
                    player.playSong(_completedSong!, fullQueue: library.songs);
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 10),
                SwissButton(
                  label: 'VIEW IN LIBRARY',
                  style: SwissButtonStyle.outline,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecCol(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: AppTheme.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppTheme.text,
          ),
        ),
      ],
    );
  }
}
