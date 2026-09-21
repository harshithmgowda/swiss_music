import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/media_service.dart';
import '../theme/app_theme.dart';
import '../widgets/download_option_tile.dart';
import '../widgets/swiss_button.dart';
import 'download_screen.dart';

class UrlScreen extends StatefulWidget {
  final String? initialUrl;

  const UrlScreen({super.key, this.initialUrl});

  @override
  State<UrlScreen> createState() => _UrlScreenState();
}

class _UrlScreenState extends State<UrlScreen> {
  late final TextEditingController _urlController;
  bool _isAnalyzing = false;
  bool _isStreaming = false;
  String? _errorMessage;
  Video? _video;
  List<MediaStreamOption> _audioOptions = [];
  List<MediaStreamOption> _videoOptions = [];
  bool _isAudioTab = true;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _analyzeUrl();
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _analyzeUrl() async {
    final input = _urlController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'PLEASE ENTER A VALID PERMITTED MEDIA URL';
        _video = null;
        _audioOptions = [];
        _videoOptions = [];
      });
      return;
    }

    final videoId = MediaService.instance.parseVideoId(input);
    if (videoId == null) {
      setState(() {
        _errorMessage = 'INVALID URL. PLEASE ENTER A VALID YOUTUBE URL';
        _video = null;
        _audioOptions = [];
        _videoOptions = [];
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _video = null;
      _audioOptions = [];
      _videoOptions = [];
    });

    try {
      final result =
          await MediaService.instance.getVideoAndAllStreams(videoId);

      if (result.audioOptions.isEmpty && result.videoOptions.isEmpty) {
        setState(() {
          _errorMessage = 'NO DIRECT AUDIO OR VIDEO STREAMS AVAILABLE FOR THIS URL';
        });
      } else {
        setState(() {
          _video = result.video;
          _audioOptions = result.audioOptions;
          _videoOptions = result.videoOptions;
          _isAudioTab = result.audioOptions.isNotEmpty;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'UNABLE TO ANALYZE URL: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _streamOnline() async {
    if (_video == null) return;
    setState(() => _isStreaming = true);
    try {
      final streamUrl =
          await MediaService.instance.getBestAudioStreamUrl(_video!.id.value);
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
        id: 'stream_${_video!.id.value}',
        title: _video!.title,
        artist: _video!.author,
        duration: _video!.duration?.inSeconds ?? 0,
        filePath: streamUrl,
        fileSize:
            _audioOptions.isNotEmpty ? _audioOptions.first.totalBytes : 0,
        format: 'ONLINE STREAM',
        bitrate: _audioOptions.isNotEmpty ? _audioOptions.first.bitrate : 128,
        thumbnailPath: _video!.thumbnails.highResUrl,
        downloadDate: 'STREAM',
      );

      if (mounted) {
        context.read<PlayerProvider>().playSong(onlineSong);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playing "${_video!.title}" online'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stream audio: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStreaming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 16,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Text(
              '02',
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
              'PASTE URL',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Label
              Text(
                'PASTE VIDEO URL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 10),

              // Input Field
              TextField(
                controller: _urlController,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.text,
                ),
                decoration: InputDecoration(
                  hintText: 'Paste a YouTube URL...',
                  suffixIcon: _urlController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _urlController.clear();
                            setState(() {
                              _video = null;
                              _videoOptions = [];
                              _errorMessage = null;
                            });
                          },
                        )
                      : null,
                ),
                onSubmitted: (_) => _analyzeUrl(),
              ),
              const SizedBox(height: 12),

              // Analyze Button
              SwissButton(
                label: 'ANALYZE',
                icon: Icons.search,
                isLoading: _isAnalyzing,
                style: SwissButtonStyle.primary,
                onPressed: _analyzeUrl,
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border.all(color: AppTheme.primary, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(
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
              ],

              // Video Metadata Preview
              if (_video != null) ...[
                const SizedBox(height: 28),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: AppTheme.solidBorder,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        color: AppTheme.badgeBg,
                        child: Text(
                          'MEDIA METADATA',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Thumbnail
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          decoration: BoxDecoration(
                            border: AppTheme.solidBorder,
                            color: AppTheme.background,
                          ),
                          child: Image.network(
                            _video!.thumbnails.highResUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        _video!.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.text,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Channel / Artist
                      Text(
                        _video!.author.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppTheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Duration & ID
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: AppTheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(_video!.duration),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              color: AppTheme.text,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'ID: ${_video!.id.value}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Online Streaming Action
                      SwissButton(
                        label: 'STREAM ONLINE (PLAY NOW)',
                        icon: Icons.play_arrow,
                        isLoading: _isStreaming,
                        style: SwissButtonStyle.primary,
                        onPressed: _streamOnline,
                      ),
                    ],
                  ),
                ),

                // Download Options Section
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DOWNLOAD FORMAT',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppTheme.text,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      color: AppTheme.badgeBg,
                      child: Text(
                        '${_isAudioTab ? _audioOptions.length : _videoOptions.length} OPTIONS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: AppTheme.text,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Swiss Tab Selector (Audio vs Video)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isAudioTab = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                _isAudioTab ? AppTheme.text : AppTheme.surface,
                            border: AppTheme.solidBorder,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.audiotrack,
                                size: 16,
                                color: _isAudioTab
                                    ? AppTheme.background
                                    : AppTheme.text,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AUDIO (M4A) [${_audioOptions.length}]',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: _isAudioTab
                                      ? AppTheme.background
                                      : AppTheme.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isAudioTab = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                !_isAudioTab ? AppTheme.text : AppTheme.surface,
                            border: AppTheme.solidBorder,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam,
                                size: 16,
                                color: !_isAudioTab
                                    ? AppTheme.background
                                    : AppTheme.text,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'VIDEO (MP4) [${_videoOptions.length}]',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: !_isAudioTab
                                      ? AppTheme.background
                                      : AppTheme.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _isAudioTab
                      ? 'SELECT AUDIO BITRATE TO SAVE AS OFFLINE MUSIC'
                      : 'SELECT VIDEO RESOLUTION TO DOWNLOAD (MP4)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(height: 14),

                // Active options list
                if ((_isAudioTab ? _audioOptions : _videoOptions).isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      border: AppTheme.solidBorder,
                    ),
                    child: Center(
                      child: Text(
                        _isAudioTab
                            ? 'NO AUDIO STREAMS FOUND FOR THIS MEDIA'
                            : 'NO DIRECT VIDEO STREAMS FOUND FOR THIS MEDIA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                  )
                else
                  ...(_isAudioTab ? _audioOptions : _videoOptions).map((opt) {
                    return DownloadOptionTile(
                      option: opt,
                      onDownload: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DownloadScreen(
                              video: _video!,
                              streamOption: opt,
                            ),
                          ),
                        );
                      },
                    );
                  }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '--:--';
    final minutes = (d.inSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
