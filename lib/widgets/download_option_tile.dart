import 'package:flutter/material.dart';

import '../services/media_service.dart';
import '../theme/app_theme.dart';
import 'swiss_button.dart';

class DownloadOptionTile extends StatelessWidget {
  final MediaStreamOption option;
  final VoidCallback onDownload;
  final bool isDownloading;

  const DownloadOptionTile({
    super.key,
    required this.option,
    required this.onDownload,
    this.isDownloading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: AppTheme.solidBorder,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      option.isVideo ? Icons.videocam : Icons.audiotrack,
                      size: 16,
                      color: option.isVideo ? AppTheme.primary : AppTheme.text,
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      color: option.isVideo ? AppTheme.primary : AppTheme.text,
                      child: Text(
                        option.format,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      option.qualityLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Size: ${option.sizeFormatted}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.secondary,
                      ),
                    ),
                    if (option.videoResolution != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• ${option.videoResolution}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SwissButton(
            label: 'DOWNLOAD',
            onPressed: isDownloading ? null : onDownload,
            isLoading: isDownloading,
            style: SwissButtonStyle.primary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ],
      ),
    );
  }
}
