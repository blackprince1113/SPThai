import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:superthai/ui/screens/add_discover_screen.dart';
import 'package:superthai/core/services/auth_service.dart';
import 'package:superthai/core/utils/error_handler.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late Future<List<DiscoverItem>> _discoverFuture;

  @override
  void initState() {
    super.initState();
    _refreshDiscover();
  }

  void _refreshDiscover() {
    if (!mounted) return;
    setState(() {
      _discoverFuture = DataService.instance.getAllDiscoverItems();
    });
  }

  Future<void> _deleteDiscoverItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete site?"),
        content: const Text(
          "Are you sure you want to remove this interesting site?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DataService.instance.deleteDiscoverItem(id);
      if (!mounted) return;
      _refreshDiscover();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final isAdmin = AuthService.instance.isAdmin;

        return Scaffold(
          appBar: ThaiAppBar(
            title: "Discover",
            actions: [
              if (isAdmin)
                IconButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddDiscoverScreen(),
                      ),
                    );
                    if (!context.mounted) return;
                    if (result == true) {
                      _refreshDiscover();
                    }
                  },
                  icon: Icon(
                    Icons.add_link_rounded,
                    color: AppTheme.primaryColor,
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => _refreshDiscover(),
            color: AppTheme.primaryColor,
            child: FutureBuilder<List<DiscoverItem>>(
              future: _discoverFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(ErrorHandler.getMessage(snapshot.error)),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3,
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.explore_rounded,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No interesting sites yet",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildDiscoverCard(item, isAdmin);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiscoverCard(DiscoverItem item, bool isAdmin) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.light ? 0.05 : 0.2,
            ),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        width: 120,
                        height: 120,
                        color: theme.brightness == Brightness.light
                            ? Colors.grey.shade100
                            : Colors.white.withValues(alpha: 0.05),
                        child:
                            item.imageUrl != null && item.imageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                      Icons.broken_image_rounded,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                              )
                            : Icon(
                                Icons.explore_rounded,
                                color: theme.disabledColor,
                                size: 40,
                              ),
                      ),
                    ),
                    if (item.isPinned)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 6,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                "Pinned",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleMedium?.color,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            item.description ?? "No description available",
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.disabledColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () async {
                                final uri = Uri.parse(item.url);
                                final canLaunch = await canLaunchUrl(uri);
                                if (!mounted) return;

                                if (canLaunch) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Could not open the link"),
                                    ),
                                  );
                                }
                              },
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                              icon: Icon(
                                Icons.open_in_new_rounded,
                                size: 20,
                                color: AppTheme.primaryColor,
                              ),
                              tooltip: "Open Website",
                            ),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: item.url),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Link copied to clipboard! 📋",
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                              icon: Icon(
                                Icons.share_outlined,
                                size: 20,
                                color: theme.disabledColor,
                              ),
                            ),
                            if (isAdmin)
                              PopupMenuButton<String>(
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  Icons.more_vert_rounded,
                                  size: 20,
                                  color: theme.disabledColor,
                                ),
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddDiscoverScreen(
                                          existingDiscover: item,
                                        ),
                                      ),
                                    );
                                    if (!mounted) return;
                                    if (result == true) _refreshDiscover();
                                  } else if (value == 'delete') {
                                    _deleteDiscoverItem(item.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text("Edit"),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
