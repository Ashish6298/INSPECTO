import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/request_provider.dart';
import '../widgets/request_url_bar.dart';
import '../widgets/request_tabs.dart';
import '../widgets/response_viewer.dart';

class RequestScreen extends StatelessWidget {
  const RequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requestProvider = context.watch<RequestProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 32, width: 32),
            const SizedBox(width: 12),
            const Text(
              'INSPECTO',
              style: TextStyle(
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded),
            onPressed: () {
              // TODO: Save to collection
            },
            tooltip: 'Save Request',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const RequestUrlBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                children: [
                  const RequestTabs(),
                  if (requestProvider.response != null) const ResponseViewer(),
                  if (requestProvider.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (requestProvider.response == null &&
                      !requestProvider.isLoading)
                    _EmptyRequestState(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FloatingActionButton.extended(
          onPressed: () {
            context.read<RequestProvider>().sendRequest();
          },
          elevation: 4,
          icon: const Icon(Icons.bolt_rounded, size: 24),
          label: const Text(
            'SEND REQUEST',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _EmptyRequestState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          Icon(
            Icons.rocket_launch_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
          const SizedBox(height: 24),
          Text(
            'NO ACTIVE REQUEST',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              letterSpacing: 2,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enter a URL above to start testing your APIs.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
