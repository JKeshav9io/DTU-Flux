import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dtu_connect/notification_services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mime/mime.dart';  // Added for MIME type lookup

class SendNotificationPage extends StatefulWidget {
  const SendNotificationPage({super.key});

  @override
  State<SendNotificationPage> createState() => _SendNotificationPageState();
}

class _SendNotificationPageState extends State<SendNotificationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  String? selectedSubject;
  String selectedNotice = "Class Bunk";
  final TextEditingController customMessageController = TextEditingController();
  final TextEditingController customTitleController = TextEditingController();
  final TextEditingController defaultMessageController = TextEditingController();

  List<Map<String, dynamic>> subjects = [];
  bool isLoading = true;
  PlatformFile? pickedFile;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }

  Future<void> fetchSubjects() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final query = await _firestore.collection('students').where('email', isEqualTo: user.email).get();
    if (query.docs.isEmpty) return;
    final studentData = query.docs.first.data();
    final branchId = studentData['branchId'];
    final sectionId = studentData['sectionId'];

    final snapshot = await _firestore
        .collection('branches')
        .doc(branchId)
        .collection('sections')
        .doc(sectionId)
        .collection('subjects')
        .get();

    setState(() {
      subjects = snapshot.docs.map((doc) => doc.data()).toList();
      selectedSubject = subjects.isNotEmpty ? subjects.first['subjectName'] : null;
      isLoading = false;
    });
  }

  Future<void> pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes == null && file.path != null) {
        final fileData = await File(file.path!).readAsBytes();
        setState(() {
          pickedFile = PlatformFile(
            name: file.name,
            size: file.size,
            bytes: fileData,
            path: file.path,
          );
        });
      } else {
        setState(() {
          pickedFile = file;
        });
      }
    }
  }

  Future<String?> _uploadFileToSupabase(PlatformFile file, String folderName) async {
    try {
      // Ensure bytes are available
      if (file.bytes == null) {
        if (file.path != null) {
          final fileData = await File(file.path!).readAsBytes();
          file = PlatformFile(
            name: file.name,
            size: file.size,
            bytes: fileData,
            path: file.path,
          );
        } else {
          throw Exception('No file data available');
        }
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = '${file.name}';
      final String filePath = '$folderName/$fileName';

      // Determine proper MIME type from filename
      final String? mimeType = lookupMimeType(file.name);
      final contentType = mimeType ?? 'application/octet-stream';

      await _supabase.storage.from('notificationsfile').uploadBinary(
        filePath,
        file.bytes!,
        fileOptions: FileOptions(contentType: contentType),
      );

      // getPublicUrl returns String
      final String url = _supabase.storage.from('notificationsfile').getPublicUrl(filePath);
      return url;
    } catch (e) {
      print('❌ File upload error: $e');
      return null;
    }
  }

  void sendNotification() async {
    if (isUploading) return;
    final user = _auth.currentUser;
    if (user == null) return;
    if (selectedNotice == "Custom Notification") {
      if (customTitleController.text.trim().isEmpty || customMessageController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter title and message!")),
        );
        return;
      }
    }

    setState(() => isUploading = true);
    String? attachmentUrl;

    try {
      final query = await _firestore.collection('students').where('email', isEqualTo: user.email).get();
      if (query.docs.isEmpty) throw Exception('Student record not found');
      final studentData = query.docs.first.data();
      final branchId = studentData['branchId'];
      final sectionId = studentData['sectionId'];
      final enrolledYear = studentData['enrolledYear'].toString();
      final topic = '${enrolledYear}_${branchId}_${sectionId}';

      if (pickedFile != null) {
        attachmentUrl = await _uploadFileToSupabase(pickedFile!, topic);
        if (attachmentUrl == null) throw Exception('File upload failed');
      }

      final collectionPath = 'notification/$topic/history';
      final title = selectedNotice == "Custom Notification"
          ? customTitleController.text.trim()
          : selectedNotice;
      final body = selectedNotice == "Custom Notification"
          ? customMessageController.text.trim()
          : defaultMessageController.text.trim();

      final notificationData = {
        'title': title,
        'body': body,
        'type': selectedNotice,
        'screen': 'alerts',
        'timestamp': FieldValue.serverTimestamp(),
        if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      };

      await _firestore.collection(collectionPath).add(notificationData);
      await NotificationServices().sendNotificationToTopic(
        title: title,
        body: body,
        screenToNavigate: 'alerts',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Notification Sent Successfully"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        customTitleController.clear();
        customMessageController.clear();
        defaultMessageController.clear();
        pickedFile = null;
        isUploading = false;
      });
    } catch (e) {
      print('❌ Notification error: $e');
      setState(() => isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustom = selectedNotice == "Custom Notification";
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;
    final padding = isWide
        ? EdgeInsets.symmetric(horizontal: width * 0.15, vertical: 24)
        : const EdgeInsets.all(16.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Notification"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text("Notification Type:", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  "Class Bunk",
                  "Class Cancellation",
                  "Custom Notification"
                ].map((notice) {
                  final selected = selectedNotice == notice;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      showCheckmark: false,
                      label: Text(
                        notice,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                        ),
                      ),
                      selected: selected,
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (bool sel) {
                        setState(() {
                          selectedNotice = notice;
                          customMessageController.clear();
                          customTitleController.clear();
                          defaultMessageController.clear();
                          pickedFile = null;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            if (!isCustom) ...[
              Text("Select Subject:", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedSubject,
                    icon: Icon(Icons.arrow_drop_down, color: theme.iconTheme.color),
                    items: subjects.map((subj) {
                      return DropdownMenuItem<String>(
                        value: subj['subjectName'],
                        child: Text(subj['subjectName'] ?? "", style: theme.textTheme.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSubject = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text("Notification Message:", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: defaultMessageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Enter message",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (isCustom) ...[
              Text("Notification Title:", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: customTitleController,
                decoration: InputDecoration(
                  hintText: "Enter Title",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Text("Notification Message:", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: customMessageController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Enter Message",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: pickAttachment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(pickedFile == null ? "Attach File" : pickedFile!.name, style: theme.textTheme.labelLarge),
              ),
            ],
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: sendNotification,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Send Notification", style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
