import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssignmentForm extends StatefulWidget {
  const AssignmentForm({super.key});

  @override
  _AssignmentFormState createState() => _AssignmentFormState();
}

class _AssignmentFormState extends State<AssignmentForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  String? _selectedSubjectCode;

  DateTime? _selectedDate;
  PlatformFile? _selectedFile;

  bool _isSubmitting = false;
  bool _isLoadingSubjects = true;
  List<Map<String, String>> _subjects = [];

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('branches')
        .doc('MCE')
        .collection('sections')
        .doc('B05')
        .collection('subjects')
        .get();
    _subjects = snapshot.docs.map((doc) {
      return {
        'code': doc['subjectCode'] as String,
        'name': doc['subjectName'] as String,
      };
    }).toList();
    if (_subjects.isNotEmpty) {
      _selectedSubjectCode = _subjects.first['code'];
    }
    setState(() => _isLoadingSubjects = false);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: false);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<String?> _uploadFileToSupabase(String subjectCode, PlatformFile file) async {
    try {
      if (file.path == null) {
        throw Exception('File path is null. Please select another file.');
      }

      // Read bytes from the picked file path
      final fileBytes = await File(file.path!).readAsBytes();
      final storagePath = '$subjectCode/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      const bucket = 'assignements';

      // Upload
      await supabase.storage
          .from(bucket)
          .uploadBinary(storagePath, fileBytes, fileOptions: const FileOptions(upsert: true));

      // Get public URL
      final publicURL = supabase.storage.from(bucket).getPublicUrl(storagePath);
      return publicURL;
    } catch (e) {
      debugPrint('Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File upload failed: $e')),
      );
      return null;
    }
  }

  Future<void> _submitAssignment() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedFile == null ||
        _selectedSubjectCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a file.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final assignId = 'assign_${DateTime.now().millisecondsSinceEpoch}';

    // 1️⃣ Upload file to Supabase
    final fileURL = await _uploadFileToSupabase(_selectedSubjectCode!, _selectedFile!);
    if (fileURL == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    // 2️⃣ Save assignment metadata to Firestore
    await FirebaseFirestore.instance
        .collection('branches')
        .doc('MCE')
        .collection('sections')
        .doc('B05')
        .collection('subjects')
        .doc(_selectedSubjectCode)
        .collection('assignments')
        .doc(assignId)
        .set({
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'unit': _unitController.text.trim(),
      'subjectCode': _selectedSubjectCode,
      'dueDate': Timestamp.fromDate(_selectedDate!),
      'fileName': _selectedFile!.name,
      'fileURL': fileURL,
      'isSubmitted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Assignment added successfully')),
    );
    Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Add Assignment')),
      body: Padding(
        padding: padding,
        child: _isLoadingSubjects
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Title', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Assignment 1',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter title' : null,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text('Subject', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedSubjectCode,
                      onChanged: (val) => setState(() => _selectedSubjectCode = val),
                      items: _subjects.map((subj) {
                        return DropdownMenuItem<String>(
                          value: subj['code'],
                          child: Text(subj['name']!, style: theme.textTheme.bodyMedium),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Unit', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _unitController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Unit 2',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter unit' : null,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text('Description', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Brief description of the assignment',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter description' : null,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text('Due Date', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  tileColor: theme.cardColor,
                  title: Text(
                    _selectedDate == null
                        ? 'Select due date'
                        : 'Due: ${DateFormat('dd MMM yyyy').format(_selectedDate!)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  trailing: Icon(Icons.calendar_today, color: theme.iconTheme.color),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
                const SizedBox(height: 12),
                Text('Attachment', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _pickFile,
                    child: Text(
                      _selectedFile == null ? 'Select File' : 'Selected: ${_selectedFile!.name}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    onPressed: _isSubmitting ? null : _submitAssignment,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Submit Assignment', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
