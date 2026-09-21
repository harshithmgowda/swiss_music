import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

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
  String? _errorMessage;
  Video? _video;
  List<MediaStreamOption> _videoOptions = [];

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
        _videoOptions = [];
      });
      return;
    }

    final videoId = MediaService.instance.parseVideoId(input);
    if (videoId == null) {
      setState(() {
        _errorMessage = 'INVALID URL. PLEASE ENTER A VALID YOUTUBE URL';
        _video = null;
        _videoOptions = [];
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _video = null;
      _videoOptions = [];
    });

    try {
      final result = await MediaService.instance.getVideoAndStreams(videoId);

      if (result.videoOptions.isEmpty) {
        setState(() {
          _errorMessage = 'NO DIRECT VIDEO STREAMS AVAILABLE FOR THIS URL';
        });
      } else {
        setState(() {
          _video = result.video;
          _videoOptions = result.videoOptions;
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
                    ],
                  ),
                ),

                // Download Options Section
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DOWNLOAD OPTIONS (MP4 VIDEO)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppTheme.text,
                      ),
                    ),
                    if (_videoOptions.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        color: AppTheme.primary,
                        child: Text(
                          '${_videoOptions.length} QUALITIES',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'SELECT RESOLUTION TO DOWNLOAD (PLAYS SEAMLESSLY AS AUDIO/VIDEO IN APP)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(height: 14),

                // Video stream options list
                if (_videoOptions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      border: AppTheme.solidBorder,
                    ),
                    child: Center(
                      child: Text(
                        'NO DIRECT VIDEO STREAMS FOUND FOR THIS MEDIA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                  )
                else
                  ..._videoOptions.map((opt) {
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
