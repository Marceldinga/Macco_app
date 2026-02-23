import 'package:flutter/material.dart';

void main() {
  runApp(const NjangiApp());
}

class NjangiApp extends StatelessWidget {
  const NjangiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'theyoungshallgrow',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0B1B3A), // midnight navy vibe
      ),
      home: const NjangiShell(),
    );
  }
}

class NjangiShell extends StatefulWidget {
  const NjangiShell({super.key});

  @override
  State<NjangiShell> createState() => _NjangiShellState();
}

class _NjangiShellState extends State<NjangiShell> {
  int _index = 0;

  final _pages = const [
    DashboardPage(),
    TransactionsPage(),
    LoansPage(),
    FinesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('theyoungshallgrow 🏦'),
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Txns'),
          NavigationDestination(icon: Icon(Icons.account_balance), label: 'Loans'),
          NavigationDestination(icon: Icon(Icons.gavel), label: 'Fines'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // DEMO DATA (no login, no backend yet)
    final kpis = [
      ('Total Contributed', '\$12,500'),
      ('Foundation Balance', '\$6,000'),
      ('Outstanding Loans', '\$4,500'),
      ('Overdue Members', '2'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Dashboard',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        for (final (title, value) in kpis)
          Card(
            child: ListTile(
              title: Text(title),
              trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Demo mode is ON (no login).\n'
              'Next: connect to Supabase using a safe public view, or enable login later.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ),
      ],
    );
  }
}

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('Contribution', 'Marcel Dinga', '\$500', '2026-02-16'),
      ('Loan payment', 'Aria Dinga', '\$250', '2026-02-10'),
      ('Fine payment', 'Member 3', '\$50', '2026-02-08'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Transactions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        for (final (type, who, amt, date) in items)
          Card(
            child: ListTile(
              title: Text('$type • $amt'),
              subtitle: Text('$who • $date'),
            ),
          ),
      ],
    );
  }
}

class LoansPage extends StatelessWidget {
  const LoansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loans = const [
      ('Marcel Dinga', '\$1,000', 'Active', '10 days overdue'),
      ('Member 7', '\$500', 'Closed', 'Paid'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Loans', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        for (final (name, principal, status, note) in loans)
          Card(
            child: ListTile(
              title: Text('$name • $principal'),
              subtitle: Text('$status • $note'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
      ],
    );
  }
}

class FinesPage extends StatelessWidget {
  const FinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final fines = const [
      ('Late payment', 'Marcel Dinga', '\$20', 'Paid'),
      ('Missed meeting', 'Member 2', '\$10', 'Unpaid'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Fines', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        for (final (reason, who, amt, status) in fines)
          Card(
            child: ListTile(
              title: Text('$reason • $amt'),
              subtitle: Text('$who • $status'),
            ),
          ),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        SizedBox(height: 12),
        Card(
          child: ListTile(
            title: Text('Demo User'),
            subtitle: Text('No login yet'),
            leading: CircleAvatar(child: Icon(Icons.person)),
          ),
        ),
        SizedBox(height: 12),
        Card(
          child: ListTile(
            title: Text('Switch to Supabase later'),
            subtitle: Text('We’ll enable login + RLS when you’re ready'),
          ),
        ),
      ],
    );
  }
}