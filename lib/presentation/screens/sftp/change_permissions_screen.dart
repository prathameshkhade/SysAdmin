import 'package:flutter/material.dart';
import '../../../data/models/sftp_permission_models.dart';
import '../../../data/services/sftp_service.dart';

class ChangePermissionScreen extends StatefulWidget {
  final String path;
  final String currentPermissions;
  final String owner;
  final String group;
  final SftpService sftpService;

  const ChangePermissionScreen({
    super.key,
    required this.path,
    required this.currentPermissions,
    required this.owner,
    required this.group,
    required this.sftpService,
  });

  @override
  State<ChangePermissionScreen> createState() => _ChangePermissionScreenState();
}

class _ChangePermissionScreenState extends State<ChangePermissionScreen> {
  late FilePermission _permissions;
  bool _isRecursive = false;
  bool _isLoading = false;
  String _currentOwner = '';
  String _currentGroup = '';

  @override
  void initState() {
    super.initState();
    _permissions = FilePermission.fromString(widget.currentPermissions.substring(1));
    _currentOwner = widget.owner;
    _currentGroup = widget.group;
  }

  void _showMessage(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _applyPermissions() async {
    setState(() => _isLoading = true);
    try {
      // Apply permissions
      await widget.sftpService.changePermissions(
        widget.path,
        _permissions.toOctal(),
        recursive: _isRecursive,
      );

      // Apply owner/group if changed
      if (_currentOwner != widget.owner || _currentGroup != widget.group) {
        await widget.sftpService.changeOwner(
          widget.path,
          _currentOwner,
          _currentGroup,
          recursive: _isRecursive,
        );
      }

      _showMessage('Permissions updated successfully', false);
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('Failed to update permissions: $e', true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showUserList() async {
    setState(() => _isLoading = true);
    try {
      final users = await widget.sftpService.getUsers();
      if (!mounted) return;

      final result = await showModalBottomSheet<UnixUser>(
        context: context,
        builder: (context) => _buildUserList(users),
      );

      if (result != null) {
        setState(() => _currentOwner = result.name);
      }
    } catch (e) {
      _showMessage('Failed to load users: $e', true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showGroupList() async {
    setState(() => _isLoading = true);
    try {
      final groups = await widget.sftpService.getGroups();
      if (!mounted) return;

      final result = await showModalBottomSheet<UnixGroup>(
        context: context,
        builder: (context) => _buildGroupList(groups),
      );

      if (result != null) {
        setState(() => _currentGroup = result.name);
      }
    } catch (e) {
      _showMessage('Failed to load groups: $e', true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Builds userlist
  Widget _buildUserList(List<UnixUser> users) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading: const Icon(Icons.person),
          title: Text(user.name),
          subtitle: Text('UID ${user.uid}'),
          onTap: () => Navigator.pop(context, user),
        );
      },
    );
  }

  // Builds grouplist
  Widget _buildGroupList(List<UnixGroup> groups) {
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return ListTile(
          leading: const Icon(Icons.group),
          title: Text(group.name),
          subtitle: Text('GID ${group.gid}'),
          onTap: () => Navigator.pop(context, group),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Permission checkboxes
                  _buildPermissionSection('Owner', [
                    ('R', _permissions.ownerRead, (value) => setState(() => _permissions.ownerRead = value!)),
                    ('W', _permissions.ownerWrite, (value) => setState(() => _permissions.ownerWrite = value!)),
                    ('X', _permissions.ownerExecute, (value) => setState(() => _permissions.ownerExecute = value!)),
                  ]),
                  _buildPermissionSection('Group', [
                    ('R', _permissions.groupRead, (value) => setState(() => _permissions.groupRead = value!)),
                    ('W', _permissions.groupWrite, (value) => setState(() => _permissions.groupWrite = value!)),
                    ('X', _permissions.groupExecute, (value) => setState(() => _permissions.groupExecute = value!)),
                  ]),
                  _buildPermissionSection('Global', [
                    ('R', _permissions.otherRead, (value) => setState(() => _permissions.otherRead = value!)),
                    ('W', _permissions.otherWrite, (value) => setState(() => _permissions.otherWrite = value!)),
                    ('X', _permissions.otherExecute, (value) => setState(() => _permissions.otherExecute = value!)),
                  ]),

                  const SizedBox(height: 16),
                  Text('${_permissions.toOctal()} ${_permissions.toString()}'),
                  const SizedBox(height: 16),

                  // Special permissions
                  Row(
                    children: [
                      Checkbox(
                        value: _isRecursive,
                        onChanged: (value) => setState(() => _isRecursive = value!),
                      ),
                      const Text('Recursive'),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text('Owner and group', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Owner selection
                  ListTile(
                    title: const Text('Owner'),
                    subtitle: Text(_currentOwner),
                    trailing: TextButton(
                      onPressed: _showUserList,
                      child: const Text('BROWSE'),
                    ),
                  ),

                  // Group selection
                  ListTile(
                    title: const Text('Group'),
                    subtitle: Text(_currentGroup),
                    trailing: TextButton(
                      onPressed: _showGroupList,
                      child: const Text('BROWSE'),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _applyPermissions,
        heroTag: const Icon(Icons.check),
        child: const Text('APPLY'),
      ),
    );
  }

  Widget _buildPermissionSection(String title, List<(String, bool, void Function(bool?))> permissions) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(title, style: const TextStyle(fontSize: 16)),
          ),
          ...permissions.map((p) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: p.$2,
                    onChanged: p.$3,
                  ),
                  Text(p.$1),
                  const SizedBox(width: 8),
                ],
              )),
        ],
      ),
    );
  }
} /* Models required for */
