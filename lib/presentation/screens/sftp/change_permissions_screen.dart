import 'package:flutter/material.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
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
    _permissions = FilePermission.fromString(widget.currentPermissions);
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

  // Show the Userlist
  Future<void> _showUserList() async {
    final users = await widget.sftpService.getUsers();
    if (!mounted) return;

    final selectedUser = await showDialog<String>(
      context: context,
      builder: (context) =>
          Dialog(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) =>
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(users[index].name),
                    subtitle: Text('UID ${users[index].uid}'),
                    onTap: () => Navigator.pop(context, users[index].name),
                  ),
            ),
          ),
    );

    if (selectedUser != null) setState(() => _currentOwner = selectedUser);
  }

  // Show the GroupList
  Future<void> _showGroupList() async {
    final groups = await widget.sftpService.getGroups();
    if (!mounted) return;

    final selectedGroup = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: groups.length,
          itemBuilder: (context, index) => ListTile(
            leading: const Icon(Icons.group),
            title: Text(groups[index].name),
            subtitle: Text('GID ${groups[index].gid}'),
            onTap: () => Navigator.pop(context, groups[index].name),
          ),
        ),
      ),
    );

    if (selectedGroup != null) setState(() => _currentGroup = selectedGroup);
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
    return IosScaffold(
      title: "Permissions",
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget> [
                    // SETUID
                    Checkbox(
                      value: _permissions.setuid,
                      onChanged: (value) => setState(() => _permissions.setuid = value!),
                    ),
                    const Text('SETUID'),
                    const SizedBox(width: 8),

                    // SETGID
                    Checkbox(
                      value: _permissions.setgid,
                      onChanged: (value) => setState(() => _permissions.setgid = value!),
                    ),
                    const Text('SETGID'),
                    const SizedBox(width: 8),

                    // STICKY
                    Checkbox(
                      value: _permissions.sticky,
                      onChanged: (value) => setState(() => _permissions.sticky = value!),
                    ),
                    const Text('STICKY'),
                  ],
                ),

                const SizedBox(height: 16),
                // Changed Permissions representation
                Text(
                  '${_permissions.toOctal()} \t\t\t ${_permissions.toString()}',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Recursive Checkbox
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
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
                  trailing: ElevatedButton(
                    onPressed: _showUserList,
                    child: const Text('BROWSE'),
                  ),
                ),

                // Group selection
                ListTile(
                  title: const Text('Group'),
                  subtitle: Text(_currentGroup),
                  trailing: ElevatedButton(
                    onPressed: _showGroupList,
                    child: const Text('BROWSE'),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: "Apply the changed permissions",
        onPressed: _applyPermissions,
        icon: const Icon(Icons.check),
        label: const Text("Apply"),
      ),
    );
  }

  Widget _buildPermissionSection(String title, List<(String, bool, void Function(bool?))> permissions) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
}
