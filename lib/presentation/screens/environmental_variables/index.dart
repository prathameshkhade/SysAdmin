import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/data/services/env_service.dart';
import 'package:sysadmin/presentation/screens/environmental_variables/form.dart';
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

  // Use nullable type and late to handle async initialization
  EnvService? _envService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(
              () => setState(() {}) // Rebuild when tab changes
      );

    // Initialize the Env service
    _initService();
  }

  Future<void> _initService() async {
    try {
      _envService = await EnvService.create(ref: ref);
    } catch (e) {
      debugPrint('Error initializing EnvService: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  // Callback functions
  void _handleFabClick() async {
    final bool isGlobal = _tabController.index == 1; // Fixed index comparison

    final bool? isCreated = await Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) => EnvForm(isGlobal: isGlobal)
        )
    );

    if (isCreated == true && mounted) {
      setState(() {}); // Triggers rebuild to refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 1.0,
        title: const Text("Environmental Variables"),
        bottom: TabBar(
          controller: _tabController,
          dividerHeight: 0,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: theme.primaryColor,
          labelStyle: theme.textTheme.labelLarge!.copyWith(fontWeight: FontWeight.bold),
          tabAlignment: TabAlignment.center,
          unselectedLabelColor: Colors.grey,
          tabs: const <Tab> [
            Tab(child: Text("Local Variables")),
            Tab(child: Text("Global Variables"))
          ],
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _envService == null
          ? const Center(child: Text("Failed to initialize environment service"))
          : DefaultTabController(
          length: 2,
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              LocalVariableTab(envService: _envService!),
              GlobalVariableTab(envService: _envService!)
            ],
          )
      ),

      floatingActionButton: (!_isLoading && _envService != null) ? FloatingActionButton(
        onPressed: _handleFabClick,
        tooltip: "Create ${_tabController.index == 0 ? 'Local' : 'Global'} Variable",
        elevation: 4.0,
        child: const Icon(Icons.add_rounded),
      ) : null,
    );
  }
}