import 'package:flutter/material.dart';
import 'package:superthai/ui/theme/app_theme.dart';

class ThaiSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool isSwitch;
  final bool switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final VoidCallback? onTap;

  const ThaiSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    this.isSwitch = false,
    this.switchValue = false,
    this.onSwitchChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: isSwitch ? null : (onTap ?? () {}),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10.2),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
            if (isSwitch)
              Switch(
                value: switchValue,
                onChanged: onSwitchChanged,
                activeThumbColor: theme.colorScheme.primary,
                activeTrackColor: theme.colorScheme.primary.withValues(
                  alpha: 0.3,
                ),
                inactiveThumbColor: theme.brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade100,
                inactiveTrackColor: theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade300,
              ),
            if (!isSwitch) const SizedBox(width: 8),
            if (!isSwitch)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: theme.disabledColor,
              ),
          ],
        ),
      ),
    );
  }
}

class ThaiSettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final bool showDivider;

  const ThaiSettingsGroup({
    super.key,
    required this.children,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.2),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final tile = entry.value;
          final isLast = index == children.length - 1;

          return Column(
            children: [
              tile,
              if (!isLast && showDivider)
                Divider(
                  height: 1,
                  indent: 60,
                  endIndent: 20,
                  color: theme.dividerColor,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class ThaiCreateHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const ThaiCreateHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: theme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: primaryColor.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class ThaiInfoBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const ThaiInfoBox({
    super.key,
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boxColor = color ?? AppTheme.primaryColor;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: boxColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: boxColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: boxColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ThaiGripScrollbar extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final double thumbWidth;
  final double thumbHeight;
  final EdgeInsets padding;

  const ThaiGripScrollbar({
    super.key,
    required this.child,
    required this.controller,
    this.thumbWidth = 28.0,
    this.thumbHeight = 64.0,
    this.padding = const EdgeInsets.only(top: 12, bottom: 12, right: 6),
  });

  @override
  State<ThaiGripScrollbar> createState() => _ThaiGripScrollbarState();
}

class _ThaiGripScrollbarState extends State<ThaiGripScrollbar> {
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(ThaiGripScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (mounted) {
          setState(() {});
        }
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double trackHeight =
              constraints.maxHeight - widget.padding.top - widget.padding.bottom;
          final double availableTravel = trackHeight - widget.thumbHeight;

          double scrollProgress = 0.0;
          double maxScroll = 0.0;
          bool hasScroll = false;

          if (widget.controller.hasClients) {
            try {
              if (widget.controller.position.hasContentDimensions) {
                maxScroll = widget.controller.position.maxScrollExtent;
                if (maxScroll > 0) {
                  hasScroll = true;
                  scrollProgress =
                      (widget.controller.offset / maxScroll).clamp(0.0, 1.0);
                }
              }
            } catch (_) {}
          }

          final double thumbTop =
              widget.padding.top + (scrollProgress * availableTravel);

          return Stack(
            children: [
              widget.child,
              if (hasScroll)
                Positioned(
                  top: widget.padding.top,
                  bottom: widget.padding.bottom,
                  right: widget.padding.right,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapDown: (details) {
                      if (maxScroll <= 0 || availableTravel <= 0) return;
                      final double localY =
                          details.localPosition.dy - (widget.thumbHeight / 2);
                      final double targetProgress =
                          (localY / availableTravel).clamp(0.0, 1.0);
                      widget.controller.animateTo(
                        targetProgress * maxScroll,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    },
                    child: SizedBox(
                      width: widget.thumbWidth,
                      child: Center(
                        child: Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (hasScroll)
                Positioned(
                  top: thumbTop,
                  right: widget.padding.right,
                  child: GestureDetector(
                    onVerticalDragStart: (_) {
                      setState(() => _isDragging = true);
                    },
                    onVerticalDragEnd: (_) {
                      setState(() => _isDragging = false);
                    },
                    onVerticalDragCancel: () {
                      setState(() => _isDragging = false);
                    },
                    onVerticalDragUpdate: (details) {
                      if (maxScroll <= 0 || availableTravel <= 0) return;
                      final double deltaProgress =
                          details.delta.dy / availableTravel;
                      final double newOffset = (widget.controller.offset +
                              (deltaProgress * maxScroll))
                          .clamp(0.0, maxScroll);
                      widget.controller.jumpTo(newOffset);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: widget.thumbWidth,
                      height: widget.thumbHeight,
                      decoration: BoxDecoration(
                        color: _isDragging
                            ? primaryColor
                            : primaryColor.withValues(alpha: 0.9),
                        borderRadius:
                            BorderRadius.circular(widget.thumbWidth / 2),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(
                                alpha: _isDragging ? 0.4 : 0.25),
                            blurRadius: _isDragging ? 8 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            3,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(vertical: 2.5),
                              width: widget.thumbWidth * 0.42,
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
