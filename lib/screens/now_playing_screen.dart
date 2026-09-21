import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import 'url_screen.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  void _showQueueModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final player = context.watch<PlayerProvider>();
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PLAYBACK QUEUE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: AppTheme.text,
                    ),
                  ),
                  Text(
                    '${player.queue.length} TRACKS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1.5),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: player.queue.length,
                  itemBuilder: (context, index) {
                    final song = player.queue[index];
                    final isCurrent = index == player.currentIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isCurrent ? AppTheme.badgeBg : AppTheme.surface,
                        border: isCurrent
                            ? AppTheme.darkBorder
                            : AppTheme.solidBorder,
                      ),
                      child: ListTile(
                        leading: Text(
                          (index + 1).toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            color: isCurrent
                                ? AppTheme.primary
                                : AppTheme.secondary,
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.secondary,
                          ),
                        ),
                        trailing: isCurrent
                            ? const Icon(
                                Icons.volume_up,
                                size: 20,
                                color: AppTheme.primary,
                              )
                            : null,
                        onTap: () {
                          player.playAtIndex(index);
                          Navigator.of(ctx).pop();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;

    if (song == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('NOW PLAYING')),
        body: Center(
          child: Text(
            'NO TRACK LOADED',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppTheme.secondary,
            ),
          ),
        ),
      );
    }

    final isRemoteThumb = song.thumbnailPath.startsWith('http://') ||
        song.thumbnailPath.startsWith('https://');
    final hasThumbnail = isRemoteThumb ||
        (song.thumbnailPath.isNotEmpty &&
            File(song.thumbnailPath).existsSync());

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 16,
        leading: IconButton(
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 30,
            color: AppTheme.text,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Text(
              '05',
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
              'NOW PLAYING',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: AppTheme.text,
              ),
            ),
          ],
        ),
        actions: [
          if (song.isOnline)
            IconButton(
              icon: Icon(Icons.download, color: AppTheme.primary),
              tooltip: 'Download Offline',
              onPressed: () {
                final videoId = song.id.replaceAll('stream_', '');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UrlScreen(initialUrl: videoId),
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.queue_music, color: AppTheme.text),
            tooltip: 'Queue',
            onPressed: () => _showQueueModal(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Large Artwork with sharp 1.5px border
              AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: AppTheme.darkBorder,
                  ),
                  child: isRemoteThumb
                      ? Image.network(
                          song.thumbnailPath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildFallbackArt(),
                        )
                      : hasThumbnail
                      ? Image.file(
                          File(song.thumbnailPath),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildFallbackArt(),
                        )
                      : _buildFallbackArt(),
                ),
              ),

              const SizedBox(height: 24),

              // Track metadata
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: AppTheme.text,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          song.artist.toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          song.isOnline ? AppTheme.primary : AppTheme.badgeBg,
                      border: AppTheme.solidBorder,
                    ),
                    child: Text(
                      song.isOnline ? 'ONLINE STREAM' : 'OFFLINE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: song.isOnline ? Colors.white : AppTheme.text,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Progress Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: AppTheme.primary,
                  inactiveTrackColor: AppTheme.border,
                  thumbColor: AppTheme.primary,
                  overlayColor: AppTheme.primary.withValues(alpha: 0.1),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                  trackShape: const RectangularSliderTrackShape(),
                ),
                child: Slider(
                  value: player.position.inMilliseconds.toDouble().clamp(
                    0.0,
                    player.duration.inMilliseconds.toDouble() > 0
                        ? player.duration.inMilliseconds.toDouble()
                        : 0.0,
                  ),
                  max: player.duration.inMilliseconds.toDouble() > 0
                      ? player.duration.inMilliseconds.toDouble()
                      : 1.0,
                  onChanged: (val) {
                    player.seek(Duration(milliseconds: val.toInt()));
                  },
                ),
              ),

              // Timestamps: 00:42 / 03:42
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      player.positionFormatted,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.text,
                      ),
                    ),
                    Text(
                      player.durationFormatted,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Playback Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Shuffle
                  IconButton(
                    iconSize: 24,
                    icon: Icon(
                      Icons.shuffle,
                      color: player.isShuffle
                          ? AppTheme.primary
                          : AppTheme.secondary,
                    ),
                    tooltip: 'Shuffle',
                    onPressed: () => player.toggleShuffle(),
                  ),

                  // Previous
                  IconButton(
                    iconSize: 36,
                    icon: Icon(Icons.skip_previous, color: AppTheme.text),
                    tooltip: 'Previous',
                    onPressed: () => player.playPrevious(),
                  ),

                  // Play / Pause (Swiss Red #E53935 primary action)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.rectangle, // Zero border radius
                    ),
                    child: IconButton(
                      iconSize: 36,
                      icon: Icon(
                        player.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () => player.togglePlayPause(),
                    ),
                  ),

                  // Next
                  IconButton(
                    iconSize: 36,
                    icon: Icon(Icons.skip_next, color: AppTheme.text),
                    tooltip: 'Next',
                    onPressed: () => player.playNext(),
                  ),

                  // Repeat
                  IconButton(
                    iconSize: 24,
                    icon: Icon(
                      player.loopMode == LoopMode.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                      color: player.loopMode != LoopMode.off
                          ? AppTheme.primary
                          : AppTheme.secondary,
                    ),
                    tooltip: 'Repeat',
                    onPressed: () => player.cycleLoopMode(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Volume slider
              Row(
                children: [
                  Icon(
                    Icons.volume_down,
                    size: 20,
                    color: AppTheme.secondary,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        activeTrackColor: AppTheme.text,
                        inactiveTrackColor: AppTheme.border,
                        thumbColor: AppTheme.text,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ),
                      ),
                      child: Slider(
                        value: player.volume,
                        onChanged: (vol) => player.setVolume(vol),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.volume_up,
                    size: 20,
                    color: AppTheme.secondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackArt() {
    return Container(
      color: AppTheme.badgeBg,
      child: Center(
        child: Icon(Icons.music_note, size: 80, color: AppTheme.secondary),
      ),
    );
  }
}
