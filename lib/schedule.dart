import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final String branchId = 'MCE';
  final String sectionId = 'B05';

  Map<String, List<Map<String, dynamic>>> timetable = {};
  String selectedDay = 'Monday';
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    setTodayAsDefault();
    loadTimetable();
  }

  void setTodayAsDefault() {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    selectedDay = (now.weekday >= 1 && now.weekday <= 5)
        ? weekdays[now.weekday - 1]
        : 'Monday';
  }

  Future<void> loadTimetable({bool forceRefresh = false}) async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'timetable_${branchId}_$sectionId';

      if (!forceRefresh) {
        final raw = prefs.getString(cacheKey);
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          timetable = decoded.map(
            (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v as List)),
          );
          setState(() => isLoading = false);
          return;
        }
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('branches')
          .doc(branchId)
          .collection('sections')
          .doc(sectionId)
          .collection('timetable')
          .get();

      final parsed = <String, List<Map<String, dynamic>>>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['classes'] is List) {
          parsed[doc.id] = List<Map<String, dynamic>>.from(
            data['classes'] as List,
          );
        }
      }

      timetable = parsed;
      await prefs.setString(cacheKey, jsonEncode(parsed));
      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Widget dayChip(String day) {
    final isSelected = selectedDay == day;
    final textSize = MediaQuery.of(context).size.width * 0.035;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(
          day,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: textSize,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        selected: isSelected,
        showCheckmark: false,
        selectedColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        onSelected: (_) => setState(() => selectedDay = day),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = screenWidth < 400 ? 12.0 : 16.0;
    final todaySchedule = timetable[selectedDay];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Timetable'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh timetable',
            onPressed: () => loadTimetable(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
              ].map((day) => dayChip(day)).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : hasError
                ? const Center(child: Text("Something went wrong."))
                : todaySchedule == null
                ? const Center(child: Text("No timetable available."))
                : todaySchedule.isEmpty
                ? const Center(child: Text("No classes today."))
                : ListView.builder(
                    itemCount: todaySchedule.length,
                    itemBuilder: (context, index) {
                      final item = todaySchedule[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardPadding,
                          vertical: 6,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final iconSize = constraints.maxWidth * 0.06;
                            final titleSize = constraints.maxWidth * 0.05;
                            final labelSize = constraints.maxWidth * 0.04;
                            return Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.shadow
                                        .withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          flex: 2,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.menu_book_rounded,
                                                size: iconSize,
                                                color: Theme.of(
                                                  context,
                                                ).iconTheme.color,
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  item['subjectFullName'] ??
                                                      item['subjectName'] ??
                                                      'Unknown Subject',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontSize: titleSize,
                                                      ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Flexible(
                                          flex: 1,
                                          child: ElevatedButton.icon(
                                            onPressed: () => showDialog(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: const Text('Syllabus'),
                                                content: const Text(
                                                  'Syllabus view coming soon...',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text('Close'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            icon: Icon(
                                              Icons.book_outlined,
                                              size: labelSize,
                                            ),
                                            label: Text(
                                              "Syllabus",
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge
                                                  ?.copyWith(
                                                    fontSize: labelSize,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onPrimary,
                                                  ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    constraints.maxWidth * 0.03,
                                                vertical:
                                                    constraints.maxWidth *
                                                    0.015,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _infoRow(
                                      icon: Icons.code,
                                      text:
                                          "Code: ${item['subjectCode'] ?? '-'}",
                                      iconSize: iconSize,
                                      textSize: labelSize,
                                    ),
                                    const SizedBox(height: 4),
                                    _infoRow(
                                      icon: Icons.person,
                                      text:
                                          "Teacher: ${item['faculty'] ?? 'TBA'}",
                                      iconSize: iconSize,
                                      textSize: labelSize,
                                    ),
                                    const SizedBox(height: 4),
                                    _infoRow(
                                      icon: Icons.room,
                                      text: "Room: ${item['venue'] ?? '-'}",
                                      iconSize: iconSize,
                                      textSize: labelSize,
                                    ),
                                    const SizedBox(height: 4),
                                    _infoRow(
                                      icon: Icons.access_time,
                                      text:
                                          "Time: ${item['startTime']} - ${item['endTime']}",
                                      iconSize: iconSize,
                                      textSize: labelSize,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String text,
    required double iconSize,
    required double textSize,
  }) {
    return Row(
      children: [
        Icon(icon, size: iconSize),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: textSize),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
