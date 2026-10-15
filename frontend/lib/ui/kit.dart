// Shared design system for EnergyTwin: tokens, glass surfaces, buttons,
// inputs, meters and entrance animations used by every screen.
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/ui/locale_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Bottom padding every scrollable screen needs so content clears the floating nav bar.
const double kNavClearance = 110;

/// Localized strings and locale-aware number formatting.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get localeTag => Localizations.localeOf(this).toLanguageTag();

  /// Decimal number in the current locale, e.g. 1.234,5 (de) / 1,234.5 (en).
  String fmt(num v, [int decimals = 0]) => NumberFormat.decimalPatternDigits(locale: localeTag, decimalDigits: decimals).format(v);

  /// Euro amount in the current locale, e.g. 1.686 € (de) / €1,686 (en).
  String eur(num v, [int decimals = 0]) => NumberFormat.currency(locale: localeTag, symbol: '€', decimalDigits: decimals).format(v);

  /// Long date in the current locale from an ISO yyyy-mm-dd string; falls back to the input.
  String date(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? iso : DateFormat.yMMMMd(localeTag).format(d);
  }
}

// ======================================================================
// Tokens
// ======================================================================
abstract final class AppColors {
  static const emerald = Color(0xFF10B981);
  static const teal = Color(0xFF14B8A6);
  static const sky = Color(0xFF38BDF8);
  static const blue = Color(0xFF0EA5E9);
  static const indigo = Color(0xFF6366F1);
  static const violet = Color(0xFF8B5CF6);
  static const amber = Color(0xFFF59E0B);
  static const orange = Color(0xFFF97316);
  static const rose = Color(0xFFEF4444);

  /// Same thresholds the Prices screen has always used.
  static Color forPrice(double ct) => ct < 15 ? emerald : (ct < 25 ? amber : rose);
}

class AppPalette {
  const AppPalette(this.isDark);
  final bool isDark;

  static AppPalette of(BuildContext context) => AppPalette(Theme.of(context).brightness == Brightness.dark);

  Color get bg => isDark ? const Color(0xFF070B16) : const Color(0xFFF5F7FB);
  Color get text => isDark ? Colors.white : const Color(0xFF0B1220);
  Color get muted => isDark ? const Color(0xFF94A3B8) : const Color(0xFF55627A);
  Color get faint => isDark ? const Color(0xFF64748B) : const Color(0xFF8A94A8);
  Color get glass => isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.72);
  Color get glassStrong => isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.9);
  Color get border => isDark ? Colors.white.withValues(alpha: 0.09) : const Color(0xFF0B1220).withValues(alpha: 0.08);
  Color get shadow => isDark ? Colors.black.withValues(alpha: 0.45) : const Color(0xFF1E293B).withValues(alpha: 0.08);
  Color get track => isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFF0B1220).withValues(alpha: 0.06);
  Color get field => isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.9);
}

abstract final class AppType {
  static TextStyle display(double size, Color color, {FontWeight weight = FontWeight.w800, double height = 1.12}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: -size * 0.035);

  static TextStyle body(double size, Color color, {FontWeight weight = FontWeight.w400, double height = 1.55}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, height: height);

  static TextStyle mono(double size, Color color, {FontWeight weight = FontWeight.w600, double spacing = 0}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing);

  static TextStyle eyebrow(Color color) => mono(11.5, color, weight: FontWeight.w700, spacing: 1.8);
}

// ======================================================================
// Background
// ======================================================================
/// Slowly drifting colour glows over a fading technical grid.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    super.key,
    required this.child,
    this.colors = const [AppColors.emerald, AppColors.sky, AppColors.indigo, AppColors.teal],
  });
  final Widget child;
  final List<Color> colors;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) => CustomPaint(painter: AuroraPainter(_c.value, p, widget.colors)),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class AuroraPainter extends CustomPainter {
  AuroraPainter(this.t, this.palette, [this.colors = const [AppColors.emerald, AppColors.sky, AppColors.indigo, AppColors.teal]]);
  final double t;
  final AppPalette palette;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.bg);

    final a = t * 2 * math.pi;
    final s = math.max(size.width, 900.0);
    final strength = palette.isDark ? 1.0 : 0.55;
    final blobs = [
      (Offset(size.width * (0.18 + 0.08 * math.sin(a)), 140 + 60 * math.cos(a)), s * 0.55, colors[0], 0.22),
      (Offset(size.width * (0.85 + 0.06 * math.cos(a * 1.3)), 260 + 80 * math.sin(a * 0.8)), s * 0.5, colors[1 % colors.length], 0.2),
      (Offset(size.width * (0.55 + 0.1 * math.sin(a * 0.7 + 1)), 620 + 90 * math.cos(a * 1.1)), s * 0.45, colors[2 % colors.length], 0.16),
      (Offset(size.width * (0.1 + 0.05 * math.cos(a * 0.9)), 1150 + 70 * math.sin(a)), s * 0.4, colors[3 % colors.length], 0.12),
    ];
    for (final (center, radius, color, alpha) in blobs) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: alpha * strength),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    final gridRect = Rect.fromLTWH(0, 0, size.width, math.min(size.height, 900));
    canvas.saveLayer(gridRect, Paint());
    GridPainter(palette.text.withValues(alpha: palette.isDark ? 0.045 : 0.05), 48).paint(canvas, gridRect.size);
    canvas.drawRect(
      gridRect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.transparent],
        ).createShader(gridRect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(AuroraPainter old) => old.t != t || old.palette.isDark != palette.isDark || old.colors != colors;
}

class GridPainter extends CustomPainter {
  GridPainter(this.color, this.step);
  final Color color;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter old) => old.color != color || old.step != step;
}

/// A min-size row whose [text] ellipsizes when width is bounded, without
/// throwing when placed inside another unbounded Row.
class _InlineRow extends StatelessWidget {
  const _InlineRow({required this.text, this.leading = const [], this.trailing = const [], this.expand = false});
  final Widget text;
  final List<Widget> leading;
  final List<Widget> trailing;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => Row(
        mainAxisSize: expand && c.hasBoundedWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...leading,
          c.hasBoundedWidth ? Flexible(child: text) : text,
          ...trailing,
        ],
      ),
    );
  }
}

// ======================================================================
// Surfaces
// ======================================================================
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding = EdgeInsets.zero,
    this.strong = false,
    this.blur = false,
    this.shadow = true,
    this.borderColor,
  });
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool strong;
  final bool blur;
  final bool shadow;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    Widget surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: strong ? p.glassStrong : p.glass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? p.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: p.isDark ? 0.06 : 0.5),
            Colors.white.withValues(alpha: 0),
          ],
        ),
      ),
      child: child,
    );
    if (blur) {
      surface = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: surface),
      );
    }
    if (!shadow) return surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 30, offset: const Offset(0, 14), spreadRadius: -10)],
      ),
      child: surface,
    );
  }
}

/// A glass panel with an optional icon/title header.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.colors = const [AppColors.emerald, AppColors.sky],
    this.trailing,
    this.padding = const EdgeInsets.all(24),
    this.strong = false,
  });
  final Widget child;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final List<Color> colors;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Glass(
      radius: 24,
      strong: strong,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[IconTile(icon: icon!, colors: colors, size: 40), const SizedBox(width: 14)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title!, style: AppType.display(18, p.text)),
                      if (subtitle != null) ...[const SizedBox(height: 3), Text(subtitle!, style: AppType.body(13, p.muted, height: 1.4))],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
            const SizedBox(height: 22),
          ],
          child,
        ],
      ),
    );
  }
}

class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, required this.colors, this.size = 44, this.soft = false});
  final IconData icon;
  final List<Color> colors;
  final double size;

  /// Tinted background with a coloured icon instead of a solid gradient.
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(size * 0.3);
    if (soft) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: r,
          color: colors.first.withValues(alpha: 0.12),
          border: Border.all(color: colors.first.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: colors.first, size: size * 0.5),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.35), blurRadius: size * 0.35, offset: Offset(0, size * 0.1))],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.52),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.color, required this.label, this.icon});
  final Color color;
  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: _InlineRow(
        leading: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 5)],
        ],
        text: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: AppType.body(11.5, color, weight: FontWeight.w700, height: 1.2),
        ),
      ),
    );
  }
}

class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key, required this.pulse, required this.label, this.color = AppColors.emerald});
  final Animation<double> pulse;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final textColor = Color.lerp(color, p.isDark ? Colors.white : Colors.black, p.isDark ? 0.35 : 0.35)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: color.withValues(alpha: p.isDark ? 0.1 : 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: _InlineRow(
        leading: [
          PulseDot(pulse: pulse, color: color),
          const SizedBox(width: 8),
        ],
        text: Text(label, style: AppType.body(12.5, textColor, weight: FontWeight.w600, height: 1.2)),
      ),
    );
  }
}

class PulseDot extends StatelessWidget {
  const PulseDot({super.key, required this.pulse, required this.color});
  final Animation<double> pulse;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (_, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 6 + 8 * pulse.value,
              height: 6 + 8 * pulse.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.5 * (1 - pulse.value)),
              ),
            ),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.wide = true,
    this.accent = AppColors.emerald,
    this.compact = false,
  });
  final String eyebrow;
  final String title;
  final String? subtitle;
  final bool wide;
  final Color accent;

  /// Smaller title for in-page section headings.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final size = compact ? (wide ? 30.0 : 24.0) : (wide ? 44.0 : 30.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.2)]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(child: Text(eyebrow, style: AppType.eyebrow(accent))),
          ],
        ),
        SizedBox(height: compact ? 12 : 16),
        Text(title, style: AppType.display(size, p.text, height: 1.12)),
        if (subtitle != null) ...[
          SizedBox(height: compact ? 10 : 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(subtitle!, style: AppType.body(compact ? 15 : 16, p.muted, height: 1.6)),
          ),
        ],
      ],
    );
  }
}

// ======================================================================
// Buttons
// ======================================================================
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.colors = const [AppColors.emerald, AppColors.blue],
  });
  final String label;
  final IconData? icon;

  /// Null disables the button.
  final VoidCallback? onTap;
  final bool loading;
  final bool expand;
  final List<Color> colors;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.loading;
    final hover = _hover && enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      onTap: enabled ? widget.onTap : null,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: enabled ? widget.onTap : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: widget.onTap == null ? 0.45 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(0, hover ? -2 : 0, 0),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(colors: widget.colors),
                boxShadow: [
                  BoxShadow(
                    color: widget.colors.first.withValues(alpha: hover ? 0.55 : (enabled ? 0.35 : 0.1)),
                    blurRadius: hover ? 32 : 20,
                    offset: const Offset(0, 10),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: _InlineRow(
                expand: widget.expand,
                leading: [
                  if (widget.loading) ...[
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    const SizedBox(width: 12),
                  ],
                ],
                text: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.body(15, Colors.white, weight: FontWeight.w700, height: 1.2),
                ),
                trailing: [
                  if (widget.icon != null && !widget.loading)
                    AnimatedPadding(
                      duration: const Duration(milliseconds: 220),
                      padding: EdgeInsets.only(left: hover ? 14 : 10),
                      child: Icon(widget.icon, size: 18, color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatefulWidget {
  const SecondaryButton({super.key, required this.label, required this.onTap, this.icon, this.accent = AppColors.emerald});
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color accent;

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: enabled ? 1 : 0.4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _hover && enabled ? p.glassStrong : p.glass,
                border: Border.all(color: _hover && enabled ? widget.accent.withValues(alpha: 0.5) : p.border),
              ),
              child: _InlineRow(
                leading: [
                  if (widget.icon != null) ...[Icon(widget.icon, size: 18, color: p.text), const SizedBox(width: 10)],
                ],
                text: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.body(15, p.text, weight: FontWeight.w600, height: 1.2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: p.glass,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: Tween(begin: 0.5, end: 1.0).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(icon, key: ValueKey(icon), size: 20, color: p.text),
            ),
          ),
        ),
      ),
    );
  }
}

/// Light/dark toggle wired to the app-wide theme notifier.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, required this.themeNotifier});
  final ValueNotifier<ThemeMode> themeNotifier;

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.of(context).isDark;
    return GlassIconButton(
      icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
      tooltip: isDark ? context.l10n.themeLight : context.l10n.themeDark,
      onTap: () => themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}

/// Compact DE / EN switch bound to [localeController].
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return ValueListenableBuilder<Locale>(
      valueListenable: localeController,
      builder: (context, current, _) => Tooltip(
        message: context.l10n.language,
        child: Container(
          height: 42,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: p.glass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final l in LocaleController.supported)
                _LangChip(
                  code: l.languageCode.toUpperCase(),
                  label: l.languageCode == 'de' ? 'Deutsch' : 'English',
                  selected: current.languageCode == l.languageCode,
                  onTap: () => localeController.set(l),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({required this.code, required this.label, required this.selected, required this.onTap});
  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: selected ? const LinearGradient(colors: [AppColors.emerald, AppColors.sky]) : null,
            ),
            child: Text(code, style: AppType.mono(11.5, selected ? Colors.white : p.muted, weight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}

class TextLink extends StatefulWidget {
  const TextLink({super.key, required this.label, required this.color, required this.onTap, this.icon = Icons.arrow_forward_rounded});
  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData icon;

  @override
  State<TextLink> createState() => _TextLinkState();
}

class _TextLinkState extends State<TextLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: _InlineRow(
            text: Text(widget.label, style: AppType.body(13.5, widget.color, weight: FontWeight.w700, height: 1.2)),
            trailing: [
              AnimatedPadding(
                duration: const Duration(milliseconds: 220),
                padding: EdgeInsets.only(left: _hover ? 10 : 6),
                child: Icon(widget.icon, size: 16, color: widget.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HoverScale extends StatefulWidget {
  const HoverScale({super.key, required this.child, this.scale = 1.04});
  final Widget child;
  final double scale;

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? widget.scale : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Sliding-pill segmented control.
class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.colors = const [AppColors.sky, AppColors.indigo],
    this.segmentWidth = 108,
  });
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final List<Color> colors;
  final double segmentWidth;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final idx = options.indexWhere((o) => o.$1 == value).clamp(0, options.length - 1);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.glass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeOutBack,
              alignment: Alignment(options.length == 1 ? 0 : -1 + 2 * idx / (options.length - 1), 0),
              child: Container(
                width: segmentWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(colors: colors),
                  boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 4))],
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final o in options)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => o.$1 == value ? null : onChanged(o.$1),
                    child: SizedBox(
                      width: segmentWidth,
                      height: 38,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: AppType.body(13.5, o.$1 == value ? Colors.white : p.muted, weight: FontWeight.w700, height: 1.2),
                          child: Text(o.$2),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Inputs
// ======================================================================
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.helper,
    this.icon,
    this.suffix,
    this.hint,
    this.keyboardType,
    this.accent = AppColors.emerald,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String label;
  final String? helper;
  final String? hint;
  final IconData? icon;
  final String? suffix;
  final TextInputType? keyboardType;
  final Color accent;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppType.body(13, p.text, weight: FontWeight.w600, height: 1.2)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onSubmitted: onSubmitted,
          cursorColor: accent,
          style: AppType.body(15, p.text, weight: FontWeight.w600, height: 1.3),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: AppType.body(15, p.faint, height: 1.3),
            prefixIcon: icon == null ? null : Icon(icon, size: 20, color: p.muted),
            suffixText: suffix,
            suffixStyle: AppType.mono(12, p.muted),
            filled: true,
            fillColor: p.field,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: border(p.border),
            enabledBorder: border(p.border),
            focusedBorder: border(accent, 1.6),
            helperText: helper,
            helperMaxLines: 2,
            helperStyle: AppType.body(12, p.muted, height: 1.3),
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// Data display
// ======================================================================
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.decimals,
    required this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 1400),
    this.thousands = false,
    this.currency = false,
  });
  final double value;
  final int decimals;
  final TextStyle style;
  final String prefix;
  final String suffix;
  final Duration duration;

  /// Group digits per locale (12.450 in German, 12,450 in English).
  final bool thousands;

  /// Format as a euro amount in the current locale; [prefix] is ignored.
  final bool currency;

  @override
  Widget build(BuildContext context) {
    final tag = context.localeTag;
    final NumberFormat f;
    if (currency) {
      f = NumberFormat.currency(locale: tag, symbol: '€', decimalDigits: decimals);
    } else {
      f = NumberFormat.decimalPatternDigits(locale: tag, decimalDigits: decimals);
      if (!thousands) f.turnOffGrouping();
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutExpo,
      builder: (_, v, _) => Text(
        '${currency ? '' : prefix}${f.format(v)}$suffix',
        maxLines: 1,
        overflow: TextOverflow.visible,
        style: style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}

/// KPI tile with gradient icon, animated value and hover lift.
class KpiTile extends StatefulWidget {
  const KpiTile({
    super.key,
    required this.icon,
    required this.colors,
    required this.label,
    this.number,
    this.decimals = 0,
    this.prefix = '',
    this.suffix = '',
    this.text,
    this.sub,
    this.valueColor,
    this.thousands = false,
    this.currency = false,
  }) : assert(number != null || text != null);
  final IconData icon;
  final List<Color> colors;
  final String label;
  final double? number;
  final int decimals;
  final String prefix;
  final String suffix;

  /// Static value used instead of an animated [number].
  final String? text;
  final String? sub;
  final Color? valueColor;
  final bool thousands;
  final bool currency;

  @override
  State<KpiTile> createState() => _KpiTileState();
}

class _KpiTileState extends State<KpiTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final style = AppType.display(28, widget.valueColor ?? p.text, height: 1.1);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
        child: Glass(
          radius: 22,
          strong: _hover,
          borderColor: _hover ? widget.colors.first.withValues(alpha: 0.45) : null,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.label, maxLines: 2, style: AppType.body(12.5, p.muted, weight: FontWeight.w600, height: 1.3)),
                  ),
                  const SizedBox(width: 8),
                  IconTile(icon: widget.icon, colors: widget.colors, size: 36),
                ],
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: widget.number != null
                    ? CountUp(
                        value: widget.number!,
                        decimals: widget.decimals,
                        prefix: widget.prefix,
                        suffix: widget.suffix,
                        thousands: widget.thousands,
                        currency: widget.currency,
                        style: style,
                      )
                    : Text(widget.text!, style: style),
              ),
              if (widget.sub != null) ...[
                const SizedBox(height: 4),
                Text(widget.sub!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.body(12, p.faint, height: 1.3)),
              ],
              const SizedBox(height: 14),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                height: 3,
                width: _hover ? 64 : 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: widget.colors),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal bar that grows to [fraction] on first build.
class AnimatedBar extends StatelessWidget {
  const AnimatedBar({
    super.key,
    required this.fraction,
    required this.colors,
    this.height = 10,
    this.duration = const Duration(milliseconds: 1200),
  });
  final double fraction;
  final List<Color> colors;
  final double height;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      height: height,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(color: p.track, borderRadius: BorderRadius.circular(height)),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => FractionallySizedBox(
          widthFactor: v,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height),
              gradient: LinearGradient(colors: colors.length == 1 ? [colors.first, colors.first] : colors),
              boxShadow: [BoxShadow(color: colors.last.withValues(alpha: 0.35), blurRadius: 10)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated circular gauge.
class RingMeter extends StatelessWidget {
  const RingMeter({
    super.key,
    required this.value,
    required this.colors,
    required this.label,
    this.centerText,
    this.size = 104,
    this.stroke = 10,
  });

  /// 0..1
  final double value;
  final List<Color> colors;
  final String label;

  /// Defaults to the animated percentage.
  final String? centerText;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 1600),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RingPainter(v, colors, p.track, stroke),
              child: Center(
                child: Text(
                  centerText ?? '${(v * 100).round()}%',
                  style: AppType.display(size * 0.2, p.text).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppType.body(12.5, p.muted, weight: FontWeight.w600, height: 1.3),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.colors, this.track, this.stroke);
  final double v;
  final List<Color> colors;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (v <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [...colors, colors.first],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * v, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v || old.track != track;
}

/// Numbered progress stepper.
class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.steps, required this.active, this.colors = const [AppColors.amber, AppColors.orange]});
  final List<String> steps;
  final int active;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Glass(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(color: p.track, borderRadius: BorderRadius.circular(2)),
                    child: AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      widthFactor: i <= active ? 1 : 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: colors),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            _StepDot(index: i, active: active, label: steps[i], colors: colors),
          ],
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.index, required this.active, required this.label, required this.colors});
  final int index;
  final int active;
  final String label;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final done = index < active;
    final curr = index == active;
    final lit = done || curr;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: lit ? LinearGradient(colors: colors) : null,
            color: lit ? null : Colors.transparent,
            border: lit ? null : Border.all(color: p.border, width: 1.5),
            boxShadow: curr ? [BoxShadow(color: colors.first.withValues(alpha: 0.5), blurRadius: 16, spreadRadius: 1)] : null,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text('${index + 1}', style: AppType.mono(13, lit ? Colors.white : p.muted, weight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppType.body(11.5, curr ? p.text : p.muted, weight: curr ? FontWeight.w700 : FontWeight.w500, height: 1.2)),
      ],
    );
  }
}

// ======================================================================
// States
// ======================================================================
/// Animated glowing orb with an icon — used for heroes and loading states.
class HeroOrb extends StatefulWidget {
  const HeroOrb({super.key, required this.icon, required this.colors, this.size = 150});
  final IconData icon;
  final List<Color> colors;
  final double size;

  @override
  State<HeroOrb> createState() => _HeroOrbState();
}

class _HeroOrbState extends State<HeroOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final core = s * 0.46;
    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (var k = 0; k < 3; k++)
                Builder(
                  builder: (_) {
                    final t = (_c.value + k / 3) % 1;
                    final d = core + (s - core) * t;
                    return Container(
                      width: d,
                      height: d,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: widget.colors.first.withValues(alpha: 0.45 * (1 - t)), width: 1.5),
                      ),
                    );
                  },
                ),
              Transform.rotate(
                angle: _c.value * 2 * math.pi,
                child: CustomPaint(size: Size.square(s * 0.72), painter: _OrbitPainter(widget.colors.last)),
              ),
              Container(
                width: core,
                height: core,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: widget.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: widget.colors.first.withValues(alpha: 0.55), blurRadius: s * 0.25)],
                ),
                child: Icon(widget.icon, color: Colors.white, size: core * 0.5),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final dash = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const n = 36;
    for (var i = 0; i < n; i += 2) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), i * 2 * math.pi / n, math.pi / n, false, dash);
    }
    canvas.drawCircle(c + Offset(r, 0), 4, Paint()..color = color);
    canvas.drawCircle(c + Offset(-r * 0.5, r * 0.866), 3, Paint()..color = color.withValues(alpha: 0.7));
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.color != color;
}

class LoadingPanel extends StatelessWidget {
  const LoadingPanel({
    super.key,
    required this.message,
    this.sub,
    this.icon = Icons.bolt_rounded,
    this.colors = const [AppColors.emerald, AppColors.sky],
  });
  final String message;
  final String? sub;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Glass(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeroOrb(icon: icon, colors: colors, size: 120),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(message, key: ValueKey(message), textAlign: TextAlign.center, style: AppType.display(18, p.text)),
          ),
          if (sub != null) ...[const SizedBox(height: 6), Text(sub!, textAlign: TextAlign.center, style: AppType.body(13, p.muted))],
          const SizedBox(height: 22),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(minHeight: 4, color: colors.first, backgroundColor: p.track),
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({
    super.key,
    required this.message,
    required this.onAction,
    this.title,
    this.actionLabel,
    this.actionIcon = Icons.refresh_rounded,
  });
  final String? title;
  final String message;
  final VoidCallback onAction;
  final String? actionLabel;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Glass(
      radius: 24,
      borderColor: AppColors.rose.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const IconTile(icon: Icons.cloud_off_rounded, colors: [AppColors.rose], size: 56, soft: true),
          const SizedBox(height: 18),
          Text(title ?? context.l10n.errorTitle, textAlign: TextAlign.center, style: AppType.display(18, p.text)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: AppType.body(14, p.muted)),
          const SizedBox(height: 22),
          SecondaryButton(label: actionLabel ?? context.l10n.tryAgain, icon: actionIcon, onTap: onAction, accent: AppColors.rose),
        ],
      ),
    );
  }
}

class Shimmer extends StatefulWidget {
  const Shimmer({super.key, this.width, required this.height, this.radius = 12});
  final double? width;
  final double height;
  final double radius;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final base = p.isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFF0B1220).withValues(alpha: 0.06);
    final hi = p.isDark ? Colors.white.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.9);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(begin: Alignment(-3 + _c.value * 4, 0), end: Alignment(-1 + _c.value * 4, 0), colors: [base, hi, base]),
        ),
      ),
    );
  }
}

// ======================================================================
// Motion
// ======================================================================
/// Fades and slides [child] in once, after [delay].
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero, this.offset = 24});
  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(offset: Offset(0, widget.offset * (1 - _a.value)), child: child),
      ),
    );
  }
}

/// Fades and slides [child] in during the [start]–[end] slice of [controller].
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.controller, required this.start, required this.end, required this.child, this.offset = 24});
  final Animation<double> controller;
  final double start;
  final double end;
  final double offset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curve = Interval(start, end, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (_, child) {
        final v = curve.transform(controller.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, offset * (1 - v)), child: child),
        );
      },
    );
  }
}

/// Fades and slides [child] in the first time it scrolls into view.
class ScrollReveal extends StatefulWidget {
  const ScrollReveal({super.key, required this.controller, required this.child, this.delay = Duration.zero});
  final ScrollController controller;
  final Widget child;
  final Duration delay;

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal> {
  bool _visible = false;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_triggered || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top < MediaQuery.sizeOf(context).height * 0.92) {
      _triggered = true;
      widget.controller.removeListener(_check);
      Future.delayed(widget.delay, () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ======================================================================
// Layout helpers
// ======================================================================
/// Lays [children] out in equal-width columns that wrap on narrow screens.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({super.key, required this.children, this.minItemWidth = 240, this.maxColumns = 4, this.gap = 16});
  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = (c.maxWidth / minItemWidth).floor().clamp(1, maxColumns);
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final child in children) SizedBox(width: w, child: child)],
        );
      },
    );
  }
}

/// Horizontal gutter used by every screen.
double pageGutter(BuildContext context) => MediaQuery.sizeOf(context).width < 600 ? 20 : 32;

/// Centres content at a max width with the standard gutter.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.maxWidth = 1200});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pageGutter(context)),
          child: child,
        ),
      ),
    );
  }
}
