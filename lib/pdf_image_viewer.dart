import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class FileViewerScreen extends StatefulWidget {
  final String fileUrl;
  final String fileName;

  const FileViewerScreen({
    super.key,
    required this.fileUrl,
    required this.fileName,
  });

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  bool isLoading = true;
  bool isError = false;
  File? cachedFile;
  PdfControllerPinch? pdfController;

  @override
  void initState() {
    super.initState();
    _loadFromCacheOrDownload();
  }

  @override
  void dispose() {
    pdfController?.dispose();
    super.dispose();
  }

  Future<void> _loadFromCacheOrDownload() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final isPdf = widget.fileUrl.toLowerCase().endsWith('.pdf');
      final cleanedFileName = widget.fileName.trim().replaceAll(' ', '_');
      final safeFileName = isPdf && !cleanedFileName.endsWith('.pdf')
          ? '$cleanedFileName.pdf'
          : cleanedFileName;
      final filePath = '${cacheDir.path}/$safeFileName';
      final file = File(filePath);

      if (await file.exists() && await file.length() > 0) {
        final docFuture = PdfDocument.openFile(file.path);
        setState(() {
          cachedFile = file;
          pdfController = PdfControllerPinch(document: docFuture);
          isError = false;
        });
      } else {
        await Dio().download(widget.fileUrl, file.path);
        if (await file.exists() && await file.length() > 0) {
          final docFuture = PdfDocument.openFile(file.path);
          setState(() {
            cachedFile = file;
            pdfController = PdfControllerPinch(document: docFuture);
            isError = false;
          });
        } else {
          throw Exception("Downloaded file is empty or corrupted.");
        }
      }
    } catch (e) {
      debugPrint('Error loading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Unable to load the file. Please try again later.',
            ),
          ),
        );
        Navigator.pop(context); // Go back
      }
      setState(() {
        isError = true;
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _downloadAndOpen() async {
    try {
      if (Platform.isAndroid) {
        if (await Permission.storage.isGranted == false) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Storage permission denied')),
              );
            }
            return;
          }
        }
      }

      Directory? targetDir;
      if (Platform.isAndroid) {
        final downloadDirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        targetDir = (downloadDirs != null && downloadDirs.isNotEmpty)
            ? downloadDirs.first
            : await getExternalStorageDirectory();
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      final cleanedFileName = widget.fileName.trim().replaceAll(' ', '_');
      final safeFileName =
          widget.fileUrl.toLowerCase().endsWith('.pdf') &&
              !cleanedFileName.endsWith('.pdf')
          ? '$cleanedFileName.pdf'
          : cleanedFileName;
      final filePath = '${targetDir!.path}/$safeFileName';

      await Dio().download(widget.fileUrl, filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved to $filePath'),
            action: SnackBarAction(
              label: 'OPEN',
              onPressed: () {
                OpenFile.open(filePath);
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download. Please try again.'),
          ),
        );
      }
    }
  }

  Widget _buildViewer() {
    final lower = widget.fileName.toLowerCase();
    if (lower.endsWith('.pdf') && pdfController != null) {
      return PdfViewPinch(controller: pdfController!);
    } else if ([
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
    ].any((ext) => lower.endsWith(ext))) {
      return cachedFile != null
          ? Image.file(cachedFile!)
          : const Center(child: Text('Image not loaded.'));
    } else {
      return const Center(child: Text('Unsupported or unreadable file.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadAndOpen,
            tooltip: 'Download & Open',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isError
          ? Center(
              child: Text(
                'Failed to load file',
                style: theme.textTheme.bodyMedium,
              ),
            )
          : _buildViewer(),
    );
  }
}
