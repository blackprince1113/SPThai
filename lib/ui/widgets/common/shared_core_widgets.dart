import 'package:flutter/material.dart';
import 'package:superthai/ui/screens/profile/settings_screen.dart';
import 'package:superthai/ui/screens/auth/login_screen.dart';
import 'package:superthai/ui/screens/navigation/main_container.dart';
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
    this.showProfile = false,
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
      centerTitle: centerTitle ?? true,
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
    Widget? contentWidget,
    String? warningText,
    String confirmLabel = "Yes",
    String cancelLabel = "No",
    Color? confirmColor,
  }) async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: confirmColor ?? AppTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            contentWidget ??
                Text(
                  content,
                  style: const TextStyle(fontSize: 14),
                ),
            if (warningText != null && warningText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warningText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor ?? AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  confirmLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.brightness == Brightness.light
                      ? Colors.grey.shade200
                      : Colors.grey.shade800,
                  foregroundColor: theme.brightness == Brightness.light
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  cancelLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }
}
