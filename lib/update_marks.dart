// No change in imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UpdateMarksPage extends StatefulWidget {
  const UpdateMarksPage({super.key});

  @override
  State<UpdateMarksPage> createState() => _UpdateMarksPageState();
}

class _UpdateMarksPageState extends State<UpdateMarksPage> {
  String? selectedSubject;
  String? selectedExamType;

  List<Map<String, String>> subjects = [];
  final List<String> examTypes = ["MTE", "ETE", "Class Test 1", "Class Test 2"];

  List<QueryDocumentSnapshot<Map<String, dynamic>>> students = [];
  bool isLoading = true;

  final Map<String, TextEditingController> _marksControllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final subSnap = await FirebaseFirestore.instance
          .collection('branches')
          .doc('MCE')
          .collection('sections')
          .doc('B05')
          .collection('subjects')
          .get();

      subjects = subSnap.docs
          .map((doc) => {
        'code': doc['subjectCode'] as String,
        'name': doc['subjectName'] as String,
      })
          .toList();

      if (subjects.isNotEmpty) selectedSubject = subjects.first['code'];
      if (examTypes.isNotEmpty) selectedExamType = examTypes.first;

      final stuSnap = await FirebaseFirestore.instance
          .collection('students')
          .where('branchId', isEqualTo: 'MCE')
          .where('sectionId', isEqualTo: 'B05')
          .where('enrolledYear', isEqualTo: 2024)
          .get();

      students = stuSnap.docs;

      for (var doc in students) {
        _marksControllers[doc.id] = TextEditingController();
      }

      setState(() => isLoading = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}')),
      );
      setState(() => isLoading = false);
    }
  }

  Widget _buildMarksField(String studentId) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 60, maxWidth: 100),
      child: IntrinsicWidth(
        child: SizedBox(
          height: 48,
          child: TextField(
            controller: _marksControllers[studentId],
            decoration: InputDecoration(
              hintText: 'Marks',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> data, ThemeData theme, String studentId) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? '-', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Roll No: ${data['rollNo'] ?? '-'}', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildMarksField(studentId),
          ],
        ),
      ),
    );
  }

  Future<void> _publishMarks() async {
    if (selectedSubject == null || selectedExamType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select subject and exam type')),
      );
      return;
    }

    final examField = switch (selectedExamType) {
      'MTE' => 'midSem',
      'ETE' => 'endSem',
      'Class Test 1' => 'ct1',
      'Class Test 2' => 'ct2',
      _ => null,
    };

    if (examField == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid exam type')),
      );
      return;
    }

    final batch = FirebaseFirestore.instance.batch();
    int updatesCount = 0;

    for (var doc in students) {
      final studentDocId = doc.id;
      final txt = _marksControllers[studentDocId]?.text;
      if (txt == null || txt.isEmpty) continue;

      final marks = int.tryParse(txt);
      if (marks == null || marks < 0 || marks > 100) continue;

      final data = doc.data();
      final rollNo = data['rollNo'];
      final semester = data['semester'];
      if (rollNo == null || semester == null) continue;

      final ref = FirebaseFirestore.instance
          .collection('students')
          .doc(studentDocId)
          .collection('performance')
          .doc(semester.toString())
          .collection('subjects')
          .doc(selectedSubject);

      batch.set(ref, {
        'subjectCode': selectedSubject,
        examField: marks,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      updatesCount++;
    }

    if (updatesCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid marks to update')),
      );
      return;
    }

    try {
      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated $updatesCount records successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Update Marks'),
        centerTitle: true,
      ),

      body: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final horizontalPadding = isWide ? constraints.maxWidth * 0.15 : 16.0;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Subject', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedSubject,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (val) => setState(() => selectedSubject = val),
                items: subjects
                    .map((subj) => DropdownMenuItem(
                  value: subj['code'],
                  child: Text(subj['name']!),
                ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text('Exam Type', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: examTypes.map((type) {
                  final selected = selectedExamType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: selected,
                    onSelected: (_) => setState(() => selectedExamType = type),
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surface,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: selected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ...students.map((doc) => _buildStudentCard(doc.data(), theme, doc.id)),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: isWide ? 300 : double.infinity,
                  child: ElevatedButton(
                    onPressed: _publishMarks,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Publish Marks'),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    for (var c in _marksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
