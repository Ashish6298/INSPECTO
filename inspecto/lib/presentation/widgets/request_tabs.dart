import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/request_provider.dart';
import 'key_value_list.dart';
import 'request_body_editor.dart';

class RequestTabs extends StatefulWidget {
  const RequestTabs({super.key});

  @override
  State<RequestTabs> createState() => _RequestTabsState();
}

class _RequestTabsState extends State<RequestTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequestProvider>();

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepPurple,
          labelColor: Colors.deepPurpleAccent,
          tabs: const [
            Tab(text: 'Params'),
            Tab(text: 'Headers'),
            Tab(text: 'Body'),
          ],
        ),
        SizedBox(
          height: 300,
          child: TabBarView(
            controller: _tabController,
            children: [
              KeyValueList(
                title: 'Query Parameters',
                data: provider.params,
                onChanged: provider.setParams,
              ),
              KeyValueList(
                title: 'Headers',
                data: provider.headers,
                onChanged: provider.setHeaders,
              ),
              const RequestBodyEditor(),
            ],
          ),
        ),
      ],
    );
  }
}
