import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:superthai/ui/screens/settings_screen.dart';
import 'package:superthai/ui/screens/login_screen.dart';
import 'package:superthai/ui/screens/main_container.dart';
import 'package:superthai/ui/theme/app_theme.dart';

class ThaiAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final double? leadingWidth;
  final bool showProfile;
  final bool? centerTitle;

  const ThaiAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.leadingWidth,
    this.showProfile = true,
    this.centerTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null) {
      final canPop = ModalRoute.of(context)?.canPop ?? false;
      if (canPop) {
        effectiveLeading = IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        );
      } else {
        effectiveLeading = IconButton(
          icon: Icon(Icons.menu_rounded, color: theme.colorScheme.primary),
          onPressed: () {
            final mainState = MainContainer.of(context);
            if (mainState != null) {
              mainState.openDrawer();
            } else {
              Scaffold.maybeOf(context)?.openDrawer();
            }
          },
        );
      }
    }

    return AppBar(
      toolbarHeight: 65,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: centerTitle ?? false,
      title:
          titleWidget ??
          Text(
            title ?? "",
            style:
                theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 18) ??
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
      actions: [
        ...?actions,
        if (showProfile)
          IconButton(
            icon: Icon(
              Icons.person_outline_rounded,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        const SizedBox(width: 8),
      ],
      leading: effectiveLeading,
      leadingWidth: leadingWidth,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(65);
}

class ThaiButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isLoading;

  const ThaiButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: color != null
          ? ElevatedButton.styleFrom(backgroundColor: color)
          : null,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(text),
    );
  }
}

class ThaiTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool isPassword;
  final int? maxLines;

  const ThaiTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.isPassword = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        maxLines: isPassword ? 1 : maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null
              ? Icon(icon, color: Theme.of(context).primaryColor)
              : null,
        ),
      ),
    );
  }
}

class ThaiCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const ThaiCard({super.key, required this.child, this.onTap, this.padding});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

class ThaiLessonProgress extends StatelessWidget {
  final int currentIndex;
  final int totalSteps;

  const ThaiLessonProgress({
    super.key,
    required this.currentIndex,
    required this.totalSteps,
  });

  double get _value => (currentIndex + 1) / (totalSteps > 0 ? totalSteps : 1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LinearProgressIndicator(
      value: _value.clamp(0, 1),
      backgroundColor: Colors.grey.shade200,
      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
      borderRadius: BorderRadius.circular(10),
      minHeight: 8,
    );
  }
}

class ThaiAnswerChoiceButton extends StatelessWidget {
  final String text;
  final bool answered;
  final bool selected;
  final bool correct;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;
  final double borderRadius;
  final EdgeInsets margin;

  const ThaiAnswerChoiceButton({
    super.key,
    required this.text,
    required this.answered,
    required this.selected,
    required this.correct,
    required this.onTap,
    this.height = 65,
    this.fontSize = 20,
    this.borderRadius = 20,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    var background = theme.cardColor;
    var textColor = theme.textTheme.bodyLarge?.color ?? AppTheme.textColor;
    var borderColor = theme.dividerColor.withValues(alpha: 0.2);

    if (answered) {
      if (correct) {
        background = Colors.green.withValues(alpha: 0.1);
        borderColor = Colors.green.withValues(alpha: 0.5);
        textColor = Colors.green;
      } else if (selected) {
        background = Colors.red.withValues(alpha: 0.1);
        borderColor = Colors.red.withValues(alpha: 0.5);
        textColor = Colors.red;
      }
    }

    return Padding(
      padding: margin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: answered ? null : onTap,
            borderRadius: BorderRadius.circular(borderRadius - 2),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTheme.getResponsiveFontSize(text, fontSize),
                    fontWeight: FontWeight.bold,
                    color: textColor,
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

class ThaiFeedbackCard extends StatelessWidget {
  final bool correct;
  final String correctTitle;
  final String incorrectTitle;
  final String? answerLabel;
  final String? answerText;
  final VoidCallback onContinue;
  final IconData correctIcon;
  final IconData incorrectIcon;
  final String buttonText;

  const ThaiFeedbackCard({
    super.key,
    required this.correct,
    required this.correctTitle,
    required this.incorrectTitle,
    required this.onContinue,
    this.answerLabel,
    this.answerText,
    this.correctIcon = Icons.check_circle_rounded,
    this.incorrectIcon = Icons.cancel_rounded,
    this.buttonText = "CONTINUE",
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = correct ? Colors.green : Colors.red;
    final title = correct ? correctTitle : incorrectTitle;
    final icon = correct ? correctIcon : incorrectIcon;
    final showAnswer = !correct && answerText != null && answerText!.isNotEmpty;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light
                  ? (correct ? Colors.green.shade50 : Colors.red.shade50)
                  : statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: theme.brightness == Brightness.light
                    ? (correct ? Colors.green.shade300 : Colors.red.shade300)
                    : statusColor.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: statusColor.shade700, size: 32),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: statusColor.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (showAnswer) ...[
                  const SizedBox(height: 16),
                  if (answerLabel != null)
                    Text(
                      answerLabel!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.brightness == Brightness.light
                            ? statusColor
                            : statusColor.shade300,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    answerText!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.brightness == Brightness.light
                          ? statusColor.shade900
                          : statusColor.shade200,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ThaiButton(
                  text: buttonText,
                  color: statusColor,
                  onPressed: onContinue,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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

class StepResultNotification extends Notification {
  final bool result;
  StepResultNotification(this.result);
}

class ThaiDialogs {
  static void showSignupPrompt(
    BuildContext context, {
    String? title,
    String? message,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title ?? "Account Required 🚀"),
        content: Text(
          message ??
              "Please create an account or login to save your progress and access more features!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Maybe Later"),
          ),
          ThaiButton(
            text: "Login / Sign Up",
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = "Confirm",
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  const ThaiSettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
              if (!isLast)
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
