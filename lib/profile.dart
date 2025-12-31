import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signin_page.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const ProfilePage({super.key, required this.studentData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Map<String, dynamic> studentInfo;
  late final List<dynamic> attendanceData;
  late final List<dynamic> performanceList;
  late final Map<String, dynamic> latestPerformance;

  @override
  void initState() {
    super.initState();
    studentInfo = widget.studentData;
    attendanceData = studentInfo['attendance'] as List<dynamic>? ?? [];
    performanceList = studentInfo['performance'] as List<dynamic>? ?? [];
    latestPerformance = performanceList.isNotEmpty
        ? performanceList.last as Map<String, dynamic>
        : <String, dynamic>{};
  }

  double calculateAttendancePercentage() {
    int conducted = attendanceData
        .where((d) => d['held'] == 'conducted')
        .length;
    int present = attendanceData.where((d) => d['status'] == 'present').length;
    return conducted == 0 ? 0.0 : present / conducted * 100;
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => SigninPage()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Logged out successfully!"),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;
    final padding = isWide
        ? EdgeInsets.symmetric(horizontal: screenWidth * 0.15, vertical: 24)
        : const EdgeInsets.all(16.0);

    return Scaffold(
      appBar: AppBar(title: Text("My Profile"), centerTitle: true),
      body: SingleChildScrollView(
        padding: padding,
        child: Column(
          children: [
            _buildProfileImage(theme, isWide),
            const SizedBox(height: 8),
            Text(
              studentInfo["name"] ?? 'NA',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              studentInfo["rollNo"] ?? 'NA',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _infoCard(
                  "Semester",
                  studentInfo["semester"]?.toString() ?? 'NA',
                  theme,
                ),
                _infoCard(
                  "Attendance",
                  "${calculateAttendancePercentage().toStringAsFixed(2)}%",
                  theme,
                ),
                _infoCard(
                  "CGPA",
                  latestPerformance["cgpa"]?.toString() ?? 'NA',
                  theme,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProfileDetailsCard(theme),
            const SizedBox(height: 16),
            _LogoutButton(onLogout: _logout),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(ThemeData theme, bool isWide) {
    final photoURL = studentInfo["photoURL"];
    final size = isWide ? 140.0 : 100.0;
    if (photoURL != null && photoURL.toString().isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoURL,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _fallbackProfileIcon(theme, size);
          },
        ),
      );
    }
    return _fallbackProfileIcon(theme, size);
  }

  Widget _fallbackProfileIcon(ThemeData theme, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surface,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _infoCard(String title, String value, ThemeData theme) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: theme.cardTheme.elevation ?? 2,
        color: theme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetailsCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: theme.cardTheme.elevation ?? 2,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Personal Information",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow("Roll No:", studentInfo["rollNo"] ?? 'NA', theme),
            _buildInfoRow("Branch:", studentInfo["branchName"] ?? 'NA', theme),
            _buildInfoRow("Course:", studentInfo["course"] ?? 'NA', theme),
            _buildInfoRow(
              "Year:",
              studentInfo["year"]?.toString() ?? 'NA',
              theme,
            ),
            _buildInfoRow("Phone:", studentInfo["contact"] ?? 'NA', theme),
            _buildInfoRow("Email:", studentInfo["email"] ?? 'NA', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.hintColor,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: theme.cardTheme.elevation ?? 2,
      color: theme.cardColor,
      child: ListTile(
        leading: Icon(Icons.logout, color: theme.colorScheme.error),
        title: Text(
          "Logout",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.error,
          ),
        ),
        onTap: onLogout,
      ),
    );
  }
}
