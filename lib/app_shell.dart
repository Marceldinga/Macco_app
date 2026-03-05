import 'package:flutter/material.dart';

import 'panels/dashboard_panel.dart';
import 'panels/members_panel.dart';
import 'panels/llm_panel.dart';
import 'panels/loans_panel.dart'; // ✅ Loans panel

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const DashboardPanel(),
      const MembersPanel(),
      const LoansPanel(),        // ✅ Real loans panel
      const LlmPanelPage(),
      const _ComingSoon(title: 'Audit'),
      const _ComingSoon(title: 'Health'),
      const _ComingSoon(title: 'Admin'),
    ];

    final titles = <String>[
      'Dashboard',
      'Members',
      'Loans',
      'LLM Panel',
      'Audit',
      'Health',
      'Admin',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("${titles[_index]} • v1"), // version label helps confirm deployment
      ),
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() {
            _index = i;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups),
            label: 'Members',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance),
            label: 'Loans',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy),
            label: 'LLM',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Audit',
          ),
          NavigationDestination(
            icon: Icon(Icons.health_and_safety),
            label: 'Health',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  final String title;

  const _ComingSoon({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title\n\nComing soon...',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}