import 'package:flutter/material.dart';
import '../../../data/models/remote_file.dart';
import '../../../data/models/ssh_connection.dart';
import '../../../data/services/sftp_service.dart';
import 'directory_view.dart';

class SftpExplorerScreen extends StatefulWidget {
  final SSHConnection connection;

  const SftpExplorerScreen({
    super.key,
    required this.connection,
  });

  @override
  State<SftpExplorerScreen> createState() => _SftpExplorerScreenState();
}

class _SftpExplorerScreenState extends State<SftpExplorerScreen> {
  final SftpService _sftpService = SftpService();
  String _currentPath = '/';
  List<RemoteFile> _files = [];
  bool _isLoading = true;
  String? _error;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connectAndLoadDirectory();
  }

  Future<void> _connectAndLoadDirectory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _sftpService.connect(widget.connection);
      _isConnected = true;
      await _loadCurrentDirectory();
    }
    catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Connection failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentDirectory() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final files = await _sftpService.listDirectory(_currentPath);
      if (!mounted) return;

      setState(() {
        _files = files;
        _isLoading = false;
      });
    }
    catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load directory: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToDirectory(String path) {
    setState(() => _currentPath = path);
    _loadCurrentDirectory();
  }

  @override
  void dispose() {
    if (_isConnected) {
      _sftpService.disconnect();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          elevation: 0,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),

      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Implement drawer or navigation menu
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Text> [
              Text(_currentPath, style: theme.textTheme.bodyLarge),
              Text('${_files.length} items', style: TextStyle(fontSize: 12, color: Colors.grey[400]),),
            ],
          ),

          actions: [
            // Search Icon Button
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Implement search functionality
              },
            ),

            // More
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Implement more options menu
              },
            ),
          ],
        ),

        body: _buildBody(theme),

        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Implement add/upload functionality
          },
          backgroundColor: Colors.amber,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _connectAndLoadDirectory,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.surface,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return DirectoryView(
      files: _files,
      currentPath: _currentPath,
      onDirectoryTap: _navigateToDirectory,
    );
  }
}
