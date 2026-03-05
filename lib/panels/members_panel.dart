import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MembersPanel extends StatefulWidget {
  const MembersPanel({super.key});

  @override
  State<MembersPanel> createState() => _MembersPanelState();
}

class _MembersPanelState extends State<MembersPanel> {
  SupabaseClient get sb => Supabase.instance.client;

  final _search = TextEditingController();
  late Future<_MembersData> _future;

  // Match Dashboard palette
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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<_MembersData> _load() async {
    final res = await Future.wait([
      sb
          .from('v_member_financial_totals')
          .select()
          .order('member_id', ascending: true)
          .limit(2000)
          .timeout(const Duration(seconds: 12)),
      sb.from('app_state').select().limit(1).timeout(const Duration(seconds: 12)),
    ]);

    final rowsRaw = res[0];
    final appRaw = res[1];

    final rows = <Map<String, dynamic>>[];
    if (rowsRaw is List) {
      for (final e in rowsRaw) {
        if (e is Map) rows.add(Map<String, dynamic>.from(e));
      }
    }

    Map<String, dynamic> ap = {};
    if (appRaw is List && appRaw.isNotEmpty && appRaw.first is Map) {
      ap = Map<String, dynamic>.from(appRaw.first as Map);
    }

    final nextMemberId = _toInt(ap['next_member_id']);

    // Summary totals + map id->name for KPI
    num sumContrib = 0;
    num sumFoundation = 0;
    final idToName = <int, String>{};

    for (final r in rows) {
      sumContrib += _toNum(r['contrib_total']);
      sumFoundation += _toNum(r['foundation_total']);

      final id = _toInt(r['member_id']);
      final nm = _pickMemberName(r, fallbackId: id);
      if (id != 0 && nm.trim().isNotEmpty) idToName[id] = nm.trim();
    }

    final nextMemberName = nextMemberId == 0 ? '' : (idToName[nextMemberId] ?? '');

    return _MembersData(
      rows: rows,
      nextMemberId: nextMemberId,
      nextMemberName: nextMemberName,
      totalMembers: rows.length,
      sumContrib: sumContrib,
      sumFoundation: sumFoundation,
    );
  }

  // ---------- helpers ----------
  static int _toInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
  static num _toNum(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;

  String s(dynamic v) => v == null ? '' : v.toString();

  String _pickMemberName(Map<String, dynamic> r, {required int fallbackId}) {
    final memberName = s(r['member_name']);
    if (memberName.isNotEmpty) return memberName;

    final display = s(r['display_name']);
    if (display.isNotEmpty) return display;

    final name = s(r['name']);
    if (name.isNotEmpty) return name;

    return 'Member $fallbackId';
  }

  // ✅ ONLY LAST 4 DIGITS (NO +, NO SPACES)
  String last4Phone(String phone) {
    if (phone.isEmpty) return '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return digits;
    return digits.substring(digits.length - 4);
  }

  String money(dynamic v) {
    final numVal = _toNum(v);
    final hasCents = (numVal * 100).round() % 100 != 0;
    final txt = hasCents ? numVal.toStringAsFixed(2) : numVal.toStringAsFixed(0);

    // simple comma formatting without intl dependency
    final parts = txt.split('.');
    final whole = parts[0];
    final sign = whole.startsWith('-') ? '-' : '';
    final digits = sign.isEmpty ? whole : whole.substring(1);
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final idxFromEnd = digits.length - i;
      buf.write(digits[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    final wholeFmt = '$sign${buf.toString()}';
    return parts.length == 2 ? '\$$wholeFmt.${parts[1]}' : '\$$wholeFmt';
  }

  bool _matches(Map<String, dynamic> r, String q) {
    if (q.isEmpty) return true;
    final id = s(r['member_id']);
    final name = _pickMemberName(r, fallbackId: _toInt(r['member_id']));
    final phone = s(r['phone']);
    final hay = '${id.toLowerCase()} ${name.toLowerCase()} ${phone.toLowerCase()}';
    return hay.contains(q.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Members',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => setState(() => _future = _load()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search
            TextField(
              controller: _search,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                hintText: 'Search by id, name…',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: _cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _accent),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 12),

            FutureBuilder<_MembersData>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'ERROR:\n\n${snap.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                final data = snap.data!;
                final q = _search.text.trim();
                final rows = q.isEmpty ? data.rows : data.rows.where((r) => _matches(r, q)).toList();

                final nextText = data.nextMemberId == 0
                    ? '—'
                    : '${data.nextMemberName} (ID: ${data.nextMemberId})';

                // Summary strip
                final chips = [
                  _miniStat('Total', '${data.totalMembers}', Icons.group),
                  _miniStat('Contrib', money(data.sumContrib), Icons.payments),
                  _miniStat('Foundation', money(data.sumFoundation), Icons.savings),
                  _miniStat('Next Beneficiary', nextText, Icons.emoji_events),
                ];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _wrapRow(chips),
                    const SizedBox(height: 12),

                    if (rows.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No members found.', style: TextStyle(color: Colors.white70)),
                      )
                    else
                      ...rows.map((r) {
                        final memberId = _toInt(r['member_id']);
                        final isBeneficiary = memberId != 0 && memberId == data.nextMemberId;

                        final memberName = _pickMemberName(r, fallbackId: memberId);

                        // ✅ last 4 digits ONLY
                        final phoneLast4 = last4Phone(s(r['phone']));

                        final contribTotal = money(r['contrib_total']);
                        final foundationTotal = money(r['foundation_total']);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isBeneficiary ? _accent : _border, width: isBeneficiary ? 1.5 : 1),
                            boxShadow: isBeneficiary
                                ? [
                                    BoxShadow(
                                      color: _accent.withOpacity(0.18),
                                      blurRadius: 18,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : const [],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _chip,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isBeneficiary ? Icons.emoji_events : Icons.person,
                                  color: _accent,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            memberName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isBeneficiary)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: _chip,
                                              borderRadius: BorderRadius.circular(999),
                                              border: Border.all(color: _accent),
                                            ),
                                            child: const Text(
                                              'NEXT BENEFICIARY',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),

                                    // ✅ THIS IS THE LINE THAT HIDES FULL PHONE
                                    Text(
                                      'ID: $memberId${phoneLast4.isNotEmpty ? ' • $phoneLast4' : ''}',
                                      style: const TextStyle(color: Colors.white70),
                                    ),

                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 8,
                                      children: [
                                        _pill('Contrib', contribTotal, Icons.payments),
                                        _pill('Foundation', foundationTotal, Icons.savings),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 6),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _wrapRow(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = w >= 1200 ? 4 : (w >= 850 ? 3 : (w >= 520 ? 2 : 1));
        final cardWidth = cols == 1 ? w : (w - (12 * (cols - 1))) / cols;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children.map((x) => SizedBox(width: cardWidth, child: x)).toList(),
        );
      },
    );
  }

  Widget _miniStat(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _chip,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _chip,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _accent, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MembersData {
  final List<Map<String, dynamic>> rows;
  final int nextMemberId;
  final String nextMemberName;
  final int totalMembers;
  final num sumContrib;
  final num sumFoundation;

  _MembersData({
    required this.rows,
    required this.nextMemberId,
    required this.nextMemberName,
    required this.totalMembers,
    required this.sumContrib,
    required this.sumFoundation,
  });
}