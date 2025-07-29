import 'dart:convert';

import 'package:dtu_connect/pdf_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:dtu_connect/schedule.dart';
import 'package:dtu_connect/alerts.dart';
import 'package:dtu_connect/assignment.dart';
import 'package:dtu_connect/attendance.dart';
import 'package:dtu_connect/events_screen.dart';
import 'package:dtu_connect/profile.dart';
import 'package:dtu_connect/academic_performance.dart';
import 'cr_panel.dart';
import 'package:dtu_connect/data_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';


class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  bool isLoading = true;
  Map<String, dynamic>? _student;
  final DataService _dataService = DataService();
  //NotificationServices.requestNotificationPermissions();

  @override
  void initState() {
    super.initState();
    loadStudentData();
  }


  Future<void> loadStudentData() async {
    setState(() {
      isLoading = true;
      _student = null;
    });
    try {
      final data = await _dataService.fetchLoggedInStudentBaseData();
      setState(() {
        _student = data;
        isLoading = false;
      });
      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load student data')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        _student = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  List<Widget> get _screens {
    if (_student == null) {
      // Always return a loading/fallback widget if student is not loaded
      return [
        const DashboardShimmer(),
      ];
    }
    return [
      HomeScreen(student: _student!),
      AcademicPerformanceScreen(studentId: _student!['id']),
      EventsScreen(),
      AlertsScreen(),
      ProfilePage(studentData: _student!),
    ];
  }

  String _formatStudentName(String name) {
    final parts = name.trim().split(' ');
    if (parts.length <= 2) return name;
    final initials = parts.sublist(0, parts.length - 1).map((p) => '${p[0].toUpperCase()}.').join();
    return '$initials ${parts.last}';
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final student = _student;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: _selectedIndex == 0
          ? AppBar(
              title: isLoading || student == null
                  ? const SizedBox(height: 20, child: CircularProgressIndicator())
                  : Text(
                      'Welcome, ${_formatStudentName(student['name'] ?? '')}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
              backgroundColor: theme.colorScheme.primary,
              iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
              elevation: 0,
              leading: (_student != null && student?['photoURL'] != null)
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(student?['photoURL']),
                      ),
                    )
                  : const CircleAvatar(
                      child: Icon(Icons.account_circle),
                    ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CrPanel()));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
                  },
                ),
              ],
            )
          : null,
      body: isLoading
          ? const DashboardShimmer()
          : LayoutBuilder(
              builder: (context, constraints) {
                // Responsive: Use Row for wide screens, Column for mobile/tablet
                if (isWide) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          color: theme.colorScheme.surface,
                          child: _screens[_selectedIndex],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          color: theme.colorScheme.background,
                          child: ProfilePage(studentData: student!),
                        ),
                      ),
                    ],
                  );
                } else {
                  return _screens[_selectedIndex];
                }
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.5),
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Academics'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic> student;
  const HomeScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;
    final crossAxisCount = isWide ? 8 : isTablet ? 6 : 4;
    final branchId = student['branchId'];
    final sectionId = student['sectionId'];
    final studentId = student['id'] ?? '';

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? screenWidth * 0.1 : 16.0,
        vertical: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Responsive row for cards
          Row(
            children: [
              Expanded(
                child: TodayAttendanceCard(studentId: studentId),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: NextClassCard(branchId: branchId, sectionId: sectionId),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text("Quick Actions", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: crossAxisCount,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: isWide ? 1.2 : 1,
            children: [
              _quickActionButton(context, Icons.check, "Attendance", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => Attendance()));
              }),
              _quickActionButton(context, Icons.assignment, "Assignment", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentScreen()));
              }),
              _quickActionButton(context, Icons.schedule, "Schedule", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableScreen()));
              }),
              _quickActionButton(context, Icons.event, "Events", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()));
              }),
            ],
          ),
          const SizedBox(height: 20),
          Text("Upcoming Assignments", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          UpcomingAssignmentsCard(branchId: branchId, sectionId: sectionId),
          const SizedBox(height: 20),
          Text("Campus Events", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          CampusEventsCard(),
        ],
      ),
    );
  }
}

// Today's Attendance Card
class TodayAttendanceCard extends StatelessWidget {
  final String studentId;
  const TodayAttendanceCard({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = DataService();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (studentId.isEmpty) {
      return _infoCard(context, title: "Today's Attendance", value: "No student ID", progress: 0, valueColor: Colors.red);
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: dataService.fetchLoggedInStudentAttendance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _infoCard(context, title: "Today's Attendance", value: "Loading...", progress: 0, valueColor: Colors.green);
        }
        if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load attendance')),
            );
          });
          return _infoCard(context, title: "Today's Attendance", value: "Error", progress: 0, valueColor: Colors.red);
        }

        final allTodayHeld = snapshot.data?.where((a) =>
          a['date'] == today && a['held'] == 'conducted'
        ).toList() ?? [];

        final presentToday = allTodayHeld.where((a) => a['status'] == 'present').toList();

        final totalHeld = allTodayHeld.length;
        final totalPresent = presentToday.length;

        if (totalHeld == 0) {
          return _infoCard(context, title: "Today's Attendance", value: "No class", progress: 0, valueColor: Colors.grey);
        }

        final percent = totalPresent / totalHeld;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.brightness == Brightness.light
                  ? Colors.grey.shade300
                  : Colors.grey.shade700,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's Attendance", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: theme.dividerColor,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${(percent * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Next Class Card
class NextClassCard extends StatelessWidget {
  final String branchId;
  final String sectionId;
  const NextClassCard({super.key, required this.branchId, required this.sectionId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = DataService();
    final now = DateTime.now();
    final todayName = DateFormat('EEEE').format(now);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: dataService.fetchTimetable(branchId, sectionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _nextClassCard(context, time: "", subject: "");
        }
        if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load timetable')),
            );
          });
          return _nextClassCard(context, time: "Error", subject: "");
        }
        final todaySlots = snapshot.data?.where((slot) => slot['day'] == todayName).toList() ?? [];
        final nowTime = TimeOfDay.fromDateTime(now);
        Map<String, dynamic>? nextClass;
        for (var slot in todaySlots) {
          final start = slot['startTime'] ?? '';
          final startTime = _parseTimeOfDay(start);
          if (startTime != null && _isAfter(nowTime, startTime)) {
            nextClass = slot;
            break;
          }
        }
        if (nextClass == null) {
          return _nextClassCard(context, time: "No upcoming class", subject: "");
        }
        final formattedTime = nextClass['startTime'] ?? '';
        final subject = nextClass['subject'] ?? '';
        return _nextClassCard(context, time: formattedTime, subject: subject);
      },
    );
  }

  TimeOfDay? _parseTimeOfDay(String? timeStr) {
    if (timeStr == null) return null;
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  bool _isAfter(TimeOfDay now, TimeOfDay slot) {
    return now.hour < slot.hour || (now.hour == slot.hour && now.minute < slot.minute);
  }
}

// Upcoming Assignments Card
class UpcomingAssignmentsCard extends StatelessWidget {
  final String branchId;
  final String sectionId;
  const UpcomingAssignmentsCard({super.key, required this.branchId, required this.sectionId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = DataService();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: dataService.fetchSubjects(branchId, sectionId),
      builder: (context, subjectSnap) {
        if (subjectSnap.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              _assignmentCard(context, title: "", due: ""),
              _assignmentCard(context, title: "", due: ""),
            ],
          );
        }
        if (subjectSnap.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load subjects')),
            );
          });
          return _assignmentCard(context, title: "Error", due: "");
        }
        final subjects = subjectSnap.data ?? [];
        if (subjects.isEmpty) {
          return _assignmentCard(context, title: "No subjects found", due: "");
        }
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchUpcomingAssignments(dataService, branchId, sectionId, subjects),
          builder: (context, assignSnap) {
            if (assignSnap.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  _assignmentCard(context, title: "", due: ""),
                  _assignmentCard(context, title: "", due: ""),
                ],
              );
            }
            if (assignSnap.hasError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to load assignments')),
                );
              });
              return _assignmentCard(context, title: "Error", due: "");
            }
            final assignments = assignSnap.data ?? [];
            if (assignments.isEmpty) {
              return _assignmentCard(context, title: "No upcoming assignments", due: "");
            }
            return Column(
              children: assignments.take(2).map((a) {
                final subjectName = a['subjectName'] ?? '';
                final title = a['title'] ?? '';
                final dueDate = a['dueDate'];
                String formattedDue = '';
                if (dueDate != null) {
                  if (dueDate is Timestamp) {
                    formattedDue = DateFormat.yMMMMd().add_jm().format(dueDate.toDate());
                  } else if (dueDate is DateTime) {
                    formattedDue = DateFormat.yMMMMd().add_jm().format(dueDate);
                  } else if (dueDate is String) {
                    formattedDue = dueDate;
                  }
                }
                return _assignmentCard(
                  context,
                  title: '$subjectName: $title',
                  due: formattedDue,
                  fileUrl: a['fileURL'],
                  fileName: title,
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchUpcomingAssignments(
      DataService dataService,
      String branchId,
      String sectionId,
      List<Map<String, dynamic>> subjects,
      ) async {
    final now = DateTime.now();
    List<Map<String, dynamic>> allAssignments = [];
    for (var subj in subjects) {
      final subjectId = subj['id'];
      final assigns = await dataService.fetchAssignmentsForSubject(branchId, sectionId, subjectId);
      for (var a in assigns) {
        if (a['dueDate'] != null && (a['dueDate'] as Timestamp).toDate().isAfter(now)) {
          allAssignments.add({...a, 'subjectName': subj['subjectName'] ?? subj['id']});
        }
      }
    }
    allAssignments.sort((a, b) => (a['dueDate'] as Timestamp).compareTo(b['dueDate'] as Timestamp));
    return allAssignments;
  }
}


class CampusEventsCard extends StatefulWidget {
  const CampusEventsCard({super.key});

  @override
  State<CampusEventsCard> createState() => _CampusEventsCardState();
}

class _CampusEventsCardState extends State<CampusEventsCard> {
  List<Map<String, dynamic>> events = [];

  get http => null;

  @override
  void initState() {
    super.initState();
    fetchEventData();
  }

  Future<void> fetchEventData() async {
    try {
      final eventQuery = await FirebaseFirestore.instance
          .collection("events")
          .orderBy("timestamp", descending: true)
          .limit(1)
          .get();

      if (eventQuery.docs.isNotEmpty) {
        final event = eventQuery.docs.first.data();
        final url = event["url"] ?? "";

        if (url.isNotEmpty) {
          final uri = Uri.parse(url);
          final response = await http.get(uri);

          if (response.statusCode == 200) {
            final jsonData = jsonDecode(response.body);
            final items = jsonData["items"] as List<dynamic>?;

            if (items != null && items.isNotEmpty) {
              final List<Map<String, dynamic>> filtered = items
                  .where((e) =>
              (e["summary"] as String?)?.toLowerCase().contains("mvp") ?? false)
                  .map((e) => {
                "title": e["summary"] ?? "",
                "date": e["start"]["date"] ?? "",
              })
                  .toList();

              if (mounted) {
                setState(() {
                  events = filtered;
                });
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching events: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        events.isEmpty
            ? _eventCard(
          context,
          imageUrl: "",
          title: "",
          date: "",
        )
            : _eventCard(
          context,
          imageUrl: "https://img.freepik.com/free-vector/flat-design-illustration-people-joining-online-webinar_23-2149171184.jpg",
          title: events[0]["title"] ?? "",
          date: events[0]["date"] ?? "",
        ),
      ],
    );
  }

  Widget _eventCard(
      BuildContext context, {
        required String imageUrl,
        required String title,
        required String date,
      }) {
    final theme = Theme.of(context);
    final isEmpty = title.trim().isEmpty;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isEmpty && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.image_not_supported)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: isEmpty
                ? Row(
              children: [
                const Icon(Icons.event_busy, size: 40, color: Colors.grey),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("No MVP Events",
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        "Stay tuned! Upcoming campus events will appear here soon.",
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
              ],
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(date,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


Widget _infoCard(BuildContext context,
    {required String title, required String value, required double progress, required Color valueColor}) {
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: theme.brightness == Brightness.light
            ? Colors.grey.shade300
            : Colors.grey.shade700,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.dividerColor,
                color: valueColor,
              ),
            ),
            const SizedBox(width: 5),
            Text(value, style: theme.textTheme.bodyMedium?.copyWith(color: valueColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    ),
  );
}

Widget _nextClassCard(BuildContext context, {required String time, required String subject}) {
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: theme.brightness == Brightness.light
            ? Colors.grey.shade300
            : Colors.grey.shade700,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Next Class", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(time, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(subject, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
      ],
    ),
  );
}

Widget _quickActionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
  final theme = Theme.of(context);
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.brightness == Brightness.light
                  ? Colors.grey.shade300
                  : Colors.grey.shade700,
            ),
          ),
          child: Icon(icon, size: 30, color: theme.iconTheme.color),
        ),
        const SizedBox(height: 5),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    ),
  );
}

Widget _eventCard(BuildContext context, {required String imageUrl, required String title, required String date}) {
  final theme = Theme.of(context);
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(imageUrl, width: double.infinity, height: 200, fit: BoxFit.cover),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(date, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
            ],
          ),
        ),
      ],
    ),
  );
}

// Add this outside any class, near other top-level widget functions
Widget _assignmentCard(BuildContext context, {required String title, required String due, String? fileUrl, String? fileName}) {
  final theme = Theme.of(context);
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
      subtitle: Text("Due: $due", style: theme.textTheme.bodySmall),
      trailing: ElevatedButton(
        onPressed: fileUrl != null && fileName != null
            ? () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FileViewerScreen(fileUrl: fileUrl, fileName: "${fileName}.pdf")),
          );
        }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text("Submit", style: TextStyle(color: Colors.white)),
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
      _showSnack(context, 'Could not launch');
    }
  } catch (_) {
    _showSnack(context, 'Error opening link');
  }
}

void _showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg)),
  );
}


class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 600;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _shimmerCard(theme)),
              if (isWide) const SizedBox(width: 10),
              Expanded(child: _shimmerCard(theme)),
            ],
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: theme.cardColor,
            highlightColor: theme.dividerColor,
            child: Container(
              height: 24,
              width: 120,
              color: theme.cardColor,
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: isWide ? 6 : 4,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: List.generate(isWide ? 6 : 4, (i) => _shimmerQuickAction(theme)),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: theme.cardColor,
            highlightColor: theme.dividerColor,
            child: Container(
              height: 24,
              width: 180,
              color: theme.cardColor,
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          const SizedBox(height: 10),
          _shimmerAssignment(theme),
          _shimmerAssignment(theme),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: theme.cardColor,
            highlightColor: theme.dividerColor,
            child: Container(
              height: 24,
              width: 180,
              color: theme.cardColor,
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          const SizedBox(height: 10),
          _shimmerEvent(theme),
        ],
      ),
    );
  }

  Widget _shimmerCard(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.cardColor,
      highlightColor: theme.dividerColor,
      child: Container(
        height: 90,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.brightness == Brightness.light
                ? Colors.grey.shade300
                : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _shimmerQuickAction(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.cardColor,
      highlightColor: theme.dividerColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.brightness == Brightness.light
                    ? Colors.grey.shade300
                    : Colors.grey.shade700,
              ),
            ),
            child: Container(
              width: 30,
              height: 30,
              color: theme.dividerColor,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            height: 10,
            width: 40,
            color: theme.dividerColor,
          ),
        ],
      ),
    );
  }

  Widget _shimmerAssignment(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.cardColor,
      highlightColor: theme.dividerColor,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          title: Container(height: 16, width: 100, color: theme.dividerColor),
          subtitle: Container(height: 12, width: 60, color: theme.dividerColor),
          trailing: Container(
            width: 60,
            height: 32,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _shimmerEvent(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.cardColor,
      highlightColor: theme.dividerColor,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 120,
              color: theme.dividerColor,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: 100, color: theme.dividerColor),
                  const SizedBox(height: 5),
                  Container(height: 12, width: 80, color: theme.dividerColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
