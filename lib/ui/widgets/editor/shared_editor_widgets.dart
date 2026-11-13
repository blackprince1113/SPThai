import 'package:flutter/material.dart';

class ThaiSpeakIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double padding;
  final double iconSize;

  const ThaiSpeakIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.padding = 20,
    this.iconSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: iconSize, color: color),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class ThaiEditableFieldCard extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final int? maxLines;

  const ThaiEditableFieldCard({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.onChanged,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextFormField(
                    controller: controller,
                    maxLines: maxLines,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    decoration: editableInputDecoration(theme, primaryColor),
                    onChanged: onChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThaiEditableChoiceTile extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final bool isCorrect;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onCorrectChanged;

  const ThaiEditableChoiceTile({
    super.key,
    required this.index,
    required this.controller,
    required this.isCorrect,
    required this.onChanged,
    required this.onCorrectChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect
              ? primaryColor.withValues(alpha: 0.4)
              : Colors.transparent,
          width: 2,
        ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isCorrect
                  ? primaryColor
                  : primaryColor.withValues(alpha: 0.1),
              child: Text(
                "${index + 1}",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCorrect
                      ? Colors.white
                      : primaryColor.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: controller,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                decoration: editableInputDecoration(theme, primaryColor),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: isCorrect,
              activeThumbColor: primaryColor,
              activeTrackColor: primaryColor.withValues(alpha: 0.3),
              inactiveThumbColor: primaryColor.withValues(alpha: 0.4),
              inactiveTrackColor: primaryColor.withValues(alpha: 0.1),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              onChanged: controller.text.isEmpty ? null : onCorrectChanged,
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration editableInputDecoration(ThemeData theme, Color focusColor) {
  return InputDecoration(
    hintText: "Tap to type...",
    hintStyle: TextStyle(
      fontWeight: FontWeight.normal,
      color: focusColor.withValues(alpha: 0.5),
      fontSize: 14,
    ),
    filled: true,
    fillColor: theme.brightness == Brightness.light
        ? focusColor.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.1),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: focusColor.withValues(alpha: 0.5),
        width: 1.5,
      ),
    ),
  );
}
