import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'providers/download_provider.dart';
import 'providers/library_provider.dart';
import 'providers/player_provider.dart';
import 'providers/theme_provider.dart';
import 'services/audio_player_service.dart';
import 'services/media_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI for Desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize Background Audio Service for Mobile
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.swissmusic.player.channel.audio',
        androidNotificationChannelName: 'Swiss Music Playback',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      );
    } catch (e) {
      debugPrint('Background audio service initialization note: $e');
    }

    // Request audio permissions if needed on Android
    if (Platform.isAndroid) {
      try {
        final status = await Permission.audio.status;
        if (status.isDenied) {
          await Permission.audio.request();
        }
      } catch (_) {}
    }
  }

  // Initialize Media Service (WebView JS Challenge Solver for mobile)
  await MediaService.instance.initialize();

  // Initialize Audio Player Service
  AudioPlayerService.instance.init();

  runApp(const SwissMusicApp());
}

class SwissMusicApp extends StatelessWidget {
  const SwissMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()..init()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()..init()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'Swiss Music',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SwissMusicAppShell(),
          );
        },
      ),
    );
  }
}
