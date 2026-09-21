import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';
import '../widgets/swiss_button.dart';
import 'playlist_screen.dart';
import 'url_screen.dart';

class LibraryScreen extends StatefulWidget {
  final VoidCallback? onSwitchToPlaylistsTab;

  const LibraryScreen({super.key, this.onSwitchToPlaylistsTab});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddToPlaylistDialog(Song song) {
    final library = context.read<LibraryProvider>();
    final playlists = library.playlists;

    if (playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'NO PLAYLISTS AVAILABLE. CREATE ONE FIRST IN PLAYLISTS TAB.',
          ),
          backgroundColor: AppTheme.text,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'ADD TO PLAYLIST',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.0,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final pl = playlists[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(border: AppTheme.solidBorder),
                child: ListTile(
                  title: Text(
                    pl.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    '${pl.songCount} SONGS',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.secondary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.add,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.of(ctx).pop();
                    await library.addSongToPlaylist(pl.id, song.id);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('ADDED "${song.title}" TO "${pl.name}"'),
                        backgroundColor: AppTheme.text,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final player = context.watch<PlayerProvider>();

    return Column(
      children: [
        // Rectangular Tab Bar
        Container(
          color: AppTheme.surface,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: AppTheme.text,
            unselectedLabelColor: AppTheme.secondary,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
            tabs: const [
              Tab(text: '01 SONGS'),
              Tab(text: '02 DOWNLOADS'),
              Tab(text: '03 PLAYLISTS'),
            ],
          ),
        ),

        const Divider(height: 1.5),

        Expanded(
          child: library.isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.text),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: SONGS
                    _buildSongList(library, player),
                    // Tab 2: DOWNLOADS (ordered by date)
                    _buildSongList(library, player, isDownloadsTab: true),
                    // Tab 3: PLAYLISTS
                    const PlaylistScreen(isEmbedded: true),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSongList(
    LibraryProvider library,
    PlayerProvider player, {
    bool isDownloadsTab = false,
  }) {
    if (library.songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: AppTheme.badgeBg,
                child: Text(
                  'STATUS: ZERO FILES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppTheme.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'NO MUSIC',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your downloaded music will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.secondary),
              ),
              const SizedBox(height: 24),
              SwissButton(
                label: 'PASTE URL TO DOWNLOAD',
                icon: Icons.link,
                style: SwissButtonStyle.primary,
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const UrlScreen()));
                },
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => library.refresh(),
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: library.songs.length,
        itemBuilder: (context, index) {
          final song = library.songs[index];
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
            onAddToPlaylist: () => _showAddToPlaylistDialog(song),
          );
        },
      ),
    );
  }
}
