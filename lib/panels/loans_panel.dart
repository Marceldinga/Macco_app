import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoansPanel extends StatefulWidget {
  const LoansPanel({super.key});

  @override
  State<LoansPanel> createState() => _LoansPanelState();
}

class _LoansPanelState extends State<LoansPanel> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _rows = [];
  List<String> _columns = const [];

  // tweak if you want fewer/more rows
  static const int _limit = 50;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('loans')
          .select('*')
          .order('created_at', ascending: false)
          .limit(_limit);

      final list = (data as List).cast<Map<String, dynamic>>();

      // derive columns from first row (keeps it flexible)
      final cols = list.isNotEmpty ? list.first.keys.map((e) => e.toString()).toList() : <String>[];

      setState(() {
        _rows = list;
        _columns = cols;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = Colors.white.withOpacity(0.10);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D14),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0E111B).withOpacity(0.70),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorView(error: _error!, onRetry: _loadLoans)
                  : _rows.isEmpty
                      ? _EmptyView(onRetry: _loadLoans)
                      : _LoansTable(columns: _columns, rows: _rows),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _loadLoans,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "⚠️ Failed to load loans",
          style: TextStyle(color: Colors.white.withOpacity(0.90), fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Text(error, style: TextStyle(color: Colors.white.withOpacity(0.65)), textAlign: TextAlign.center),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text("Retry"),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onRetry;

  const _EmptyView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "No loans found.",
          style: TextStyle(color: Colors.white.withOpacity(0.80), fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text("Reload"),
        ),
      ],
    );
  }
}

class _LoansTable extends StatelessWidget {
  final List<String> columns;
  final List<Map<String, dynamic>> rows;

  const _LoansTable({required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    // limit columns for better UI (you can adjust)
    final maxCols = columns.length > 10 ? columns.sublist(0, 10) : columns;
    final maxRows = rows.length > 25 ? rows.sublist(0, 25) : rows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Loans",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.92), fontSize: 16),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingTextStyle: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
                dataTextStyle: TextStyle(
                  color: Colors.white.withOpacity(0.80),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                columns: maxCols.map((c) => DataColumn(label: Text(c))).toList(),
                rows: maxRows.map((r) {
                  return DataRow(
                    cells: maxCols.map((c) => DataCell(Text("${r[c] ?? ''}"))).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Showing ${maxRows.length}/${rows.length} rows • ${maxCols.length}/${columns.length} columns",
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55), fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}