import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'mini_player.dart';

class SwissScaffold extends StatelessWidget {
  final String title;
  final String structuralNumber;
  final Widget body;
  final List<Widget>? actions;
  final int currentIndex;
  final ValueChanged<int>? onNavigationChanged;
  final bool showBottomNav;

  const SwissScaffold({
    super.key,
    required this.title,
    required this.structuralNumber,
    required this.body,
    this.actions,
    this.currentIndex = 0,
    this.onNavigationChanged,
    this.showBottomNav = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 16,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: AppTheme.text),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Row(
          children: [
            Text(
              structuralNumber,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '/',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppTheme.border,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppTheme.text,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              size: 20,
              color: AppTheme.text,
            ),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          ...?actions,
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: body),
            const MiniPlayer(),
          ],
        ),
      ),
      bottomNavigationBar: showBottomNav ? _buildBottomNav(context, isDark) : null,
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    final navItems = [
      {'num': '01', 'label': 'HOME'},
      {'num': '02', 'label': 'SEARCH'},
      {'num': '03', 'label': 'LIBRARY'},
      {'num': '04', 'label': 'PLAYLISTS'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.border, width: AppTheme.borderWidth),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(navItems.length, (index) {
            final isSelected = index == currentIndex;
            final item = navItems[index];

            return Expanded(
              child: InkWell(
                onTap: () => onNavigationChanged?.call(index),
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.text : Colors.transparent,
                    border: Border(
                      left: index > 0
                          ? BorderSide(color: AppTheme.border, width: 1)
                          : BorderSide.none,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['num']!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['label']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: isSelected
                              ? (isDark ? AppTheme.background : Colors.white)
                              : AppTheme.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
