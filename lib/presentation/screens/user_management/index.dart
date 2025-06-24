import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/core/utils/color_extension.dart';
import 'package:sysadmin/core/utils/util.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
import 'package:sysadmin/data/services/user_manager_service.dart';
import 'package:sysadmin/presentation/screens/user_management/create_user_form.dart';
import 'package:sysadmin/presentation/widgets/bottom_sheet.dart';
import 'package:sysadmin/providers/ssh_state.dart';

import '../../../core/services/sudo_service.dart';
import '../../../data/models/linux_user.dart';
import 'delete_user_screen.dart';

enum UserFilter { all, system, regular, customFilter }

enum SortField { username, uid, gid, comment }

enum SortOrder { ascending, descending, none }

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  late UserManagerService _userManagerService;
  late SudoService _sudoService;
  late List<LinuxUser> users = [];
  late List<LinuxUser> filteredUsers = [];

  // Filter states
  UserFilter selectedFilter = UserFilter.all;
  Map<SortField, SortOrder> sortOrders = {
    SortField.username: SortOrder.none,
    SortField.uid: SortOrder.none,
    SortField.gid: SortOrder.none,
    SortField.comment: SortOrder.none,
  };

  @override
  void initState() {
    super.initState();
    var sessionManager = ref.read(sshSessionManagerProvider);
    _sudoService = ref.read(sudoServiceProvider);
    _userManagerService = UserManagerService(sessionManager, _sudoService);

    // Set context for sudo prompts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sudoService.setContext(context);
    });

    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      users = await _userManagerService.getAllUsers();
      _applyFilters();
      debugPrint(users.toString());
      setState(() {});
    }
    catch (e) {
      debugPrint("$e");
    }
  }

  void _applyFilters() {
    List<LinuxUser> tempUsers = List.from(users);

    // Apply category filter
    switch (selectedFilter) {
      case UserFilter.system:
        tempUsers = tempUsers.where((user) => user.uid >= 0 && user.uid <= 999).toList();
        break;
      case UserFilter.regular:
        tempUsers = tempUsers.where((user) => user.uid > 1000).toList();
        break;
      case UserFilter.all:
      case UserFilter.customFilter:
        // Show all users
        break;
    }

    // Apply sorting
    _applySorting(tempUsers);
    filteredUsers = tempUsers;
  }

  void _applySorting(List<LinuxUser> userList) {
    // Find active sort field
    SortField? activeSortField;
    SortOrder? activeSortOrder;

    for (var entry in sortOrders.entries) {
      if (entry.value != SortOrder.none) {
        activeSortField = entry.key;
        activeSortOrder = entry.value;
        break;
      }
    }

    if (activeSortField == null || activeSortOrder == SortOrder.none) return;

    userList.sort((a, b) {
      int comparison = 0;

      switch (activeSortField!) {
        case SortField.username:
          comparison = a.username.toLowerCase().compareTo(b.username.toLowerCase());
          break;
        case SortField.uid:
          comparison = a.uid.compareTo(b.uid);
          break;
        case SortField.gid:
          comparison = a.gid.compareTo(b.gid);
          break;
        case SortField.comment:
          comparison = a.comment.toLowerCase().compareTo(b.comment.toLowerCase());
          break;
      }

      return activeSortOrder == SortOrder.ascending ? comparison : -comparison;
    });
  }

  void _toggleSort(SortField field) {
    setState(() {
      // Reset all other sort orders
      for (var key in sortOrders.keys) {
        if (key != field) {
          sortOrders[key] = SortOrder.none;
        }
      }

      // Toggle current field
      switch (sortOrders[field]!) {
        case SortOrder.none:
          sortOrders[field] = SortOrder.ascending;
          break;
        case SortOrder.ascending:
          sortOrders[field] = SortOrder.descending;
          break;
        case SortOrder.descending:
          sortOrders[field] = SortOrder.none;
          break;
      }

      _applyFilters();
    });
  }

  void _onFilterChanged(UserFilter filter) {
    setState(() {
      selectedFilter = filter;
      _applyFilters();
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.useOpacity(0.5),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sort',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          // Clear all sorts
                          for (var key in sortOrders.keys) {
                            sortOrders[key] = SortOrder.none;
                          }
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('CLEAR'),
                    ),
                  ],
                ),
              ),

              // Sort options
              _buildSortOption('Username', SortField.username, Icons.abc),
              _buildSortOption('User ID', SortField.uid, Icons.tag),
              _buildSortOption('Group ID', SortField.gid, Icons.group),
              _buildSortOption('Comment', SortField.comment, Icons.comment),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, SortField field, IconData icon) {
    final sortOrder = sortOrders[field]!;
    final theme = Theme.of(context);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
      isThreeLine: false,
      iconColor: Colors.grey,
      titleAlignment: ListTileTitleAlignment.center,
      titleTextStyle: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.inverseSurface.useOpacity(0.85)
      ),
      leading: Icon(icon),
      title: Text(title),
      trailing: _buildSortIndicator(sortOrder),
      onTap: () => _toggleSort(field)
    );
  }

  Widget _buildSortIndicator(SortOrder order) {
    switch (order) {
      case SortOrder.ascending:
        return Icon(Icons.arrow_upward, color: Theme.of(context).colorScheme.primary);
      case SortOrder.descending:
        return Icon(Icons.arrow_downward, color: Theme.of(context).colorScheme.primary);
      case SortOrder.none:
        return const SizedBox.shrink();
    }
  }

  void _showModalBottomSheet(BuildContext context, LinuxUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.useOpacity(0.5),
      builder: (context) => CustomBottomSheet(
        data: CustomBottomSheetData(
            title: user.username,
            subtitle: user.comment.isNotEmpty ? user.comment : "N/A",
            actionButtons: <ActionButtonData> [
              ActionButtonData(
                  text: 'EDIT',
                  onPressed: user.uid <= 1000
                      ? () {}
                      : () async {
                    try {
                      Navigator.pop(context); // Close bottom sheet first
                      bool? isUserUpdated = await Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => CreateUserForm(
                            service: _userManagerService,
                            originalUser: user, // Pass the user to edit
                          ),
                        ),
                      );

                      if (isUserUpdated == true) {
                        WidgetsBinding.instance.addPostFrameCallback(
                              (_) => Util.showMsg(
                            context: context,
                            msg: "User updated successfully",
                            bgColour: Colors.green,
                            isError: false,
                          ),
                        );
                        await _loadUsers(); // Refresh the user list
                      }
                    }
                    catch (e) {
                      if (mounted) {
                        WidgetsBinding.instance.addPostFrameCallback(
                              (_) => Util.showMsg(
                            context: context,
                            msg: "Failed to update user: $e",
                            isError: true,
                          ),
                        );
                      }
                    }
                  }
              ),
              ActionButtonData(
                  text: "DELETE",
                  onPressed: user.uid <= 1000
                      ? () {}
                      : () async {
                    try {
                      Navigator.pop(context);
                      bool? isUserDeleted = await Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (context) => DeleteUserScreen(
                              user: user,
                              service: _userManagerService
                          ))
                      );
                      // Refresh user's list if the user is deleted
                      if (isUserDeleted == true) {
                        WidgetsBinding.instance.addPostFrameCallback(
                                (_) => Util.showMsg(
                                context: context,
                                msg: "User deleted successfully",
                                bgColour: Colors.green,
                                isError: false
                            )
                        );
                        await _loadUsers();
                      }
                    }
                    catch(e) {
                      if (mounted) {
                        WidgetsBinding.instance.addPostFrameCallback(
                              (_) => Util.showMsg(context: context, msg: "Failed to delete user: $e", isError: true),
                        );
                      }
                    }
                  },
                  bgColor: Theme.of(context).colorScheme.error
              )
            ],
            tables: <TableData> [
              TableData(
                  heading: "User Information",
                  rows: <TableRowData> [
                    TableRowData(label: "Username", value: user.username),
                    TableRowData(label: "Comment", value: user.comment.isNotEmpty ? user.comment : "N/A"),
                    TableRowData(label: "UID", value: user.uid.toString()),
                    TableRowData(label: "GID", value: user.gid.toString()),
                  ]
              ),
              TableData(
                  heading: "System Path",
                  rows: <TableRowData> [
                    TableRowData(label: "Home Directory", value: user.homeDirectory),
                    TableRowData(label: "Shell", value: user.shell),
                  ]
              ),

              TableData(
                  heading: "Login Information",
                  rows: <TableRowData> [
                    TableRowData(label: "Last Login", value: user.lastLogin.toString()),
                  ]
              ),
            ]
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IosScaffold(
        title: "Manage Users",
        body: SafeArea(
          child: Column(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(left: 2, top: 4, bottom: 8, right: 2),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', UserFilter.all),
                    const SizedBox(width: 10),
                    _buildFilterChip('System', UserFilter.system),
                    const SizedBox(width: 10),
                    _buildFilterChip('Regular', UserFilter.regular),
                    const SizedBox(width: 10),
                    _buildFilterActionChip(),
                  ],
                ),
              ),

              // List of users
              Flexible(
                child: RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.separated(
                    itemCount: filteredUsers.length,
                    separatorBuilder: (context, index) => Divider(
                        height: 1.3,
                        color: theme.colorScheme.surface
                    ),
                    itemBuilder: (context, index) => ListTile(
                        subtitleTextStyle: const TextStyle(color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                        leading: CircleAvatar(
                          maxRadius: 24,
                          backgroundColor: (
                              filteredUsers[index].uid == 0
                                  ? CupertinoColors.systemRed
                                  : (filteredUsers[index].uid > 0 && filteredUsers[index].uid < 1000)
                                    ? CupertinoColors.activeBlue
                                    : CupertinoColors.activeGreen
                          ).useOpacity(0.75),
                          child: Icon(
                              filteredUsers[index].uid == 0
                                  ? Icons.admin_panel_settings_outlined
                                  : (filteredUsers[index].uid > 0 && filteredUsers[index].uid < 1000)
                                    ? Icons.settings
                                    : Icons.person_outline_rounded,
                              size: 27,
                              color: theme.colorScheme.inverseSurface
                          ),
                        ),
                        title: Text(filteredUsers[index].username),
                        subtitle: Text(filteredUsers[index].comment.isNotEmpty ? filteredUsers[index].comment : "N/A"),
                        onTap: () => _showModalBottomSheet(context, filteredUsers[index])
                    ),
                  ),
                ),
              )
            ]
          ),
        ),

        // Create User Button
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            try {
              bool? isUserCreated = await Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => CreateUserForm(service: _userManagerService))
              );

              if (isUserCreated == true) {
                WidgetsBinding.instance.addPostFrameCallback(
                      (_) => Util.showMsg(
                    context: context,
                    msg: "User created successfully",
                    bgColour: Colors.green,
                    isError: false,
                  ),
                );
                await _loadUsers();
              }
            }
            catch (e) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback(
                      (_) => Util.showMsg(
                    context: context,
                    msg: "Failed to create user: $e",
                    isError: true,
                  ),
                );
              }
            }
          },
          child: Icon(Icons.add_sharp, color: theme.colorScheme.inverseSurface),
        )
    );
  }

  /// Builds a filter chip based on the provided label and filter
  Widget _buildFilterChip(String label, UserFilter filter) {
    final isSelected = selectedFilter == filter;
    final theme = Theme.of(context);

    return FilterChip(
      showCheckmark: false,
      labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),

      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.inverseSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _onFilterChanged(filter);
        }
      },
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary.useOpacity(0.3) : theme.colorScheme.outline,
          width: 0.4
        ),
      ),
    );
  }

  /// Builds the filter action chip
  Widget _buildFilterActionChip() {
    final theme = Theme.of(context);
    final hasActiveSort = sortOrders.values.any((order) => order != SortOrder.none);

    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sort,
            size: 16,
            color: hasActiveSort ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 6),
          Text(
            'Sort',
            style: TextStyle(
              color: hasActiveSort ? theme.colorScheme.onPrimary : theme.colorScheme.inverseSurface,
              fontWeight: hasActiveSort ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
      onPressed: _showFilterBottomSheet,
      backgroundColor: hasActiveSort ? theme.colorScheme.primary : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: hasActiveSort ? theme.colorScheme.primary : theme.colorScheme.outline,
          width: 0.5,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sudoService.clearContext();
    super.dispose();
  }
}