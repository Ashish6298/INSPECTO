import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/request_provider.dart';
import 'key_value_list.dart';
import 'request_body_editor.dart';
import 'authorization_editor.dart';
import 'post_request_tab.dart';

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
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequestProvider>();
    final extractorCount = provider.extractors.length;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          indicatorColor: Theme.of(context).colorScheme.primary,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            const Tab(text: 'Params'),
            const Tab(text: 'Auth'),
            const Tab(text: 'Headers'),
            const Tab(text: 'Body'),
            Tab(
              text: extractorCount > 0
                  ? 'Extractors ($extractorCount)'
                  : 'Extractors',
            ),
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
              const AuthorizationEditor(),
              KeyValueList(
                title: 'Headers',
                data: provider.headers,
                onChanged: provider.setHeaders,
              ),
              const RequestBodyEditor(),
              const PostRequestTab(),
            ],
          ),
        ),
      ],
    );
  }
}
