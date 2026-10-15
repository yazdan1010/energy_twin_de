import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:frontend/ui/kit.dart';

class GlassNavItem {
  const GlassNavItem({required this.icon, required this.selectedIcon, required this.label, required this.colors});
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final List<Color> colors;
}

/// Floating frosted navigation bar with an animated gradient pill on the active tab.
/// Use with `Scaffold(extendBody: true)` so content scrolls beneath it.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({super.key, required this.items, required this.index, required this.onChanged});
  final List<GlassNavItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: p.isDark ? 0.5 : 0.12), blurRadius: 40, offset: const Offset(0, 16))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    height: 70,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: p.isDark ? const Color(0xFF0F172A).withValues(alpha: 0.72) : Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: p.border),
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(child: _NavButton(item: items[i], selected: i == index, onTap: () => onChanged(i))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  const _NavButton({required this.item, required this.selected, required this.onTap});
  final GlassNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final sel = widget.selected;
    final colors = widget.item.colors;
    return Semantics(
      selected: sel,
      button: true,
      label: widget.item.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: sel
                  ? LinearGradient(colors: [colors.first.withValues(alpha: 0.22), colors.last.withValues(alpha: 0.12)])
                  : null,
              color: sel ? null : (_hover ? p.glass : Colors.transparent),
              border: Border.all(color: sel ? colors.first.withValues(alpha: 0.35) : Colors.transparent),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: sel ? 1.1 : 1,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  child: sel
                      ? ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (b) => LinearGradient(colors: colors).createShader(b),
                          child: Icon(widget.item.selectedIcon, size: 22),
                        )
                      : Icon(widget.item.icon, size: 22, color: p.muted),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: AppType.body(11, sel ? p.text : p.muted, weight: sel ? FontWeight.w700 : FontWeight.w500, height: 1.2),
                  child: Text(widget.item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
