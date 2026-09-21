import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/playlist_screen.dart';
import 'screens/search_screen.dart';
import 'widgets/swiss_scaffold.dart';

class SwissMusicAppShell extends StatefulWidget {
  const SwissMusicAppShell({super.key});

  @override
  State<SwissMusicAppShell> createState() => _SwissMusicAppShellState();
}

class _SwissMusicAppShellState extends State<SwissMusicAppShell> {
  int _currentIndex = 0;

  final List<Map<String, String>> _tabMetadata = const [
    {'num': '01', 'title': 'HOME'},
    {'num': '02', 'title': 'SEARCH'},
    {'num': '03', 'title': 'LIBRARY'},
    {'num': '04', 'title': 'PLAYLISTS'},
  ];

  @override
  Widget build(BuildContext context) {
    final meta = _tabMetadata[_currentIndex];

    final screens = [
      HomeScreen(
        onGoToSearch: () {
          setState(() {
            _currentIndex = 1;
          });
        },
      ),
      const SearchScreen(),
      LibraryScreen(
        onSwitchToPlaylistsTab: () {
          setState(() {
            _currentIndex = 3;
          });
        },
      ),
      const PlaylistScreen(),
    ];

    return SwissScaffold(
      title: meta['title']!,
      structuralNumber: meta['num']!,
      currentIndex: _currentIndex,
      onNavigationChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      body: screens[_currentIndex],
    );
  }
}
