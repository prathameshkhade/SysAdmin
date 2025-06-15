import 'package:flutter/cupertino.dart';
import 'package:sysadmin/data/models/linux_user.dart';

class DeleteUserScreen extends StatefulWidget {
 final LinuxUser user;

  const DeleteUserScreen({
    super.key,
    required this.user
  });

  @override
  State<DeleteUserScreen> createState() => _DeleteUserScreenState();
}

class _DeleteUserScreenState extends State<DeleteUserScreen> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
