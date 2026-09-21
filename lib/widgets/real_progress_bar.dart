import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RealProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int downloadedBytes;
  final int totalBytes;
  final bool showAscii;

  const RealProgressBar({
    super.key,
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
    this.showAscii = true,
  });

  String get asciiBar {
    const totalBlocks = 12;
    final filled = (progress * totalBlocks).round().clamp(0, totalBlocks);
    final empty = totalBlocks - filled;
    final bar = '█' * filled + '░' * empty;
    final percentage = (progress * 100).toInt();
    return '$bar  $percentage%';
  }

  String get downloadedMb {
    final mb = downloadedBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get totalMb {
    if (totalBytes <= 0) return '0.0 MB';
    final mb = totalBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showAscii) ...[
          Text(
            asciiBar,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.text,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
        ],
        // Sharp Swiss geometric progress bar
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: AppTheme.solidBorder,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                    color: AppTheme.primary,
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DOWNLOADED:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$downloadedMb / $totalMb',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.text,
                  ),
                ),
              ],
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
