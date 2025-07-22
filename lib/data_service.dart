import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the full student document (including branchId & sectionId)
  /// Attendance list under the student doc
  Future<Map<String, dynamic>?> fetchLoggedInStudentBaseData() async {
    try {
      // 1. Get current user email
      final user = _auth.currentUser;
      if (user?.email == null) {
        debugPrint('No authenticated user or email');
        return null;
      }

      // 2. Query students collection where email matches
      final query = await _firestore
          .collection('students')
          .where('email', isEqualTo: user!.email)
          .limit(1)
          .get();

      // 3. Check if we found a match
      if (query.docs.isEmpty) {
        debugPrint('No student found with email: ${user.email}');
        return null;
      }

      // 4. Get the first matching document
      final doc = query.docs.first;
      final data = doc.data();

      // 5. Validate required fields
      if (data['branchId'] == null || data['sectionId'] == null) {
        debugPrint('Student document missing required fields');
        return null;
      }

      return {'id': doc.id, ...data};
    } catch (e, stack) {
      debugPrint('Error fetching student by email: $e');
      debugPrint(stack.toString());
      return null;
    }
  }


  /// Attendance list under the student doc
  Future<List<Map<String, dynamic>>> fetchLoggedInStudentAttendance() async {
    try {
      final base = await fetchLoggedInStudentBaseData();
      if (base == null) {
        debugPrint('fetchLoggedInStudentAttendance: No student base data');
        return [];
      }

      final snap = await _firestore
          .collection('students')
          .doc(base['id'])
          .collection('attendance')
          .get();

      if (snap.docs.isEmpty) {
        debugPrint('fetchLoggedInStudentAttendance: No attendance records for student ${base['id']}');
      }

      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      print('Error fetching attendance: $e');
      return [];
    }
  }

  /// Performance subcollection
  Future<List<Map<String, dynamic>>> fetchLoggedInStudentPerformance() async {
    try {
      final base = await fetchLoggedInStudentBaseData();
      if (base == null) return [];

      final perfSnap = await _firestore
          .collection('students')
          .doc(base['id'])
          .collection('performance')
          .get();

      final results = await Future.wait(
        perfSnap.docs.map((sem) async {
          final subjects = await sem.reference
              .collection('subjects')
              .get()
              .then((s) => s.docs.map((d) => d.data()).toList());
          return {
            'semester': sem.id,
            ...sem.data(),
            'subjects': subjects,
          };
        }),
      );

      return results;
    } catch (e) {
      print('Error fetching performance: $e');
      return [];
    }
  }

  /// Timetable under branches/{branchId}/sections/{sectionId}/timetable
  Future<List<Map<String, dynamic>>> fetchTimetable(
      String branchId, String sectionId) async {
    try {
      final snap = await _firestore
          .collection('branches')
          .doc(branchId)
          .collection('sections')
          .doc(sectionId)
          .collection('timetable')
          .get();

      final list = <Map<String, dynamic>>[];
      for (var d in snap.docs) {
        final sched = d.data()['schedule'] as List<dynamic>? ?? [];
        for (var slot in sched) {
          if (slot is Map<String, dynamic>) {
            list.add({...slot, 'day': d.id});
          }
        }
      }
      return list;
    } catch (e) {
      print('Error fetching timetable: $e');
      return [];
    }
  }

  /// All subjects under a given branch/section
  Future<List<Map<String, dynamic>>> fetchSubjects(
      String branchId, String sectionId) async {
    try {
      final snap = await _firestore
          .collection('branches')
          .doc(branchId)
          .collection('sections')
          .doc(sectionId)
          .collection('subjects')
          .get();

      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      print('Error fetching subjects: $e');
      return [];
    }
  }

  /// Live stream of assignments for one subject
  Stream<List<Map<String, dynamic>>> fetchAssignmentsStream(
      String branchId, String sectionId, String subjectId) {
    try {
      return _firestore
          .collection('branches')
          .doc(branchId)
          .collection('sections')
          .doc(sectionId)
          .collection('subjects')
          .doc(subjectId)
          .collection('assignments')
          .orderBy('dueDate')
          .snapshots()
          .map((snap) => snap.docs.map((d) => d.data()).toList());
    } catch (e) {
      print('Error creating assignments stream: $e');
      return Stream.value([]);
    }
  }

  /// MVP events
  Stream<List<Map<String, dynamic>>> fetchEventsStream() {
    try {
      return _firestore
          .collection('events')
          .orderBy('dateTime')
          .snapshots()
          .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
    } catch (e) {
      print('Error creating events stream: $e');
      return Stream.value([]);
    }
  }

  /// Fetch assignments for a specific subject with due date filtering
  Future<List<Map<String, dynamic>>> fetchAssignmentsForSubject(
      String branchId,
      String sectionId,
      String subjectId,
      ) async {
    try {
      final now = Timestamp.now();
      final query = await _firestore
          .collection('branches')
          .doc(branchId)
          .collection('sections')
          .doc(sectionId)
          .collection('subjects')
          .doc(subjectId)
          .collection('assignments')
          .where('dueDate', isGreaterThanOrEqualTo: now)
          .orderBy('dueDate')
          .get();

      return query.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching assignments: $e');
      return [];
    }
  }

  /// Fetch notifications/alerts for the student's section
  Stream<List<Map<String, dynamic>>> fetchNotificationsStream() {
    try {
      final now = Timestamp.now();
      return _firestore
          .collection('notification')
          .where('timestamp', isGreaterThanOrEqualTo: now)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((d) => d.data()).toList());
    } catch (e) {
      print('Error creating notifications stream: $e');
      return Stream.value([]);
    }
  }

  /// Fetch CR details for a section
  Future<Map<String, dynamic>?> fetchCrDetails(
      String branchId, String sectionId) async {
    try {
      final doc = await _firestore
          .collection('branches')
          .doc(branchId)
          .collection('sections')
          .doc(sectionId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching CR details: $e');
      return null;
    }
  }
}