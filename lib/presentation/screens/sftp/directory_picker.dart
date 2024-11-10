import 'package:flutter/material.dart';

import '../../../data/models/remote_file.dart';
import '../../../data/services/sftp_service.dart';

class DirectoryPicker extends StatefulWidget {
  final String currentPath;
  final SftpService sftpService;
  final String title;

  const DirectoryPicker({
    super.key,
    required this.currentPath,
    required this.sftpService,
    required this.title,
  });

  @override
  State<DirectoryPicker> createState() => _DirectoryPickerState();
}

class _DirectoryPickerState extends State<DirectoryPicker> {
  late String _currentPath;
  List<RemoteFile> _directories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.currentPath;
    _loadDirectories();
  }

  Future<void> _loadDirectories() async {
    setState(() => _isLoading = true);
    try {
      final files = await widget.sftpService.listDirectory(_currentPath);
      setState(() {
        _directories = files.where((f) => f.isDirectory).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load directories: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, _currentPath),
              child: const Text('Select'),
            ),
          ],
        ),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Expanded(
            child: ListView.builder(
              itemCount: _directories.length,
              itemBuilder: (context, index) {
                final dir = _directories[index];
                return ListTile(
                  leading: Icon(Icons.folder, color: Theme.of(context).primaryColor),
                  title: Text(dir.name),
                  onTap: () {
                    setState(() {
                      _currentPath = dir.path;
                      _loadDirectories();
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
