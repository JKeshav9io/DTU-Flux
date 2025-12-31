import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dtu_connect/pdf_image_viewer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late SharedPreferences _prefs;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isSearching = false; // NEW
  String _searchText = ''; // NEW

  StreamSubscription<QuerySnapshot>? _notifSub;
  StreamSubscription<QuerySnapshot>? _eventSub;

  late String _subscriptionTopic;
  late String _notificationsKey;
  late String _eventsKey;

  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _initPrefsAndRealtime();
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _eventSub?.cancel();
    super.dispose();
  }

  Future<void> _initPrefsAndRealtime() async {
    _prefs = await SharedPreferences.getInstance();

    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final studentQuery = await _firestore
        .collection('students')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();
    if (studentQuery.docs.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    final data = studentQuery.docs.first.data();
    final year = data['enrolledYear']?.toString() ?? '2024';
    final branchId = data['branchId']?.toString() ?? 'BR';
    final sectionId = data['sectionId']?.toString() ?? 'S1';

    _subscriptionTopic = '${year}_${branchId}_$sectionId';
    _notificationsKey = 'notifs_$_subscriptionTopic';
    _eventsKey = 'events_$_subscriptionTopic';

    _loadCache();
    _listenNotifications();
    _listenEvents();

    setState(() => _isLoading = false);
  }

  void _loadCache() {
    final notifsJson = _prefs.getString(_notificationsKey);
    if (notifsJson != null) {
      _notifications = (json.decode(notifsJson) as List)
          .cast<Map<String, dynamic>>();
    }
    final eventsJson = _prefs.getString(_eventsKey);
    if (eventsJson != null) {
      _events = (json.decode(eventsJson) as List).cast<Map<String, dynamic>>();
    }
  }

  void _listenNotifications() {
    _notifSub = _firestore
        .collection('notification')
        .doc(_subscriptionTopic)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) async {
          _notifications = snap.docs.map((doc) {
            final m = doc.data();
            final rawTs = m['timestamp'];
            DateTime ts;
            if (rawTs is Timestamp) {
              ts = rawTs.toDate();
            } else if (rawTs is int) {
              ts = DateTime.fromMillisecondsSinceEpoch(rawTs);
            } else if (rawTs is String) {
              ts = DateTime.tryParse(rawTs) ?? DateTime.now();
            } else {
              ts = DateTime.now();
            }
            return {
              'title': m['title'] ?? 'No Title',
              'body': m['body'] ?? '',
              'timestamp': ts.millisecondsSinceEpoch,
              'attachment': m['attachmentUrl'],
              'type': m['type'] ?? 'Custom Notification',
            };
          }).toList();

          await _prefs.setString(
            _notificationsKey,
            json.encode(_notifications),
          );
          if (mounted) setState(() {});
        });
  }

  void _listenEvents() {
    _eventSub = _firestore
        .collection('notification')
        .doc('events')
        .collection('history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) async {
          _events = snap.docs.map((doc) {
            final m = doc.data();
            final rawTs = m['timestamp'];
            DateTime ts;
            if (rawTs is Timestamp) {
              ts = rawTs.toDate();
            } else if (rawTs is int) {
              ts = DateTime.fromMillisecondsSinceEpoch(rawTs);
            } else if (rawTs is String) {
              ts = DateTime.tryParse(rawTs) ?? DateTime.now();
            } else {
              ts = DateTime.now();
            }
            return {
              'id': doc.id,
              'title': m['title'] ?? 'No Title',
              'body': m['body'] ?? '',
              'timestamp': ts.millisecondsSinceEpoch,
              'type': 'event',
              'attachment': m['attachmentUrl'],
            };
          }).toList();

          await _prefs.setString(_eventsKey, json.encode(_events));
          if (mounted) setState(() {});
        });
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.wait([
      _firestore
          .collection('notification')
          .doc(_subscriptionTopic)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .get()
          .then((_) {}),
      _firestore
          .collection('notification')
          .doc('events')
          .collection('history')
          .orderBy('timestamp', descending: true)
          .get()
          .then((_) {}),
    ]);
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;
    final padding = isWide
        ? EdgeInsets.symmetric(horizontal: screenWidth * 0.15, vertical: 24)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    // Combine and filter items
    final allItems = [..._notifications, ..._events];
    final filteredItems = _searchText.isEmpty
        ? allItems
        : allItems.where((i) {
            final title = (i['title'] as String).toLowerCase();
            final body = (i['body'] as String).toLowerCase();
            return title.contains(_searchText.toLowerCase()) ||
                body.contains(_searchText.toLowerCase());
          }).toList();

    // Group by date
    final dates =
        filteredItems
            .map((i) => DateTime.fromMillisecondsSinceEpoch(i['timestamp']))
            .map((d) => '${d.day}-${d.month}-${d.year}')
            .toSet()
            .toList()
          ..sort((a, b) {
            final pa = a.split('-').map(int.parse).toList();
            final pb = b.split('-').map(int.parse).toList();
            return DateTime(
              pb[2],
              pb[1],
              pb[0],
            ).compareTo(DateTime(pa[2], pa[1], pa[0]));
          });

    List<Map<String, dynamic>> itemsForDate(String label) {
      return filteredItems.where((i) {
        final d = DateTime.fromMillisecondsSinceEpoch(i['timestamp']);
        return '${d.day}-${d.month}-${d.year}' == label;
      }).toList()..sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    }

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search alerts…',
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchText = val),
              )
            : const Text('Alerts & Events'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) _searchText = '';
                _isSearching = !_isSearching;
              });
            },
          ),
          IconButton(
            icon: _isRefreshing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : Icon(Icons.refresh, color: theme.colorScheme.onPrimary),
            onPressed: _isRefreshing ? null : _onRefresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : filteredItems.isEmpty
          ? _buildEmptyState(theme)
          : RefreshIndicator(
              onRefresh: _onRefresh,
              color: theme.colorScheme.primary,
              child: ListView.builder(
                padding: padding,
                itemCount: dates
                    .map((d) => 1 + itemsForDate(d).length)
                    .fold<int>(0, (int sum, int len) => sum + len),
                itemBuilder: (_, idx) {
                  int cursor = 0;
                  for (var date in dates) {
                    if (idx == cursor) return _buildDateDivider(date, theme);
                    cursor++;
                    final items = itemsForDate(date);
                    for (var item in items) {
                      if (idx == cursor) return _buildCard(item, theme, isWide);
                      cursor++;
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.notifications_off,
          size: 60,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 16),
        Text('No alerts or events', style: theme.textTheme.titleMedium),
        TextButton(
          onPressed: _onRefresh,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            textStyle: theme.textTheme.labelLarge,
          ),
          child: const Text('Refresh'),
        ),
      ],
    ),
  );

  Widget _buildDateDivider(String date, ThemeData theme) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0),
    child: Row(
      children: [
        const Expanded(child: Divider()),
        Text(
          date,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const Expanded(child: Divider()),
      ],
    ),
  );

  Widget _buildCard(Map<String, dynamic> item, ThemeData theme, bool isWide) {
    IconData icon;
    switch (item['type']) {
      case 'Class Bunk':
        icon = Icons.notifications_active;
        break;
      case 'Class Cancellation':
        icon = Icons.cancel;
        break;
      case 'University Notification':
        icon = Icons.school;
        break;
      case 'Custom Notification':
        icon = Icons.settings;
        break;
      case 'assignment':
        icon = Icons.assignment;
        break;
      case 'event':
        icon = Icons.event;
        break;
      default:
        icon = Icons.notifications;
    }
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: isWide ? 8 : 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardColor,
      elevation: theme.cardTheme.elevation ?? 2,
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(
          item['title'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          item['body'],
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.iconTheme.color,
        ),
        onTap: () => _showDetailsDialog(item, theme),
      ),
    );
  }

  void _showDetailsDialog(Map<String, dynamic> item, ThemeData theme) {
    final ts = DateTime.fromMillisecondsSinceEpoch(item['timestamp']);
    final hasAttachment =
        item['attachment'] != null && item['attachment'].isNotEmpty;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(item['title'], style: theme.textTheme.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBodyContent(item['body'], item['attachment'], theme),
                const SizedBox(height: 12),
                Text(
                  'At ${ts.day}-${ts.month}-${ts.year} '
                  '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            if (hasAttachment)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FileViewerScreen(
                        fileUrl: item['attachment'],
                        fileName: Uri.parse(
                          item['attachment'],
                        ).pathSegments.last,
                      ),
                    ),
                  );
                },
                child: const Text('View Attachment'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                textStyle: theme.textTheme.labelLarge,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBodyContent(String body, String? attachment, ThemeData theme) {
    final urlRegex = RegExp(r"(https?://[\w\-\./?=&%]+)");
    final parts = body.split(urlRegex);
    final matches = urlRegex.allMatches(body).toList();
    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i], style: theme.textTheme.bodyMedium));
      if (i < matches.length) {
        final url = matches[i].group(0)!;
        spans.add(
          TextSpan(
            text: url,
            style: theme.textTheme.bodyMedium?.copyWith(
              decoration: TextDecoration.underline,
              color: theme.colorScheme.secondary,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () async => _launchURL(context, url),
          ),
        );
      }
    }
    if (attachment != null && attachment.isNotEmpty) {
      spans.add(const TextSpan(text: '\n'));
      spans.add(
        TextSpan(
          text: 'Attachment: ${Uri.parse(attachment).pathSegments.last}',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return RichText(
      text: TextSpan(style: theme.textTheme.bodyMedium, children: spans),
    );
  }
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
