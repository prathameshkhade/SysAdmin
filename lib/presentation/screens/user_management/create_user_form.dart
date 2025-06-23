import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/core/utils/util.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
import 'package:sysadmin/data/models/linux_user.dart';
import 'package:sysadmin/data/services/ssh_session_manager.dart';
import 'package:sysadmin/data/services/user_manager_service.dart';
import 'package:sysadmin/providers/ssh_state.dart';

class CreateUserForm extends ConsumerStatefulWidget {
  final UserManagerService service;

  const CreateUserForm({super.key, required this.service});

  @override
  ConsumerState<CreateUserForm> createState() => _CreateUserFormState();
}

class _CreateUserFormState extends ConsumerState<CreateUserForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _commentController = TextEditingController();
  final _homeDirectoryController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedShell = '/bin/bash';
  bool _createHomeDirectory = true;
  bool _createUserGroup = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  late final SSHSessionManager _sessionManager;
  List<String?> _shells = [];

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_updateHomeDirectory);
    _sessionManager = ref.read(sshSessionManagerProvider);
    getAvailableShells();
  }

  /// Fetches all the available shells from connected server
  void getAvailableShells() async {
    // fetch shells
    final shellListFromServers = await _sessionManager.execute("cat /etc/shells");

    setState(() {
      // Filter all the shells properly - remove any comments and empty lines
      _shells = shellListFromServers
          .split("\n")
          .where((e) => e.trim().isNotEmpty && !e.trim().startsWith("#"))
          .map((e) => e.trim())
          .toList();
      _shells.insert(0, 'default'); // Add default option
      debugPrint("Available shells: $_shells");
    });
  }

  void _updateHomeDirectory() {
    if (_homeDirectoryController.text.isEmpty || _homeDirectoryController.text == '/home/${_usernameController.text}') {
      _homeDirectoryController.text = '/home/${_usernameController.text}';
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      Util.showMsg(context: context, msg: "Passwords do not match", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = LinuxUser(
        username: _usernameController.text.trim(),
        password: 'x',
        uid: 0, // Will be auto-assigned by system
        gid: 0, // Will be auto-assigned by system
        comment: _commentController.text.trim(),
        homeDirectory: _homeDirectoryController.text.trim(),
        shell: _selectedShell,
      );

      final result = await widget.service.createUser(
        user: user,
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
        createHomeDirectory: _createHomeDirectory,
        createUserGroup: _createUserGroup,
        customShell: _selectedShell,
      );

      if (result == true) {
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else if (result == null) {
        // User cancelled sudo password
        if (mounted) {
          Util.showMsg(context: context, msg: "Operation cancelled", isError: true);
        }
      }
    }
    catch (e) {
      if (mounted) {
        Util.showMsg(context: context, msg: "Failed to create user: $e", isError: true);
      }
    }
    finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IosScaffold(
      title: "Create User",
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              const Text(
                "User Information",
              ),
              const SizedBox(height: 20),

              // Username field
              _buildTextField(
                controller: _usernameController,
                label: "Username",
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Username is required";
                  }
                  if (!RegExp(r'^[a-z_][a-z0-9_-]*$').hasMatch(value.trim())) {
                    return "Invalid username format";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Comment field
              _buildTextField(
                controller: _commentController,
                label: "Full Name / Comment",
                required: false,
              ),
              const SizedBox(height: 20),

              // Password field
              _buildPasswordField(
                controller: _passwordController,
                label: "Password",
                isVisible: _isPasswordVisible,
                onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              const SizedBox(height: 20),

              // Confirm Password field
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: "Confirm Password",
                isVisible: _isConfirmPasswordVisible,
                onToggleVisibility: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              ),
              const SizedBox(height: 24),

              // Switch option for creating home directory
              _buildSwitchTile(
                title: "Create Home Directory?",
                value: _createHomeDirectory,
                onChanged: (value) => setState(() => _createHomeDirectory = value),
              ),
              const SizedBox(height: 20),

              // Home Directory field
              if (_createHomeDirectory) ...[
                _buildTextField(
                  controller: _homeDirectoryController,
                  label: "Home Directory",
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Home directory is required";
                    }
                    if (!value.startsWith('/')) {
                      return "Home directory must be an absolute path";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Shell dropdown
              _buildDropdownField(),
              const SizedBox(height: 24),

              // Options
              _buildSwitchTile(
                title: "Create User Group",
                value: _createUserGroup,
                onChanged: (value) => setState(() => _createUserGroup = value),
              ),
              const SizedBox(height: 32),

              // Create button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Create",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ]
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: switch (label) {
        "Password" || "Confirm Password" => TextInputType.visiblePassword,
        _ => TextInputType.text,
      },
      autofocus: label == "Username",
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: validator ??
          (required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "$label is required";
                  }
                  return null;
                }
              : null),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: Icon(
            isVisible ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedShell,
      decoration: InputDecoration(
        labelText: "Shell",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      items: _shells.map((shell) {
        return DropdownMenuItem(
          value: shell,
          child: Text(shell!),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedShell = value);
        }
      },
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _commentController.dispose();
    _homeDirectoryController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
