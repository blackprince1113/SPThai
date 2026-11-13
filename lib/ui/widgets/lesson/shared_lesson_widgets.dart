import 'package:flutter/material.dart';
import 'package:superthai/ui/widgets/editor/shared_editor_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:superthai/ui/theme/app_theme.dart';

class ThaiIllustration extends StatelessWidget {
  final String source;
  final double height;
  final double iconSize;

  const ThaiIllustration({
    super.key,
    required this.source,
    this.height = 180,
    this.iconSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) return const SizedBox.shrink();

    if (source.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: source,
        height: height,
        fit: BoxFit.contain,
        placeholder: (context, url) => SizedBox(
          height: height,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Icon(
          Icons.image_not_supported_rounded,
          size: iconSize,
          color: Colors.grey,
        ),
      );
    }

    return Text(
      source,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: height * 0.8),
    );
  }
}

class ThaiQuestionCard extends StatelessWidget {
  final String? header;
  final Widget? headerWidget;
  final Widget child;
  final EdgeInsets padding;
  final String? illustrationSource;
  final double illustrationHeight;

  const ThaiQuestionCard({
    super.key,
    this.header,
    this.headerWidget,
    required this.child,
    this.padding = const EdgeInsets.all(32),
    this.illustrationSource,
    this.illustrationHeight = 150,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (headerWidget != null || header != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child:
                  headerWidget ??
                  Text(
                    header!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
            ),
          Padding(
            padding: padding,
            child: Column(
              children: [
                if (illustrationSource != null &&
                    illustrationSource!.isNotEmpty) ...[
                  ThaiIllustration(
                    source: illustrationSource!,
                    height: illustrationHeight,
                  ),
                  const SizedBox(height: 16),
                ],
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ThaiInputContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  const ThaiInputContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: child,
    );
  }
}

class ThaiSectionLabel extends StatelessWidget {
  final String label;
  final Color? color;
  final double fontSize;
  final EdgeInsets padding;

  const ThaiSectionLabel({
    super.key,
    required this.label,
    this.color,
    this.fontSize = 10,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        label,
        style: TextStyle(
          color: color ?? Colors.grey,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class ThaiSoundButtonsRow extends StatelessWidget {
  final VoidCallback onNormal;
  final VoidCallback onSlow;
  final double spacing;

  const ThaiSoundButtonsRow({
    super.key,
    required this.onNormal,
    required this.onSlow,
    this.spacing = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ThaiSpeakIconButton(
          icon: Icons.volume_up_rounded,
          label: "NORMAL",
          color: AppTheme.primaryColor,
          onTap: onNormal,
        ),
        SizedBox(width: spacing),
        ThaiSpeakIconButton(
          icon: Icons.slow_motion_video_rounded,
          label: "SLOW",
          color: Colors.pink.shade300,
          onTap: onSlow,
        ),
      ],
    );
  }
}

class ThaiEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const ThaiEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}

class ThaiSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const ThaiSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.light ? 0.05 : 0.2,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: theme.disabledColor, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: theme.disabledColor),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: theme.disabledColor,
                  ),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}

