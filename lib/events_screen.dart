import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();

  static String _formatDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute';
    }
    return timestamp?.toString() ?? '';
  }
}

class _EventsScreenState extends State<EventsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;
    final horizontalPadding = isWide ? screenWidth * 0.15 : 16.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Events'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('dateTime')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildMessage(context, 'Something went wrong');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return _buildMessage(context, 'No events found');

          final mvpList = docs.where((d) => d['isMVP'] == true).toList();
          final featuredList = docs.where((d) => d['isMVP'] != true).toList();

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24,
            ),
            children: [
              if (mvpList.isNotEmpty)
                _buildBanner(context, mvpList.first, theme, isWide),
              const SizedBox(height: 12),
              Text(
                'Featured Events',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...featuredList.map((d) => _buildCard(context, d, theme, isWide)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessage(BuildContext context, String msg) {
    final theme = Theme.of(context);
    return Center(child: Text(msg, style: theme.textTheme.titleMedium));
  }

  Widget _buildBanner(
    BuildContext context,
    QueryDocumentSnapshot data,
    ThemeData theme,
    bool isWide,
  ) {
    final map = data.data() as Map<String, dynamic>;
    final url = map['link'] as String?;
    final dateTimeText = EventsScreen._formatDateTime(map['dateTime']);
    final location = map['location'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: isWide ? 21 / 9 : 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                map['imageURL'] ?? '',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Shimmer.fromColors(
                    baseColor: theme.cardColor,
                    highlightColor: theme.dividerColor,
                    child: Container(color: theme.cardColor),
                  );
                },
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 40,
                    color: theme.disabledColor,
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        map['eventName'] ?? '',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          shadows: [
                            const Shadow(
                              blurRadius: 3,
                              color: Colors.black45,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dateTimeText  •  $location',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _launchURL(context, url),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Register Now'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    QueryDocumentSnapshot data,
    ThemeData theme,
    bool isWide,
  ) {
    final map = data.data() as Map<String, dynamic>;
    final title = map['eventName'] as String? ?? '';
    final desc = map['description'] as String? ?? '';
    final dateTimeText = EventsScreen._formatDateTime(map['dateTime']);
    final url = map['link'] as String?;

    return GestureDetector(
      onTap: () => _launchURL(context, url),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        color: theme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.surface,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    map['imageURL'] ?? '',
                    width: isWide ? 140 : 100,
                    height: isWide ? 140 : 100,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Shimmer.fromColors(
                        baseColor: theme.cardColor,
                        highlightColor: theme.dividerColor,
                        child: Container(
                          width: isWide ? 140 : 100,
                          height: isWide ? 140 : 100,
                          color: theme.cardColor,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: theme.disabledColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            dateTimeText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchURL(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      _showSnack(context, 'No link provided');
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnack(context, 'Invalid URL');
      return;
    }

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) _showSnack(context, 'Could not launch');
      }
    } catch (_) {
      if (context.mounted) _showSnack(context, 'Error opening link');
    }
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
