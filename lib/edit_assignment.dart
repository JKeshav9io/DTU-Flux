import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditAssignmentForm extends StatefulWidget {
  final String branchId;
  final String sectionId;
  final String subjectCode;
  final String docId;
  final Map<String, dynamic> initialData;

  const EditAssignmentForm({
    super.key,
    required this.branchId,
    required this.sectionId,
    required this.subjectCode,
    required this.docId,
    required this.initialData,
  });

  @override
  State<EditAssignmentForm> createState() => _EditAssignmentFormState();
}

class _EditAssignmentFormState extends State<EditAssignmentForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _unitController;
  late TextEditingController _descriptionController;
  DateTime? _selectedDate;
  PlatformFile? _selectedFile;
  bool _isSubmitted = false;
  bool _isSaving = false;

  // Supabase client reference
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // Prefill controllers
    _titleController = TextEditingController(text: widget.initialData['title']);
    _unitController = TextEditingController(text: widget.initialData['unit']);
    _descriptionController = TextEditingController(
      text: widget.initialData['description'],
    );
    final raw = widget.initialData['dueDate'];
    if (raw is Timestamp) {
      _selectedDate = raw.toDate();
    } else if (raw is String) {
      _selectedDate = DateTime.tryParse(raw);
    }
    _isSubmitted = widget.initialData['isSubmitted'] ?? false;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: false);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<String?> _uploadFileToSupabase(
    String subjectCode,
    PlatformFile file,
  ) async {
    try {
      if (file.path == null) {
        throw Exception('File path is null. Please select another file.');
      }

      // Read the file bytes from disk
      final fileBytes = await File(file.path!).readAsBytes();
      final storagePath =
          '$subjectCode/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      const bucket = 'assignments';

      // Upload to Supabase
      await supabase.storage
          .from(bucket)
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get the public URL
      final publicURL = supabase.storage.from(bucket).getPublicUrl(storagePath);
      return publicURL;
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('File upload failed: $e')));
      }
      return null;
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) return;
    setState(() => _isSaving = true);

    final ref = FirebaseFirestore.instance
        .collection('branches')
        .doc(widget.branchId)
        .collection('sections')
        .doc(widget.sectionId)
        .collection('subjects')
        .doc(widget.subjectCode)
        .collection('assignments')
        .doc(widget.docId);

    final updateData = {
      'title': _titleController.text.trim(),
      'unit': _unitController.text.trim(),
      'description': _descriptionController.text.trim(),
      'dueDate': Timestamp.fromDate(_selectedDate!),
      'isSubmitted': _isSubmitted,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // If a new file was picked, upload it and store its URL
    if (_selectedFile != null) {
      final fileURL = await _uploadFileToSupabase(
        widget.subjectCode,
        _selectedFile!,
      );
      if (fileURL != null) {
        updateData['fileName'] = _selectedFile!.name;
        updateData['fileURL'] = fileURL;
      }
    }

    await ref.update(updateData);

    setState(() => _isSaving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Assignment updated successfully')),
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
      appBar: AppBar(title: const Text('Edit Assignment')),
      body: Padding(
        padding: padding,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Title',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Assignment Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter title' : null,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Subject Code',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    widget.subjectCode,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Unit',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextFormField(
                  controller: _unitController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Unit 2',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter unit' : null,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Description',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter description' : null,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Due Date',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  tileColor: theme.cardColor,
                  title: Text(
                    _selectedDate == null
                        ? 'Select date'
                        : DateFormat('dd MMM yyyy').format(_selectedDate!),
                    style: theme.textTheme.bodyMedium,
                  ),
                  trailing: Icon(
                    Icons.calendar_today,
                    color: theme.iconTheme.color,
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Attachment',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                OutlinedButton(
                  onPressed: _pickFile,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _selectedFile == null
                        ? 'Change File'
                        : 'Selected: ${_selectedFile!.name}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _isSubmitted,
                  title: Text(
                    'Mark assignment as submitted',
                    style: theme.textTheme.bodyMedium,
                  ),
                  onChanged: (val) => setState(() => _isSubmitted = val!),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: theme.colorScheme.primary,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    onPressed: _isSaving ? null : _saveChanges,
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Save Changes',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
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
