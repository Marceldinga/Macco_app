import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LlmPanelPage extends StatefulWidget {
  const LlmPanelPage({super.key});

  @override
  State<LlmPanelPage> createState() => _LlmPanelPageState();
}

class _LlmPanelPageState extends State<LlmPanelPage> {
  // ✅ Put your Railway API base URL here
  static const String apiBaseUrl = String.fromEnvironment(
    'YOUNCHAT_API_URL',
    defaultValue: 'https://theyoungshallgrow-api-production.up.railway.app',
  );

  String schema = 'public';

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool _loading = false;
  String? _lastMemberId;

  final List<_ChatMsg> _messages = [
    _ChatMsg.assistant("Hello 👋🏽 I’m younchat — your Njangi assistant."),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(_ChatMsg.user(text));
      _loading = true;
      _controller.clear();
    });
    _scrollToBottom();

    final history = _messages
        .where((m) => m.role == 'user' || m.role == 'assistant')
        .take(30)
        .toList();
    final trimmed =
        history.length > 10 ? history.sublist(history.length - 10) : history;

    final payload = {
      "message": text,
      "schema": schema,
      "last_member_id": _lastMemberId,
      "history": trimmed.map((m) => {"role": m.role, "content": m.content}).toList(),
    };

    try {
      final uri = Uri.parse("${apiBaseUrl.replaceAll(RegExp(r'/+$'), '')}/chat");
      final res = await http
          .post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 70));

      if (res.statusCode >= 400) {
        _addAssistantError("HTTP ${res.statusCode}: ${res.body}");
        return;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final reply = (data["reply"] ?? "").toString();
      final usedSource = (data["used_source"] ?? "").toString();
      final memberIdFocus = data["member_id_focus"]?.toString();
      final dataframe = data["dataframe"];

      if (memberIdFocus != null && memberIdFocus.isNotEmpty) {
        _lastMemberId = memberIdFocus;
      }

      setState(() {
        _messages.add(
          _ChatMsg.assistant(
            reply.isEmpty ? "Hello 👋🏽" : reply,
            usedSource: usedSource,
            dataframe: dataframe is Map<String, dynamic> ? dataframe : null,
          ),
        );
      });
    } catch (e) {
      _addAssistantError("Request failed: $e");
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _addAssistantError(String msg) {
    setState(() {
      _messages.add(_ChatMsg.assistant("Hello 👋🏽 $msg", usedSource: "client:error"));
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 250,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _useExample(String example) {
    _controller.text = example;
    _send();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D14),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0B0D14),
        title: const Text(
          "younchat • LLM Panel",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: "Clear chat",
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                _messages
                  ..clear()
                  ..add(_ChatMsg.assistant("Hello 👋🏽 I’m younchat — your Njangi assistant."));
                _lastMemberId = null;
              });
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          // ✅ Premium gradient background
          const _FintechBackground(),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: _HeaderCard(
                  schema: schema,
                  lastMemberId: _lastMemberId,
                  onSchemaChanged: (v) => setState(() => schema = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: _ExamplesRow(onPick: _useExample),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E111B).withOpacity(0.70),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      itemCount: _messages.length + (_loading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_loading && index == _messages.length) {
                          return _ThinkingBubble(
                            bg: const Color(0xFF151A28),
                            fg: cs.onSurface,
                          );
                        }
                        final msg = _messages[index];
                        return _ChatBubble(msg: msg);
                      },
                    ),
                  ),
                ),
              ),
              _Composer(
                controller: _controller,
                loading: _loading,
                onSend: _send,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FintechBackground extends StatelessWidget {
  const _FintechBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF070912),
            Color(0xFF0B0D14),
            Color(0xFF0F1220),
            Color(0xFF090B12),
          ],
        ),
      ),
      child: Stack(
        children: [
          // soft glow
          Positioned(
            left: -140,
            top: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C4DFF).withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            right: -160,
            bottom: -160,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E5A8).withOpacity(0.08),
              ),
            ),
          ),
          // subtle noise blur feel
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String schema;
  final String? lastMemberId;
  final ValueChanged<String> onSchemaChanged;

  const _HeaderCard({
    required this.schema,
    required this.lastMemberId,
    required this.onSchemaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border = Colors.white.withOpacity(0.10);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E111B).withOpacity(0.70),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: TextEditingController(text: schema),
              onChanged: onSchemaChanged,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: "Schema",
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.70)),
                hintText: "public",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.40)),
                filled: true,
                fillColor: const Color(0xFF12162A).withOpacity(0.65),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.22)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF12162A).withOpacity(0.65),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Text(
              "last_member_id: ${lastMemberId ?? '—'}",
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.80),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamplesRow extends StatelessWidget {
  final ValueChanged<String> onPick;

  const _ExamplesRow({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final examples = const [
      "members",
      "verify member 2",
      "loans",
      "finance kpis",
      "tables",
      "show contributions",
      "describe loans",
      "How are we doing?",
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: examples.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final e = examples[i];
          return _NiceChip(
            label: e,
            onTap: () => onPick(e),
          );
        },
      ),
    );
  }
}

class _NiceChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NiceChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final border = Colors.white.withOpacity(0.10);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0E111B).withOpacity(0.70),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.90),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  final Color bg;
  final Color fg;

  const _ThinkingBubble({required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white.withOpacity(0.75),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Thinking…",
              style: TextStyle(color: fg.withOpacity(0.85), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.loading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final border = Colors.white.withOpacity(0.10);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0D14),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !loading,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: "Ask younchat… (ex: members, loans, finance kpis)",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
                  filled: true,
                  fillColor: const Color(0xFF12162A).withOpacity(0.65),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.22)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: loading ? null : onSend,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.send, size: 18),
                    SizedBox(width: 8),
                    Text("Send", style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMsg msg;

  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == "user";

    final bg = isUser ? const Color(0xFF6D5EF9).withOpacity(0.28) : const Color(0xFF151A28);
    final border = Colors.white.withOpacity(0.10);

    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: align,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 780),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              msg.content,
              style: TextStyle(
                fontSize: 14,
                height: 1.30,
                color: Colors.white.withOpacity(0.92),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!isUser && (msg.usedSource?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              Text(
                "source: ${msg.usedSource}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (!isUser && msg.dataframe != null) ...[
              const SizedBox(height: 10),
              _DfCard(df: msg.dataframe!),
            ],
          ],
        ),
      ),
    );
  }
}

class _DfCard extends StatelessWidget {
  final Map<String, dynamic> df;

  const _DfCard({required this.df});

  @override
  Widget build(BuildContext context) {
    final title = (df["title"] ?? "Data").toString();
    final colsRaw = df["columns"];
    final rowsRaw = df["rows"];

    final columns = (colsRaw is List) ? colsRaw.map((e) => e.toString()).toList() : <String>[];
    final rows = (rowsRaw is List)
        ? rowsRaw
            .cast<Map>()
            .map((r) => r.map((k, v) => MapEntry(k.toString(), v)))
            .toList()
        : <Map<String, dynamic>>[];

    final maxCols = columns.length > 10 ? columns.sublist(0, 10) : columns;
    final maxRows = rows.length > 25 ? rows.sublist(0, 25) : rows;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1321),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.90))),
          const SizedBox(height: 10),
          if (maxCols.isEmpty)
            Text("No columns returned.", style: TextStyle(color: Colors.white.withOpacity(0.75)))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
          if (rows.length > maxRows.length || columns.length > maxCols.length) ...[
            const SizedBox(height: 8),
            Text(
              "Showing ${maxRows.length}/${rows.length} rows and ${maxCols.length}/${columns.length} columns",
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55), fontWeight: FontWeight.w600),
            )
          ]
        ],
      ),
    );
  }
}

class _ChatMsg {
  final String role; // "user" or "assistant"
  final String content;
  final String? usedSource;
  final Map<String, dynamic>? dataframe;

  const _ChatMsg({
    required this.role,
    required this.content,
    this.usedSource,
    this.dataframe,
  });

  factory _ChatMsg.user(String text) => _ChatMsg(role: "user", content: text);

  factory _ChatMsg.assistant(
    String text, {
    String? usedSource,
    Map<String, dynamic>? dataframe,
  }) =>
      _ChatMsg(role: "assistant", content: text, usedSource: usedSource, dataframe: dataframe);
}