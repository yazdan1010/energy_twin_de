import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:frontend/ui/kit.dart';

/// Frosted header shared by the tool screens. Use with `extendBodyBehindAppBar: true`
/// so content scrolls underneath the blur.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.themeNotifier,
    required this.title,
    this.subtitle,
    this.icon = Icons.bolt_rounded,
    this.colors = const [AppColors.emerald, AppColors.sky],
  });
  final ValueNotifier<ThemeMode> themeNotifier;
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Color> colors;

  static const double _height = 72;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: p.bg.withValues(alpha: p.isDark ? 0.62 : 0.7),
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: _height,
              child: PageBody(
                child: Row(
                  children: [
                    IconTile(icon: icon, colors: colors, size: 40),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.display(19, p.text)),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.body(12, p.muted, weight: FontWeight.w500, height: 1.4),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const LanguageToggle(),
                    const SizedBox(width: 10),
                    ThemeToggle(themeNotifier: themeNotifier),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(_height);
}
