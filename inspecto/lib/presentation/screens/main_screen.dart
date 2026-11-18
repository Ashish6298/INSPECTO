import 'package:flutter/material.dart';
import 'request_screen.dart';
import 'websocket_screen.dart';
import 'history_screen.dart';
import 'collections_screen.dart';
import 'environments_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    const RequestScreen(),
    const WebSocketScreen(),
    HistoryScreen(onRequestTapped: () {
      setState(() {
        _selectedIndex = 0;
      });
    }),
    CollectionsScreen(onRequestTapped: () {
      setState(() {
        _selectedIndex = 0;
      });
    }),
    const EnvironmentsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.send_rounded),
            label: 'Request',
          ),
          NavigationDestination(
            icon: Icon(Icons.cable_rounded),
            label: 'WebSocket',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_rounded),
            label: 'Collections',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_input_component_rounded),
            label: 'Environments',
          ),
        ],
      ),
    );
  }
}
