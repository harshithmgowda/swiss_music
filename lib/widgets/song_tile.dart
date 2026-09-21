import 'dart:io';

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../theme/app_theme.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onAddToPlaylist;

  const SongTile({
    super.key,
    required this.song,
    this.isCurrent = false,
    this.isPlaying = false,
    required this.onTap,
    required this.onDelete,
    this.onAddToPlaylist,
  });

  Widget _buildArtwork() {
    final hasThumbnail =
        song.thumbnailPath.isNotEmpty && File(song.thumbnailPath).existsSync();

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: AppTheme.solidBorder,
      ),
      child: hasThumbnail
          ? Image.file(
              File(song.thumbnailPath),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildFallbackArt(),
            )
          : _buildFallbackArt(),
    );
  }

  Widget _buildFallbackArt() {
    return Container(
      color: AppTheme.badgeBg,
      child: Center(
        child: Icon(
          song.isVideo ? Icons.videocam_outlined : Icons.music_note,
          size: 24,
          color: song.isVideo ? AppTheme.primary : AppTheme.secondary,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'DELETE MUSIC',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${song.title}" from your device? This permanently deletes the local audio file and its metadata.',
          style: TextStyle(
            color: AppTheme.text,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete();
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrent ? AppTheme.badgeBg : AppTheme.surface,
        border: isCurrent ? AppTheme.darkBorder : AppTheme.solidBorder,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildArtwork(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isCurrent) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 6),
                            color: AppTheme.primary,
                            child: Text(
                              isPlaying ? 'PLAYING' : 'PAUSED',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.secondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          song.durationFormatted,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: AppTheme.text,
                          ),
                        ),
                        if (song.isVideo)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            color: AppTheme.primary,
                            child: const Text(
                              'VIDEO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        Text(
                          '• ${_formatQualityLabel(song)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.badgeBg,
                            border: Border.all(
                              color: AppTheme.border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'OFFLINE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppTheme.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              if (onAddToPlaylist != null)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.playlist_add, size: 20),
                  color: AppTheme.secondary,
                  tooltip: 'Add to Playlist',
                  onPressed: onAddToPlaylist,
                ),
              const SizedBox(width: 4),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppTheme.primary,
                tooltip: 'Delete Music',
                onPressed: () => _showDeleteConfirmation(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatQualityLabel(Song song) {
    final format = song.format;
    // Extract resolution if format is e.g. "MP4 VIDEO (720P)"
    if (format.contains('(') && format.contains(')')) {
      final start = format.indexOf('(') + 1;
      final end = format.indexOf(')');
      final qual = format.substring(start, end).trim();
      return '$qual MP4';
    }
    if (format.toUpperCase().contains('VIDEO')) {
      return 'MP4';
    }
    return '${format.replaceAll('AUDIO', '').trim()} ${song.bitrate}K';
  }
}
