import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/playlist.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';
import '../widgets/swiss_button.dart';

class PlaylistScreen extends StatelessWidget {
  final bool isEmbedded;

  const PlaylistScreen({super.key, this.isEmbedded = false});

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'CREATE PLAYLIST',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.0,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(fontWeight: FontWeight.w700),
          decoration: const InputDecoration(hintText: 'Playlist Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<LibraryProvider>().createPlaylist(name);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Create playlist header bar
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LOCAL PLAYLISTS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppTheme.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${library.playlists.length} CREATED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  SwissButton(
                    label: '+ NEW PLAYLIST',
                    style: SwissButtonStyle.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    onPressed: () => _showCreatePlaylistDialog(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1.5),

            Expanded(
              child: library.playlists.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'NO PLAYLISTS',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: AppTheme.text,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Create a playlist to organize your offline songs.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SwissButton(
                              label: 'CREATE PLAYLIST',
                              style: SwissButtonStyle.outline,
                              onPressed: () =>
                                  _showCreatePlaylistDialog(context),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: library.playlists.length,
                      itemBuilder: (context, index) {
                        final pl = library.playlists[index];
                        return _buildPlaylistCard(context, pl);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(BuildContext context, Playlist playlist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: AppTheme.solidBorder,
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlaylistDetailScreen(playlistId: playlist.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                color: AppTheme.badgeBg,
                child: Icon(Icons.queue_music, color: AppTheme.text),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${playlist.songCount} SONGS • ${playlist.totalDurationFormatted}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  void _showAddSongsModal(BuildContext context, Playlist playlist) {
    final library = context.read<LibraryProvider>();
    final availableSongs = library.songs
        .where((s) => !playlist.songs.any((ps) => ps.id == s.id))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADD SONGS TO PLAYLIST',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: availableSongs.isEmpty
                  ? Center(
                      child: Text(
                        'All downloaded songs are already in this playlist.',
                        style: TextStyle(color: AppTheme.secondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: availableSongs.length,
                      itemBuilder: (context, index) {
                        final song = availableSongs[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            border: AppTheme.solidBorder,
                          ),
                          child: ListTile(
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
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.secondary,
                              ),
                            ),
                            trailing: Icon(
                              Icons.add,
                              color: AppTheme.primary,
                            ),
                            onTap: () async {
                              final navigator = Navigator.of(ctx);
                              await library.addSongToPlaylist(
                                playlist.id,
                                song.id,
                              );
                              navigator.pop();
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final player = context.watch<PlayerProvider>();

    final playlist = library.playlists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => Playlist(id: '', name: 'Not Found', createdAt: ''),
    );

    if (playlist.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('PLAYLIST')),
        body: const Center(child: Text('Playlist not found.')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 16,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          playlist.name.toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppTheme.primary),
            tooltip: 'Delete Playlist',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('DELETE PLAYLIST'),
                  content: Text(
                    'Delete "${playlist.name}"? Music files will remain on your device.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('CANCEL'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        library.deletePlaylist(playlist.id);
                        Navigator.of(context).pop();
                      },
                      child: const Text('DELETE'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header stats
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${playlist.songCount} SONGS • ${playlist.totalDurationFormatted}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (playlist.songs.isNotEmpty)
                        SwissButton(
                          label: 'PLAY ALL',
                          icon: Icons.play_arrow,
                          style: SwissButtonStyle.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          onPressed: () {
                            player.playSong(
                              playlist.songs.first,
                              fullQueue: playlist.songs,
                            );
                          },
                        ),
                      const SizedBox(width: 8),
                      SwissButton(
                        label: '+ ADD',
                        style: SwissButtonStyle.outline,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        onPressed: () => _showAddSongsModal(context, playlist),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1.5),

            Expanded(
              child: playlist.songs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'NO SONGS IN PLAYLIST',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.text,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwissButton(
                            label: 'ADD SONGS',
                            style: SwissButtonStyle.primary,
                            onPressed: () =>
                                _showAddSongsModal(context, playlist),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: playlist.songs.length,
                      itemBuilder: (context, index) {
                        final song = playlist.songs[index];
                        final isCurrent = player.currentSong?.id == song.id;

                        return SongTile(
                          song: song,
                          isCurrent: isCurrent,
                          isPlaying: isCurrent && player.isPlaying,
                          onTap: () {
                            player.playSong(song, fullQueue: playlist.songs);
                          },
                          onDelete: () {
                            library.removeSongFromPlaylist(
                              playlist.id,
                              song.id,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
