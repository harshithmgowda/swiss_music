import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/media_service.dart';
import '../theme/app_theme.dart';
import '../widgets/swiss_button.dart';
import 'url_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchResultItem> _results = [];
  bool _isSearching = false;
  String? _streamingItemId;
  String? _errorMessage;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final items = await MediaService.instance.searchVideos(query);
      setState(() {
        _results = items;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Search failed: $e';
        _results = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _streamItem(SearchResultItem item) async {
    setState(() => _streamingItemId = item.id);
    try {
      final streamUrl =
          await MediaService.instance.getBestAudioStreamUrl(item.id);
      if (streamUrl == null || streamUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not obtain online audio stream.'),
            ),
          );
        }
        return;
      }

      final onlineSong = Song(
        id: 'stream_${item.id}',
        title: item.title,
        artist: item.author,
        duration: item.duration?.inSeconds ?? 0,
        filePath: streamUrl,
        fileSize: 0,
        format: 'ONLINE STREAM',
        bitrate: 128,
        thumbnailPath: item.thumbnailUrl,
        downloadDate: 'STREAM',
      );

      if (mounted) {
        context.read<PlayerProvider>().playSong(onlineSong);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playing "${item.title}" online'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stream failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _streamingItemId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.surface,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search permitted media...',
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: AppTheme.secondary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _results = [];
                                _hasSearched = false;
                              });
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              const SizedBox(width: 10),
              SwissButton(
                label: 'SEARCH',
                isLoading: _isSearching,
                style: SwissButtonStyle.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                onPressed: _performSearch,
              ),
            ],
          ),
        ),

        const Divider(height: 1.5),

        // Error message
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.primary, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Results list or empty state
        Expanded(
          child: _isSearching
              ? Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.text),
                  ),
                )
              : !_hasSearched
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        color: AppTheme.badgeBg,
                        child: Text(
                          'SEARCH ENGINE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'SEARCH FOR PERMITTED CONTENT',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppTheme.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Query YouTube for music you are permitted to download.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                )
              : _results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NO RESULTS FOUND',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'No matching content found for "${_searchController.text}".',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    return _buildSearchResultTile(context, item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchResultTile(BuildContext context, SearchResultItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: AppTheme.solidBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              width: 80,
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.background,
                border: AppTheme.solidBorder,
              ),
              child: Image.network(
                item.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 20,
                    color: AppTheme.secondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.text,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.author.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.durationFormatted,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      color: AppTheme.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwissButton(
                  label: 'STREAM',
                  icon: Icons.play_arrow,
                  isLoading: _streamingItemId == item.id,
                  style: SwissButtonStyle.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  onPressed: () => _streamItem(item),
                ),
                const SizedBox(height: 6),
                SwissButton(
                  label: 'DOWNLOAD',
                  icon: Icons.download,
                  style: SwissButtonStyle.outline,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => UrlScreen(initialUrl: item.id),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
