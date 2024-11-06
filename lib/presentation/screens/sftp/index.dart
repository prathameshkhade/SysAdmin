import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sysadmin/presentation/screens/sftp/change_permissions_screen.dart';
import 'package:sysadmin/presentation/screens/sftp/file_properties_screen.dart';
import '../../../data/models/remote_file.dart';
import '../../../data/models/ssh_connection.dart';
import '../../../data/services/sftp_service.dart';
import 'directory_picker.dart';
import 'directory_view.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

class SftpExplorerScreen extends StatefulWidget {
  final SSHConnection connection;
  final String initialPath;

  const SftpExplorerScreen({
    super.key,
    required this.connection,
    this.initialPath = '/',
  });

  @override
  State<SftpExplorerScreen> createState() => _SftpExplorerScreenState();
}

class _SftpExplorerScreenState extends State<SftpExplorerScreen> with TickerProviderStateMixin {
  final SftpService _sftpService = SftpService();
  late String _currentPath = '/';
  List<RemoteFile> _files = [];
  bool _isLoading = true;
  String? _error;
  bool _isConnected = false;

  // Selection related variables
  final Set<RemoteFile> _selectedFiles = {};
  late AnimationController _actionBarController;
  late Animation<double> _actionBarAnimation;

  // Operation progress
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
    _setupAnimations();
    _connectAndLoadDirectory();
  }

  void _setupAnimations() {
    _actionBarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _actionBarAnimation = CurvedAnimation(
      parent: _actionBarController,
      curve: Curves.easeInOut,
    );
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
    } catch (e) {
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
      _selectedFiles.clear();
      _actionBarController.reverse();
    });

    try {
      final files = await _sftpService.listDirectory(_currentPath);
      if (!mounted) return;

      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load directory: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToDirectory(String path) {
    if (path == '..') {
      // Handle going back to parent directory
      final segments = _currentPath.split('/')
        ..removeWhere((s) => s.isEmpty)
        ..removeLast();
      path = segments.isEmpty ? '/' : '/${segments.join('/')}';

      if (_currentPath == '/') {
        Navigator.pop(context);
        return;
      }
    }

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => SftpExplorerScreen(
          connection: widget.connection,
          initialPath: path, // Add this parameter to constructor
        ),
      ),
    );
  }

  // Selection handling
  void _handleFileSelection(RemoteFile file) {
    setState(() {
      if (_selectedFiles.contains(file)) {
        _selectedFiles.remove(file);
        if (_selectedFiles.isEmpty) _actionBarController.reverse();
      } else {
        _selectedFiles.add(file);
        _actionBarController.forward();
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedFiles.clear();
      _actionBarController.reverse();
    });
  }

  // File operations
  Future<void> _handleCopy() async {
    final destinationPath = await _showDirectoryPicker('Choose destination folder');
    if (destinationPath == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      for (final file in _selectedFiles) {
        final newPath = '$destinationPath/${file.name}';
        await _sftpService.copyFile(file.path, newPath);
      }
      _clearSelection();
      await _loadCurrentDirectory();
    }
    catch (e) {
      _showError('Failed to copy files: $e');
    }
    finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleMove() async {
    final destinationPath = await _showDirectoryPicker('Choose destination folder');
    if (destinationPath == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      for (final file in _selectedFiles) {
        final newPath = '$destinationPath/${file.name}';
        await _sftpService.moveFile(file.path, newPath);
      }
      _clearSelection();
      await _loadCurrentDirectory();
    } catch (e) {
      _showError('Failed to move files: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${_selectedFiles.length} item(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      for (final file in _selectedFiles) {
        await _sftpService.deleteFile(file.path);
      }
      _clearSelection();
      await _loadCurrentDirectory();
    } catch (e) {
      _showError('Failed to delete files: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleRename() async {
    if (_selectedFiles.length != 1) {
      _showError('Please select only one file to rename');
      return;
    }

    final file = _selectedFiles.first;
    final newName = await _showRenameDialog(file.name);
    if (newName == null || newName.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final newPath = '$_currentPath/$newName';
      await _sftpService.renameFile(file.path, newPath);
      _clearSelection();
      await _loadCurrentDirectory();
    }
    catch (e) {
      _showError('Failed to rename file: $e');
    }
    finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDownload() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      for (final file in _selectedFiles) {
        if (!file.isDirectory) {
          await _sftpService.downloadFile(
            remotePath: file.path,
            localPath: '/storage/emulated/O/Download/${file.name}', // TODO: Modify as per your app's download directory
            onProgress: (count, total) {
            },
          );
        }
      }
      _clearSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download completed')),
      );
    }
    catch (e) {
      _showError('Failed to download files: $e');
    }
    finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _showFileInfo() async {
    if (_selectedFiles.length != 1) {
      _showError('Please select only one file to view info');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final details = await _sftpService.getFileDetails(_selectedFiles.first.path);
      if (!mounted) return;

      Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => FilePropertiesScreen(fileDetails: details)
          )
      );
    }
    catch (e) {
      _showError('Failed to load file details: $e');
    }
    finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _showPermissionScreen() async {
    if (_selectedFiles.length != 1) {
      _showError('Please select at least one file or directory to view the permissions');
      return;
    }

    final file = _selectedFiles.first;
    final fileDetails = await _sftpService.getFileDetails(file.path);

    try {
      Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => ChangePermissionScreen(
                  path: fileDetails.path,
                  currentPermissions: file.permissions,
                  owner: fileDetails.owner.toString(),
                  group: fileDetails.group.toString(),
                  sftpService: _sftpService
              )
          )
      );
    }
    catch(e) {
      _showError('Failed to load file details: $e');
    }
  }

  // UI Helper methods
  Future<String?> _showDirectoryPicker(String title) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 1,
          builder: (context, scrollController) {
            return DirectoryPicker(
              currentPath: _currentPath,
              sftpService: _sftpService,
              title: title,
            );
          },
        );
      },
    );
  }

  Future<String?> _showRenameDialog(String currentName) async {
    final controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  /* Action button methods for handling creating file, folder & uploading */
  Future<String?> _showCreateFileDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create file'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'File name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // Handling File, Folder creation
  Future<void> _handleCreateFile() async {
    // Get the new file name from dialog
    final newFileName = await _showCreateFileDialog();

    if (newFileName == null || newFileName.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final newFilePath = '$_currentPath/$newFileName';
      await _sftpService.createFile(newFilePath);
      await _loadCurrentDirectory();
    }
    catch(e) {
      _showError("Unable to create a file. \n $e");
      setState(() => _isLoading = false);
    }
    finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: _selectedFiles.isEmpty
            ? CupertinoNavigationBarBackButton(
                onPressed: () => Navigator.pop(context),
              )
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              ),
        title: _selectedFiles.isEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_currentPath, style: theme.textTheme.bodyLarge),
                  Text('${_files.length} items', style: theme.textTheme.labelSmall?.copyWith(color: Colors.blueGrey)),
                ],
              )
            : Text('${_selectedFiles.length} selected'),
        actions: _selectedFiles.isEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // Implement search
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // Implement more options
                  },
                ),
              ]
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _isConnected ? _loadCurrentDirectory : _connectAndLoadDirectory,
        child: _buildBody(theme),
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: _isProcessing
          ? CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            )
          : ExpandableFab(
            type: ExpandableFabType.up,
            overlayStyle: ExpandableFabOverlayStyle(color: Colors.black.withOpacity(0.4), blur: 1),
            distance: 75,
            childrenAnimation: ExpandableFabAnimation.none,


            // Add button (Open)
            openButtonBuilder: RotateFloatingActionButtonBuilder(
              heroTag: const Icon(Icons.add),
              backgroundColor: Theme.of(context).primaryColor,
              shape: const CircleBorder(),
              fabSize: ExpandableFabSize.regular,
              child: const Icon(Icons.add)
            ),

            // Close button (Close)
            closeButtonBuilder: RotateFloatingActionButtonBuilder(
                backgroundColor: Theme.of(context).primaryColor,
                shape: const CircleBorder(),
              fabSize: ExpandableFabSize.regular,
              child: const Icon(Icons.close)
            ),

            // List of buttons
            children: [
              // create file
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                 //  Label
                  Text('Create file',
                    style: Theme.of(context).textTheme.labelLarge
                  ),

                 const SizedBox(width: 12),

                 // Button
                  FloatingActionButton(
                    onPressed: () => _handleCreateFile,
                    shape: const CircleBorder(),
                    tooltip: "Create file",
                    enableFeedback: true,
                    child: const Icon(Icons.file_copy_outlined),
                  ),
                ],
              ),

              // create folder
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //  Label
                  Text('Create folder',
                      style: Theme.of(context).textTheme.labelLarge
                  ),

                  const SizedBox(width: 12),

                  // Button
                  FloatingActionButton(
                    onPressed: () {},
                    shape: const CircleBorder(),
                    tooltip: "Create folder",
                    enableFeedback: true,
                    child: const Icon(Icons.create_new_folder_outlined),
                  ),
                ],
              ),

              // Upload file
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //  Label
                  Text('Upload',
                      style: Theme.of(context).textTheme.labelLarge
                  ),

                  const SizedBox(width: 12),

                  // Button
                  FloatingActionButton(
                    onPressed: () {},
                    shape: const CircleBorder(),
                    tooltip: "Upload file",
                    enableFeedback: true,
                    child: const Icon(Icons.upload_file_outlined),
                  ),
                ],
              ),

            ],
          ),
      bottomNavigationBar: _selectedFiles.isEmpty
          ? null
          : SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(_actionBarAnimation),
              child: Container(
                // 15% height for action bar
                height: MediaQuery.of(context).size.width * 0.15,
                color: theme.colorScheme.surface,
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(Icons.cut_rounded, _handleMove),
                      _buildActionButton(Icons.copy, _handleCopy),
                      _buildActionButton(Icons.delete_outlined, _handleDelete),
                      _buildActionButton(Icons.download_outlined, _handleDownload),
                      _buildActionButton(Icons.edit_outlined, _handleRename),
                      _buildActionButton(Icons.info_outline_rounded, _showFileInfo),
                      _buildActionButton(Icons.settings_outlined, _showPermissionScreen),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _actionBarController.dispose();
    if (_isConnected) {
      _sftpService.disconnect();
    }
    super.dispose();
  }

  Widget _buildBody(ThemeData theme) {
    // Loading Screen
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
        ),
      );
    }

    // Error Screen
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

    // Directory view
    return DirectoryView(
      files: _files,
      selectedFiles: _selectedFiles,
      currentPath: _currentPath,
      onDirectoryTap: _navigateToDirectory,
      onFileLongPress: _handleFileSelection,
      onFileTap: (file) {
        if (_selectedFiles.isNotEmpty) {
          _handleFileSelection(file);
        } else if (file.isDirectory) {
          _navigateToDirectory(file.path);
        }
      },
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
