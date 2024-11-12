import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scrolling_fab_animated/flutter_scrolling_fab_animated.dart';
import 'package:sysadmin/data/models/ssh_connection.dart';
import 'package:sysadmin/presentation/screens/schedule_jobs/deferred_job/index.dart';
import 'package:sysadmin/presentation/screens/schedule_jobs/recurring_job/index.dart';

import 'deferred_job/form.dart';

class ScheduleJobScreen extends StatefulWidget {

  final SSHConnection connection;
  final SSHClient sshClient;

  const ScheduleJobScreen({
    super.key,
    required this.connection,
    required this.sshClient
  });

  @override
  State<ScheduleJobScreen> createState() => _ScheduleJobScreenState();
}

class _ScheduleJobScreenState extends State<ScheduleJobScreen> with SingleTickerProviderStateMixin {
  late TabController tabController;
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    scrollController = ScrollController();

    // Add listener to rebuild when tab changes
    tabController.addListener(() {
      setState(() {});  // This will rebuild the widget when tab changes
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // Handle FAB click based on current tab
  Future<void> _handleFabClick() async {
    if (tabController.index == 0) {
      final result = await Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => AtJobForm(sshClient: widget.sshClient),
        ),
      );

      if (result == true) {
        // Refresh the job list
        if (mounted) setState(() {});
      }
    }
    else {
      // TODO: Navigate to Recurring Job Form
      debugPrint('Navigate to Recurring Job Form');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 1.0,
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        shape: Border.all(style: BorderStyle.none),
        title: const Text("Schedule Jobs"),
        bottom: TabBar(
          controller: tabController,  // Add this
          dividerHeight: 0,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: theme.primaryColor,
          labelStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          labelPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          tabAlignment: TabAlignment.center,
          unselectedLabelColor: Colors.grey.withOpacity(0.75),
          tabs: <Row>[
            Row(
              children: <Widget>[
                const Text("Differed Jobs"),
                const SizedBox(width: 5),
                Container(
                  height: 25,
                  width: 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primaryColor.withOpacity(0.5),
                  ),
                  child: const Center(child: Text('18')),
                )
              ],
            ),
            Row(
              children: <Widget>[
                const Text("Recurring Jobs"),
                const SizedBox(width: 5),
                Container(
                  height: 25,
                  width: 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primaryColor.withOpacity(0.5),
                  ),
                  child: const Center(child: Text('7')),
                )
              ],
            )
          ],
        ),
      ),

      body: TabBarView(
        controller: tabController,
        children: <Widget>[
          DeferredJobScreen(sshClient: widget.sshClient),
          const RecurringJobScreen(),
        ],
      ),

      floatingActionButton: ScrollingFabAnimated(
        onPress: _handleFabClick,
        scrollController: scrollController,
        animateIcon: true,
        inverted: false,
        radius: 12.0,
        elevation: 4.0,
        width: 190,
        icon: const Icon(Icons.add),
        text: Text(
            tabController.index == 0 ? 'Add Deferred Task' : 'Add Recurring Task',
            style: theme.textTheme.labelLarge
        ),
      ),
    );
  }
}