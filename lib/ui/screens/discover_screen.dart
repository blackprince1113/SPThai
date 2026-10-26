import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/core/services/media_preload_service.dart';
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

  bool _hasCheckedMedia = false;
  bool _isDownloadingMedia = false;
  double _downloadProgress = 0.0;
  String _downloadProgressText = '';

  @override
  void initState() {
    super.initState();
    _refreshDiscover();
  }

  void _refreshDiscover() {
    if (!mounted) return;
    setState(() {
      _hasCheckedMedia = false;
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

  Future<void> _checkAndPreloadMedia(List<DiscoverItem> items) async {
    final urls = items
        .map((item) => item.imageUrl?.trim())
        .whereType<String>()
        .where((url) =>
            url.isNotEmpty &&
            (url.startsWith('http://') || url.startsWith('https://')))
        .toSet();

    if (urls.isEmpty || !mounted) return;

    final uncachedUrls =
        await MediaPreloadService.filterUncachedUrls(urls);
    if (uncachedUrls.isEmpty || !mounted) return;

    final totalBytes =
        await MediaPreloadService.getEstimatedTotalBytes(uncachedUrls);
    final formattedSize = MediaPreloadService.formatBytes(totalBytes);

    if (!mounted) return;

    final shouldDownload = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.cloud_download_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'ดาวน์โหลดเนื้อหาเพิ่มเติม',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'หน้า Discover มีไฟล์รูปภาพเพิ่มเติมประมาณ $formattedSize (${uncachedUrls.length} รายการ)\n\nคุณต้องการดาวน์โหลดไว้ล่วงหน้าเพื่อการใช้งานที่ราบรื่นหรือไม่?',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actionsPadding:
            const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      'ดาวน์โหลด',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.grey.shade200
                              : Colors.grey.shade800,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      'กลับ',
                      style: TextStyle(
                        color:
                            Theme.of(context).brightness == Brightness.light
                                ? Colors.black87
                                : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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

    if (shouldDownload == true && mounted) {
      setState(() {
        _isDownloadingMedia = true;
        _downloadProgress = 0.0;
        _downloadProgressText = 'กำลังเตรียมดาวน์โหลด...';
      });

      await MediaPreloadService.preloadImages(
        uncachedUrls,
        context,
        onProgress: (completed, total) {
          if (!mounted) return;
          setState(() {
            _downloadProgress = total > 0 ? completed / total : 1.0;
            _downloadProgressText =
                'ดาวน์โหลดรูปภาพ $completed / $total รายการ...';
          });
        },
      );

      if (mounted) {
        setState(() {
          _isDownloadingMedia = false;
        });
      }
    }
  }

  Widget _buildDownloadingWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.downloading_rounded,
              size: 64,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              "กำลังดาวน์โหลดเนื้อหา...",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _downloadProgressText,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.lightTextColor,
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _downloadProgress,
                minHeight: 10,
                backgroundColor: AppTheme.primaryColor.withValues(
                  alpha: 0.15,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(_downloadProgress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDownloadingMedia) {
      return Scaffold(
        appBar: const ThaiAppBar(title: "Discover"),
        body: _buildDownloadingWidget(),
      );
    }

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

                if (!_hasCheckedMedia && items.isNotEmpty) {
                  _hasCheckedMedia = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _checkAndPreloadMedia(items);
                  });
                }

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
