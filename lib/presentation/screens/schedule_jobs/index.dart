import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/presentation/screens/schedule_jobs/deferred_job/index.dart';
import 'package:sysadmin/presentation/screens/schedule_jobs/recurring_job/index.dart';
import 'package:sysadmin/providers/ssh_state.dart';

import 'deferred_job/form.dart';
import 'recurring_job/form.dart';

class ScheduleJobScreen extends ConsumerStatefulWidget {
  const ScheduleJobScreen({super.key});

  @override
  ConsumerState<ScheduleJobScreen> createState() => _ScheduleJobScreenState();
}

class _ScheduleJobScreenState extends ConsumerState<ScheduleJobScreen> with SingleTickerProviderStateMixin {
  late TabController tabController;
  late ScrollController scrollController;

  // Add counters for both job types
  int deferredJobCount = 0;
  int recurringJobCount = 0;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    scrollController = ScrollController();

    tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // Callback methods to update job counts
  void updateDeferredJobCount(int count) {
    setState(() => deferredJobCount = count);
  }

  void updateRecurringJobCount(int count) {
    setState(() => recurringJobCount = count);
  }

  Future<void> _handleFabClick() async {
    final sshClient = ref.read(sshClientProvider).value;
    if (tabController.index == 0) {
      final result = await Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => AtJobForm(sshClient: sshClient!),
        ),
      );

      if (result == true && mounted) {
        setState(() {}); // Trigger rebuild to refresh
      }
    } else {
      final result = await Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => CronJobForm(sshClient: sshClient!),
        ),
      );

      if (result == true && mounted) {
        setState(() {}); // Trigger rebuild to refresh
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sshClient = ref.read(sshClientProvider).value;

    return Scaffold(
      appBar: AppBar(
        elevation: 1.0,
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        shape: Border.all(style: BorderStyle.none),
        title: const Text("Schedule Jobs"),
        bottom: TabBar(
          controller: tabController,
          dividerHeight: 0,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: theme.primaryColor,
          labelStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          tabAlignment: TabAlignment.center,
          unselectedLabelColor: Colors.grey,
          tabs: <Row>[
            Row(
              children: <Widget>[
                const Text("Differed Jobs"),
                const SizedBox(width: 5),
                Container(
                  height: 22,
                  width: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tabController.index == 0
                        ? theme.primaryColor.withOpacity(0.5)
                        : Colors.grey.withOpacity(0.3),
                  ),
                  child: Center(
                      child: Text(
                    '$deferredJobCount',
                    style: theme.textTheme.labelSmall,
                  )),
                )
              ],
            ),
            Row(
              children: <Widget>[
                const Text("Recurring Jobs"),
                const SizedBox(width: 5),
                Container(
                  height: 22,
                  width: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        tabController.index == 1 ? theme.primaryColor.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
                  ),
                  child: Center(
                      child: Text(
                    '$recurringJobCount',
                    style: theme.textTheme.labelSmall,
                  )),
                )
              ],
            )
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: <Widget>[
          DeferredJobScreen(
            sshClient: sshClient!,
            onJobCountChanged: updateDeferredJobCount,
          ),
          RecurringJobScreen(
            sshClient: sshClient,
            onJobCountChanged: updateRecurringJobCount,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleFabClick,
        tooltip: "Create ${tabController.index == 0 ? 'At' : 'Cron'} Job",
        elevation: 4.0,
        icon: Icon(Icons.add, color: theme.colorScheme.onSurface),
        label: Text('Add Task', style: theme.textTheme.labelLarge),
      ),
    );
  }
}
