import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';
import '../widgets/swiss_button.dart';
import 'search_screen.dart';
import 'url_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onGoToSearch;

  const HomeScreen({super.key, this.onGoToSearch});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final player = context.watch<PlayerProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle / Structural Label
          Row(
            children: [
              Container(width: 8, height: 8, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'OFFLINE AUDIO SYSTEM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppTheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'PERSONAL MUSIC PLAYER',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.1,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 24),

          // Primary and Secondary Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: AppTheme.solidBorder,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'IMPORT AUDIO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(height: 14),
                SwissButton(
                  label: 'PASTE URL',
                  icon: Icons.link,
                  style: SwissButtonStyle.primary,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UrlScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                SwissButton(
                  label: 'SEARCH MEDIA',
                  icon: Icons.search,
                  style: SwissButtonStyle.outline,
                  onPressed:
                      onGoToSearch ??
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SearchScreen(),
                          ),
                        );
                      },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Recently Downloaded Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT MUSIC',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppTheme.text,
                ),
              ),
              if (library.songs.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  color: AppTheme.badgeBg,
                  child: Text(
                    '${library.songs.length} TRACKS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppTheme.text,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (library.isLoading) ...[
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: AppTheme.solidBorder,
              ),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.text),
                ),
              ),
            ),
          ] else if (library.songs.isEmpty) ...[
            // Strictly EMPTY Library state - NO fake songs
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: AppTheme.solidBorder,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    color: AppTheme.badgeBg,
                    child: Text(
                      'STATUS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'LIBRARY EMPTY',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Paste a permitted media URL to add music.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Display verified recent songs
            ...library.songs.take(5).map((song) {
              final isCurrent = player.currentSong?.id == song.id;
              return SongTile(
                song: song,
                isCurrent: isCurrent,
                isPlaying: isCurrent && player.isPlaying,
                onTap: () {
                  player.playSong(song, fullQueue: library.songs);
                },
                onDelete: () {
                  library.deleteSong(song.id);
                },
              );
            }),
          ],
        ],
      ),
    );
  }
}
