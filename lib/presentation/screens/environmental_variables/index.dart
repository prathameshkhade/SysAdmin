import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/presentation/screens/environmental_variables/global/index.dart';
import 'package:sysadmin/presentation/screens/environmental_variables/local/index.dart';

class EnvScreen extends ConsumerStatefulWidget {
  const EnvScreen({super.key});

  @override
  ConsumerState<EnvScreen> createState() => _EnvScreenState();
}

class _EnvScreenState extends ConsumerState<EnvScreen> with SingleTickerProviderStateMixin {
  // Controllers
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(
        () => setState(() {}) // Rebuild when tab changes
      );
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Environmental Variables"),
        bottom: TabBar(
          controller: _tabController,
          dividerHeight: 0,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: theme.primaryColor,
          labelStyle: theme.textTheme.labelLarge!.copyWith(fontWeight: FontWeight.bold),
          tabAlignment: TabAlignment.center,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(child: Text("Local Variables")),
            Tab(child: Text("Global Variables"))
          ],
        ),
      ),

      body: DefaultTabController(
          length: 2,
          child: TabBarView(
            controller: _tabController,
            children: const <Widget> [
              Center(
                child: Text(
                  "Local Var List",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                ),
              ),

              Center(
                child: Text(
                  "Global Var List",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                ),
              )
            ],
          )
      ),
    );
  }
}
