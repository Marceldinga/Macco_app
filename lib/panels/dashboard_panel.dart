import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPanel extends StatefulWidget {
  const DashboardPanel({super.key});

  @override
  State<DashboardPanel> createState() => _DashboardPanelState();
}

class _DashboardPanelState extends State<DashboardPanel> {
  late Future<_DashData> _future;
  SupabaseClient get sb => Supabase.instance.client;

  // HF-like dark palette
  static const _bg = Color(0xFF0B1120);
  static const _cardBg = Color(0xFF111827);
  static const _border = Color(0xFF1F2937);
  static const _chip = Color(0xFF1F2937);
  static const _accent = Color(0xFF6366F1);

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _single(String viewOrTable) async {
    final data = await sb.from(viewOrTable).select().limit(1);
    if (data is List && data.isNotEmpty) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    return {};
  }

  Future<List<Map<String, dynamic>>> _list(String viewOrTable, {int limit = 10}) async {
    final data = await sb.from(viewOrTable).select().limit(limit);
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<int> _count(String table) async {
    // lightweight count via a small select; (for exact count, use a view v_members_count if desired)
    final data = await sb.from(table).select('id').limit(5000);
    if (data is List) return data.length;
    return 0;
  }

  Future<Map<String, dynamic>> _memberById(int id) async {
    try {
      final data = await sb.from('members').select().eq('id', id).limit(1);
      if (data is List && data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first as Map);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> _sessionContribStats(int sessionId) async {
    // compute:
    // - cycle_contributions = SUM(amount)
    // - members_paid = COUNT(DISTINCT member_id)
    final rows = await sb
        .from('contributions')
        .select('member_id, amount')
        .eq('session_id', sessionId);

    if (rows is! List) return {'cycle_contributions': 0, 'members_paid': 0};

    num total = 0;
    final paidSet = <int>{};

    for (final r in rows) {
      if (r is Map) {
        final amt = r['amount'];
        final mid = r['member_id'];
        total += (amt is num ? amt : num.tryParse('$amt') ?? 0);
        final midInt = mid is int ? mid : int.tryParse('$mid');
        if (midInt != null) paidSet.add(midInt);
      }
    }

    return {
      'cycle_contributions': total,
      'members_paid': paidSet.length,
    };
  }

  Future<_DashData> _load() async {
    // load base views + app_state
    final results = await Future.wait([
      _single('v_dashboard_kpis'),
      _single('v_finance_kpis'),
      _list('v_next_beneficiary', limit: 1),
      _single('app_state'),
    ]);

    final dash = results[0] as Map<String, dynamic>;
    final finance = results[1] as Map<String, dynamic>;
    final nextRows = results[2] as List<Map<String, dynamic>>;
    final appState = results[3] as Map<String, dynamic>;

    // app_state values (REAL keys)
    final currentSessionId = _toInt(appState['current_session_id']);
    final nextMemberId = _toInt(appState['next_member_id']);

    // beneficiary details
    final beneficiary =
        nextMemberId > 0 ? await _memberById(nextMemberId) : <String, dynamic>{};

    // members count
    final totalMembers = await _count('members');

    // session contribution stats
    final contribStats =
        currentSessionId > 0 ? await _sessionContribStats(currentSessionId) : {'cycle_contributions': 0, 'members_paid': 0};

    return _DashData(
      dash: dash,
      finance: finance,
      nextBeneficiary: nextRows.isNotEmpty ? nextRows.first : {},
      appState: appState,
      beneficiary: beneficiary,
      totalMembers: totalMembers,
      cycleContributions: contribStats['cycle_contributions'] as num? ?? 0,
      membersPaid: contribStats['members_paid'] as int? ?? 0,
    );
  }

  int _toInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
  String s(dynamic v) => v == null ? '' : v.toString();
  num n(dynamic v) => v is num ? v : (num.tryParse('$v') ?? 0);

  String money(dynamic v) {
    final numVal = n(v);
    final hasCents = (numVal * 100).round() % 100 != 0;
    return hasCents ? '\$${numVal.toStringAsFixed(2)}' : '\$${numVal.toStringAsFixed(0)}';
  }

  String fmtTs(dynamic v) {
    if (v == null) return '—';
    try {
      final dt = DateTime.parse(v.toString()).toLocal();
      String two(int x) => x.toString().padLeft(2, '0');
      return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
    } catch (_) {
      return v.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<_DashData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error:\n${snap.error}', style: const TextStyle(color: Colors.redAccent)),
                ),
              );
            }

            final d = snap.data!;
            final dash = d.dash;
            final fin = d.finance;
            final next = d.nextBeneficiary;
            final ap = d.appState;

            // KPIs
            final totalContributed = money(dash['total_contributed']);
            final foundationBalance = money(dash['foundation_balance']);
            final outstandingLoans = money(dash['outstanding_loans']);
            final activeLoans = s(dash['active_loans']);

            // Finance
            final foundationTotal = money(fin['foundation_total']);
            final loanPaymentsTotal = money(fin['loan_payments_total']);
            final interestPaid = money(fin['interest_paid']);
            final finesPaidTotal = money(fin['fines_paid_total']);
            final outstandingPrincipal = money(fin['outstanding_principal']);
            final cashAvailable = money(fin['cash_available']);

            // Real app_state
            final currentSessionId = s(ap['current_session_id'] ?? '—');
            final beneficiaryId = s(ap['next_member_id'] ?? '—');
            final updatedAt = fmtTs(ap['updated_at']);

            final beneficiaryName = s(d.beneficiary['display_name'] ?? d.beneficiary['name'] ?? '—');

            final totalMembers = d.totalMembers == 0 ? '—' : '${d.totalMembers}';
            final membersPaidText = d.totalMembers > 0 ? '${d.membersPaid}/${d.totalMembers}' : '—';

            final cycleContrib = money(d.cycleContributions);
            final currentPot = cycleContrib; // same definition here

            // v_next_beneficiary fallback
            final nextName = s(next['member_name'] ?? next['name'] ?? next['display_name'] ?? '—');
            final nextId = s(next['member_id'] ?? next['id'] ?? '—');

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Dashboard",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => setState(() => _future = _load()),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Reload"),
                    )
                  ],
                ),
                const SizedBox(height: 10),

                // ✅ SESSION STRIP (what you want)
                _grid([
                  _card("Session ID", currentSessionId, Icons.event_repeat),
                  _card("Total Members", totalMembers, Icons.group),
                  _card("Members Paid", membersPaidText, Icons.verified),
                  _card("Current Pot", currentPot, Icons.account_balance_wallet),
                  _card("Cycle Contributions", cycleContrib, Icons.payments),
                  _card("Beneficiary", beneficiaryName, Icons.emoji_events),
                ]),
                const SizedBox(height: 6),
                Text("Last updated: $updatedAt", style: const TextStyle(color: Colors.white54, fontSize: 12)),

                const SizedBox(height: 22),
                const _SectionLabel(icon: Icons.insights, title: "Key KPIs"),
                const SizedBox(height: 12),
                _grid([
                  _card("Total Contributed", totalContributed, Icons.payments),
                  _card("Foundation Balance", foundationBalance, Icons.account_balance_wallet),
                  _card("Outstanding Loans", outstandingLoans, Icons.account_balance),
                  _card("Active Loans", activeLoans, Icons.stacked_line_chart),
                ]),

                const SizedBox(height: 26),
                const _SectionLabel(icon: Icons.account_balance_wallet, title: "Finance"),
                const SizedBox(height: 12),
                _grid([
                  _card("Foundation Total", foundationTotal, Icons.savings),
                  _card("Loan Payments Total", loanPaymentsTotal, Icons.receipt_long),
                  _card("Interest Paid", interestPaid, Icons.percent),
                  _card("Fines Paid Total", finesPaidTotal, Icons.gavel),
                  _card("Outstanding Principal", outstandingPrincipal, Icons.account_balance),
                  _card("Cash Available", cashAvailable, Icons.account_balance_wallet),
                ]),

                const SizedBox(height: 26),
                const _SectionLabel(icon: Icons.emoji_events, title: "Next Beneficiary"),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: _chip, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.emoji_events, color: _accent),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (beneficiaryName != '—') ? beneficiaryName : (nextName.isEmpty ? '—' : nextName),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Member ID: ${(beneficiaryId != '—') ? beneficiaryId : (nextId.isEmpty ? '—' : nextId)}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _grid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = w >= 1200 ? 4 : (w >= 850 ? 3 : (w >= 520 ? 2 : 1));
        final cardWidth = cols == 1 ? w : (w - (16 * (cols - 1))) / cols;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: children.map((c) => SizedBox(width: cardWidth, child: c)).toList(),
        );
      },
    );
  }

  Widget _card(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _chip, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _DashData {
  final Map<String, dynamic> dash;
  final Map<String, dynamic> finance;
  final Map<String, dynamic> nextBeneficiary;
  final Map<String, dynamic> appState;

  final Map<String, dynamic> beneficiary;
  final int totalMembers;
  final num cycleContributions;
  final int membersPaid;

  _DashData({
    required this.dash,
    required this.finance,
    required this.nextBeneficiary,
    required this.appState,
    required this.beneficiary,
    required this.totalMembers,
    required this.cycleContributions,
    required this.membersPaid,
  });
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionLabel({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white.withOpacity(0.85)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
      ],
    );
  }
}