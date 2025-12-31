// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'pdf_image_viewer.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  String branchId = 'MCE';
  String sectionId = 'B05';
  String? selectedSubject;
  List<String> subjects = [];

  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }

  Future<void> fetchSubjects() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('branches')
        .doc(branchId)
        .collection('sections')
        .doc(sectionId)
        .collection('subjects')
        .get();

    setState(() {
      subjects = snapshot.docs.map((doc) => doc.id).toList();
      if (subjects.isNotEmpty) {
        selectedSubject = subjects.first;
      }
    });
  }

  Stream<QuerySnapshot> assignmentStream(String? subject) {
    if (subject == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('branches')
        .doc(branchId)
        .collection('sections')
        .doc(sectionId)
        .collection('subjects')
        .doc(subject)
        .collection('assignments')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Assignments'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: assignmentStream(selectedSubject),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];

            final counts = {'Submitted': 0, 'Overdue': 0, 'Due Today': 0, 'Upcoming': 0};
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);

            final List<Map<String, dynamic>> assignments = [];

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final due = (data['dueDate'] as Timestamp?)?.toDate();
              final isSubmitted = data['isSubmitted'] ?? false;

              String status = '';

              if (isSubmitted) {
                counts['Submitted'] = counts['Submitted']! + 1;
                status = 'Submitted';
              } else if (due != null) {
                final dueLocal = due.toLocal();
                final dueDateOnly = DateTime(dueLocal.year, dueLocal.month, dueLocal.day);

                if (dueDateOnly.isBefore(today)) {
                  counts['Overdue'] = counts['Overdue']! + 1;
                  status = 'Overdue';
                } else if (dueDateOnly == today) {
                  counts['Due Today'] = counts['Due Today']! + 1;
                  status = 'Due Today';
                } else if (dueDateOnly.isAfter(today)) {
                  counts['Upcoming'] = counts['Upcoming']! + 1;
                  status = 'Upcoming';
                }
              }

              assignments.add({
                'data': data,
                'status': status,
                'dueStr': due != null
                    ? DateFormat('dd MMM yyyy').format(due.toLocal())
                    : 'No due date'
              });
            }

            return Column(
              children: [
                _statusCards(counts, theme),
                const SizedBox(height: 16),
                if (subjects.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: selectedSubject,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    isExpanded: true,
                    items: subjects
                        .map((subject) => DropdownMenuItem(value: subject, child: Text(subject)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSubject = value;
                      });
                    },
                  )
                else
                  const Text("No subjects found", style: TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                if (assignments.isEmpty)
                  const Expanded(
                    child: Center(child: Text("No assignments found")),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: assignments.length,
                      itemBuilder: (context, index) {
                        final data = assignments[index]['data'] as Map<String, dynamic>;
                        final status = assignments[index]['status'] as String;
                        final dueStr = assignments[index]['dueStr'] as String;
                        final title = data['title'] ?? 'Untitled';
                        final desc = data['description'] ?? 'No description';
                        final fileURL = data['fileURL'] ?? '';

                        return _assignmentCard(
                          context,
                          title: title,
                          desc: desc,
                          dueDate: dueStr,
                          fileURL: fileURL,
                          status: status,
                          theme: theme,
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statusCards(Map<String, int> counts, ThemeData theme) {
    final colors = {
      'Submitted': theme.colorScheme.secondaryContainer,
      'Overdue': Colors.red.shade100,
      'Due Today': Colors.orange.shade100,
      'Upcoming': Colors.green.shade100,
    };
    final textColors = {
      'Submitted': theme.colorScheme.onSecondaryContainer,
      'Overdue': Colors.red.shade900,
      'Due Today': Colors.orange.shade900,
      'Upcoming': Colors.green.shade900,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: counts.entries.map((entry) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors[entry.key],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(entry.key,
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColors[entry.key])),
                const SizedBox(height: 5),
                Text('${entry.value}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColors[entry.key])),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _assignmentCard(
      BuildContext context, {
        required String title,
        required String desc,
        required String dueDate,
        required String fileURL,
        required String status,
        required ThemeData theme,
      }) {
    final statusColor = status == 'Submitted'
        ? Colors.blue
        : status == 'Overdue'
        ? Colors.red
        : status == 'Due Today'
        ? Colors.orange
        : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 5),
            Text(desc, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 5),
            Text('Due: $dueDate', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FileViewerScreen(fileUrl: fileURL, fileName: "$title.pdf"),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Add solution upload or view logic
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('View Solution'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

