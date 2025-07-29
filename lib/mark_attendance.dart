import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MarkAttendancePage extends StatefulWidget {
  const MarkAttendancePage({super.key});

  @override
  State<MarkAttendancePage> createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? selectedSubjectCode;
  String? selectedSubjectName;
  List<Map<String, String>> subjects = [];
  List<Map<String, String>> students = [];
  final Map<String, bool> attendanceStatus = {};

  String? branchId;
  String? sectionId;

  bool isLoading = true;
  String classStatus = 'conducted';
  String overrideStatus = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final studentQuery = await _firestore
          .collection('students')
          .where('email', isEqualTo: user.email)
          .get();
      if (studentQuery.docs.isEmpty) return;

      final studentData = studentQuery.docs.first.data();
      branchId = studentData['branchId'] as String?;
      sectionId = studentData['sectionId'] as String?;
      if (branchId == null || sectionId == null) return;

      final subjectsSnap = await _firestore
          .collection('branches')
          .doc(branchId)
          .collection('sections')
          .doc(sectionId)
          .collection('subjects')
          .get();

      subjects = subjectsSnap.docs.map((doc) {
        final data = doc.data();
        final code = doc.id;
        final name = (data['subjectName'] as String?) ?? code;
        return {'subjectCode': code, 'subjectName': name};
      }).toList();

      if (subjects.isNotEmpty) {
        selectedSubjectCode = subjects.first['subjectCode'];
        selectedSubjectName = subjects.first['subjectName'];
      }

      final studentsSnap = await _firestore
          .collection('students')
          .where('branchId', isEqualTo: branchId)
          .where('sectionId', isEqualTo: sectionId)
          .get();

      students = studentsSnap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] as String? ?? 'Unknown',
          'roll': data['rollNo'] as String? ?? 'N/A',
        };
      }).toList();

      for (var s in students) {
        attendanceStatus[s['id']!] = true;
      }

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  void markAll(bool isPresent) {
    setState(() {
      classStatus = 'conducted';
      overrideStatus = isPresent ? '' : 'bunked';
      attendanceStatus.updateAll((key, value) => isPresent);
    });
  }

  void markClassCancelled() {
    setState(() {
      classStatus = 'cancelled';
      overrideStatus = 'cancelled';
      attendanceStatus.updateAll((key, value) => false);
    });
  }

  Future<void> publishAttendance() async {
    if (selectedSubjectCode == null || selectedSubjectName == null) return;

    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final docId = '${selectedSubjectCode}_$dateStr';

    final batch = _firestore.batch();

    for (var student in students) {
      final id = student['id']!;
      final status = overrideStatus.isNotEmpty
          ? overrideStatus
          : (attendanceStatus[id]! ? 'present' : 'absent');

      final docRef = _firestore
          .collection('students')
          .doc(id)
          .collection('attendance')
          .doc(docId);

      batch.set(docRef, {
        'date': dateStr,
        'lectureSlotId': docId,
        'subjectCode': selectedSubjectCode,
        'subjectName': selectedSubjectName,
        'status': status,
        'held': classStatus,
        'recordedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Attendance published successfully!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;
    final padding = isWide
        ? EdgeInsets.symmetric(horizontal: width * 0.15, vertical: 24)
        : const EdgeInsets.all(16.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Subject',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedSubjectCode,
              decoration: InputDecoration(
                labelText: "Subject",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                final subj = subjects.firstWhere((s) => s['subjectCode'] == value);
                setState(() {
                  selectedSubjectCode = subj['subjectCode'];
                  selectedSubjectName = subj['subjectName'];
                });
              },
              items: subjects
                  .map(
                    (subj) => DropdownMenuItem<String>(
                  value: subj['subjectCode'],
                  child: Text(subj['subjectName']!,
                      style: theme.textTheme.bodyMedium),
                ),
              )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: markClassCancelled,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.errorContainer,
                    foregroundColor: theme.colorScheme.onErrorContainer,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Class Cancelled',
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onErrorContainer)),
                ),
                ElevatedButton(
                  onPressed: () => markAll(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Class Bunked',
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onError)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Student List',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: students.isEmpty
                  ? Center(child: Text('No students found.', style: theme.textTheme.bodyMedium))
                  : ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  final id = student['id']!;
                  return ListTile(
                    leading: Icon(Icons.person, color: theme.iconTheme.color),
                    title: Text(student['name']!, style: theme.textTheme.bodyMedium),
                    subtitle: Text(student['roll']!, style: theme.textTheme.bodySmall),
                    trailing: Switch(
                      value: attendanceStatus[id]!,
                      onChanged: (val) => setState(() => attendanceStatus[id] = val),
                      activeColor: theme.colorScheme.primary,
                      trackColor: MaterialStateProperty.all(
                        theme.colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: publishAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Publish Attendance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
