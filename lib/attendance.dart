import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'data_service.dart'; // Make sure to import your DataService

class Attendance extends StatefulWidget {
  const Attendance({super.key});

  @override
  State<Attendance> createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> {
  final DataService _dataService = DataService();

  Map<String, dynamic> _subjectWiseAttendance = {};
  Map<String, int> _overallAttendance = {'total': 0, 'attended': 0, 'missed': 0};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    final rawAttendance = await _dataService.fetchLoggedInStudentAttendance();
    _processAttendanceData(rawAttendance);
    setState(() {
      isLoading = false;
    });
  }

  void _processAttendanceData(List<Map<String, dynamic>> rawAttendance) {
    _subjectWiseAttendance = {};
    _overallAttendance = {'total': 0, 'attended': 0, 'missed': 0};

    for (var record in rawAttendance) {
      final String subjectCode = (record['subjectCode'] ?? 'NA').toString();
      final String subjectName = (record['subjectName'] ?? 'NA').toString();
      final bool isPresent = (record['status'] ?? 'absent').toString().toLowerCase() == 'present';

      _subjectWiseAttendance.putIfAbsent(subjectCode, () => {
        'subjectName': subjectName,
        'total': 0,
        'attended': 0,
      });

      _subjectWiseAttendance[subjectCode]['total'] += 1;
      if (isPresent) {
        _subjectWiseAttendance[subjectCode]['attended'] += 1;
      }

      _overallAttendance['total'] = _overallAttendance['total']! + 1;
      if (isPresent) {
        _overallAttendance['attended'] = _overallAttendance['attended']! + 1;
      }
    }

    _overallAttendance['missed'] =
        _overallAttendance['total']! - _overallAttendance['attended']!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth > 900
        ? EdgeInsets.symmetric(horizontal: screenWidth * 0.15, vertical: 24)
        : const EdgeInsets.all(16.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Attendance",
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OverallAttendanceCard(
              totalClasses: _overallAttendance['total'].toString(),
              attendedClasses: _overallAttendance['attended'].toString(),
              missedClasses: _overallAttendance['missed'].toString(),
            ),
            const SizedBox(height: 20),
            if (_subjectWiseAttendance.isEmpty)
              Center(
                child: Text(
                  "No attendance records available",
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ..._subjectWiseAttendance.entries.map((entry) {
              final subjectCode = entry.key;
              final data = entry.value;
              final total = data['total'] as int;
              final attended = data['attended'] as int;
              final percentage = total > 0 ? attended / total : 0.0;

              return SubjectCard(
                subjectCode: subjectCode,
                subjectName: data['subjectName'],
                totalClasses: total.toString(),
                attendedClasses: attended.toString(),
                attendancePercent: percentage,
              );
            }),
          ],
        ),
      ),
    );
  }
}


class OverallAttendanceCard extends StatelessWidget {
  final String totalClasses;
  final String attendedClasses;
  final String missedClasses;

  const OverallAttendanceCard({
    super.key,
    required this.totalClasses,
    required this.attendedClasses,
    required this.missedClasses,
  });

  @override
  Widget build(BuildContext context) {
    final total = int.parse(totalClasses);
    final attended = int.parse(attendedClasses);
    final missed = int.parse(missedClasses);
    final percentage = total > 0 ? attended / total : 0.0;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 50,
              lineWidth: 8,
              percent: percentage.clamp(0.0, 1.0),
              center: Text("${(percentage * 100).toStringAsFixed(1)}%"),
              progressColor: percentage < 0.75 ? Colors.orange : Colors.green,
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Overall Attendance",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  _buildStatRow("Total Classes:", total.toString()),
                  _buildStatRow("Attended:", attended.toString()),
                  _buildStatRow("Missed:", missed.toString()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}



class SubjectCard extends StatelessWidget {
  final String subjectName;
  final String subjectCode;
  final String totalClasses;
  final String attendedClasses;
  final double attendancePercent;

  const SubjectCard({
    super.key,
    required this.subjectName,
    required this.subjectCode,
    required this.totalClasses,
    required this.attendedClasses,
    required this.attendancePercent,
  });

  @override
  Widget build(BuildContext context) {
    final total = int.tryParse(totalClasses) ?? 0;
    final attended = int.tryParse(attendedClasses) ?? 0;
    final missed = total - attended;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subjectName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${(attendancePercent * 100).toStringAsFixed(1)}%",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: attendancePercent < 0.75 ? Colors.orange : Colors.green,
                  ),
                )
              ],
            ),
            Text(
              subjectCode,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),
        LinearProgressIndicator(
                value: attendancePercent,
                backgroundColor: Colors.grey.shade300,
                color: attendancePercent < 0.75 ? Colors.orange : Colors.green,
                borderRadius: BorderRadius.circular(8.0),
                minHeight: 8,
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat("Total", total),
                _buildMiniStat("Attended", attended),
                _buildMiniStat("Missed", missed),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}