import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:superthai/core/utils/error_handler.dart';
import 'package:uuid/uuid.dart';

import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

class AddDiscoverScreen extends StatefulWidget {
  final DiscoverItem? existingDiscover;
  const AddDiscoverScreen({super.key, this.existingDiscover});

  @override
  State<AddDiscoverScreen> createState() => _AddDiscoverScreenState();
}

class _AddDiscoverScreenState extends State<AddDiscoverScreen> {
  late TextEditingController _titleController;
  late TextEditingController _urlController;
  late TextEditingController _descController;
  late TextEditingController _imageUrlController;
  bool _isPinned = false;
  bool _isLoading = false;
  bool _isFetchingMetadata = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingDiscover?.title ?? "",
    );
    _urlController = TextEditingController(
      text: widget.existingDiscover?.url ?? "",
    );
    _descController = TextEditingController(
      text: widget.existingDiscover?.description ?? "",
    );
    _imageUrlController = TextEditingController(
      text: widget.existingDiscover?.imageUrl ?? "",
    );
    _isPinned = widget.existingDiscover?.isPinned ?? false;
  }

  Future<void> _fetchMetadata() async {
    String url = _urlController.text.trim();
    if (url.isEmpty || !url.startsWith("http")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid URL first")),
      );
      return;
    }

    setState(() => _isFetchingMetadata = true);

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = response.body;

        String? extractMeta(String property) {
          final regex = RegExp(
            'property=["\']$property["\'] content=["\'](.*?)["\']|content=["\'](.*?)["\'] property=["\']$property["\']',
            caseSensitive: false,
          );
          final match = regex.firstMatch(body);
          return match?.group(1) ?? match?.group(2);
        }

        String? extractNameMeta(String name) {
          final regex = RegExp(
            'name=["\']$name["\'] content=["\'](.*?)["\']|content=["\'](.*?)["\'] name=["\']$name["\']',
            caseSensitive: false,
          );
          final match = regex.firstMatch(body);
          return match?.group(1) ?? match?.group(2);
        }

        final title = extractMeta('og:title') ?? extractNameMeta('title');
        final description =
            extractMeta('og:description') ?? extractNameMeta('description');
        final image = extractMeta('og:image');

        if (mounted) {
          setState(() {
            if (title != null && _titleController.text.isEmpty) {
              _titleController.text = title;
            }
            if (description != null && _descController.text.isEmpty) {
              _descController.text = description;
            }
            if (image != null) {
              _imageUrlController.text = image;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Metadata fetched successfully! ✨")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Could not fetch preview: $e")));
      }
    } finally {
      if (mounted) setState(() => _isFetchingMetadata = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _descController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveDiscover() async {
    final title = _titleController.text.trim();
    final url = _urlController.text.trim();
    final desc = _descController.text.trim();
    final imageUrl = _imageUrlController.text.trim();

    if (title.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and URL are required!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final item = DiscoverItem(
        id: widget.existingDiscover?.id ?? const Uuid().v4(),
        title: title,
        url: url,
        description: desc.isEmpty ? null : desc,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        isPinned: _isPinned,
        date: widget.existingDiscover?.date ?? DateTime.now(),
      );

      await DataService.instance.addDiscoverItem(item);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingDiscover != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ThaiAppBar(
        title: isEditing ? "Edit Site" : "Add Site",
        showProfile: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ThaiTextField(
              controller: _titleController,
              label: "Site Title",
              icon: Icons.title_rounded,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: ThaiTextField(
                    controller: _urlController,
                    label: "URL Link (https://...)",
                    icon: Icons.link_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    height: 56,
                    width: 56,
                    child: IconButton.filled(
                      onPressed: _isFetchingMetadata ? null : _fetchMetadata,
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: _isFetchingMetadata
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                    ),
                  ),
                ),
              ],
            ),
            if (_imageUrlController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: CachedNetworkImage(
                    imageUrl: _imageUrlController.text,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    errorWidget: (_, _, _) => Container(
                      height: 150,
                      color: theme.brightness == Brightness.light
                          ? Colors.grey.shade100
                          : Colors.white.withValues(alpha: 0.05),
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ThaiTextField(
              controller: _imageUrlController,
              label: "Image URL (Auto-filled)",
              icon: Icons.image_rounded,
            ),
            ThaiTextField(
              controller: _descController,
              label: "Description",
              icon: Icons.description_rounded,
              maxLines: 3,
            ),
            SwitchListTile(
              title: Text(
                "Pin this site",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              value: _isPinned,
              activeThumbColor: theme.colorScheme.primary,
              activeTrackColor: theme.colorScheme.primary.withValues(
                alpha: 0.3,
              ),
              onChanged: (val) => setState(() => _isPinned = val),
            ),
            const SizedBox(height: 32),
            ThaiButton(
              text: isEditing ? "UPDATE SITE" : "PUBLISH SITE",
              isLoading: _isLoading,
              onPressed: _saveDiscover,
            ),
          ],
        ),
      ),
    );
  }
}
