import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ScheduleJobScreen extends StatelessWidget {


  const ScheduleJobScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 1.0,
          leading: CupertinoNavigationBarBackButton(
            onPressed: () => Navigator.pop(context),
          ),
          shape: Border.all(style: BorderStyle.none),

          title: const Text("Schedule Jobs"),
          bottom: TabBar(
              dividerHeight: 0,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: theme.primaryColor,
              labelStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              labelPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              tabAlignment: TabAlignment.center,
              unselectedLabelColor: Colors.grey.withOpacity(0.75),

              tabs: <Row> [
                Row(
                  children: <Widget> [
                    const Text("Differed Jobs"),
                    const SizedBox(width: 5),
                    Container(
                      height: 25,
                      width: 25,
                      decoration:BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryColor.withOpacity(0.5),
                      ),
                      child: const Center(child: Text('18')),
                    )
                  ],
                ),
                Row(
                  children: <Widget> [
                    const Text("Recurring Jobs"),
                    const SizedBox(width: 5),
                    Container(
                      height: 25,
                      width: 25,
                      decoration:BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryColor.withOpacity(0.5),
                      ),
                      child: const Center(child: Text('7')),
                    )
                  ],
                )
              ]
          )
        ),

        body: TabBarView(
          children: <Widget> [
            // Differed Jobs
            Center(child: Text("Differed Text", style: theme.textTheme.labelLarge)),

            // Recurring Jobs
            Center(child: Text("Recurring Text", style: theme.textTheme.labelLarge))
          ],
        ),
      )
    );
  }
}