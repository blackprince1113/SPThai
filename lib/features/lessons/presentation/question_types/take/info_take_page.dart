import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

class InfoTakePage extends StatelessWidget {
  final String title;
  final String content;
  final String imageUrl;
  final bool showAppBar;
  final int currentIndex;
  final int totalSteps;

  const InfoTakePage({
    super.key,
    required this.title,
    required this.content,
    required this.imageUrl,
    this.showAppBar = true,
    this.currentIndex = 0,
    this.totalSteps = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget body = SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            ThaiLessonProgress(
              currentIndex: currentIndex,
              totalSteps: totalSteps,
            ),
            const SizedBox(height: 24),
            if (imageUrl.isNotEmpty && imageUrl.startsWith('http'))
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 220,
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 220,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.headlineMedium?.color,
                ),
              ),
            ),
            const SizedBox(height: 16),
            DefaultSelectionStyle(
              selectionColor: AppTheme.primaryColor.withValues(alpha: 0.3),
              cursorColor: AppTheme.primaryColor,
              child: MarkdownBody(
                data: content,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 16,
                    color: theme.textTheme.bodyLarge?.color?.withValues(
                      alpha: 0.8,
                    ),
                    height: 1.6,
                  ),
                  blockquote: TextStyle(
                    fontSize: 16,
                    color: theme.textTheme.bodyLarge?.color?.withValues(
                      alpha: 0.8,
                    ),
                    fontStyle: FontStyle.italic,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  blockquotePadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ThaiButton(
                text: "CONTINUE",
                onPressed: () => StepResultNotification(true).dispatch(context),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (!showAppBar) {
      body = SafeArea(child: body);
    }

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text("Info Note"),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: body,
    );
  }
}
