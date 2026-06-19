import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../services/dispute_service.dart';

class DisputeDetailScreen extends StatefulWidget {
  final String disputeId;
  const DisputeDetailScreen({super.key, required this.disputeId});

  @override
  State<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends State<DisputeDetailScreen> {
  final _service = DisputeService();
  final _replyCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  Map<String, dynamic>? _dispute;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _dispute = await _service.getDispute(widget.disputeId);
    if (mounted) {
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    final result = await _service.replyToDispute(widget.disputeId, text);
    if (!mounted) return;
    if (result['success'] == true) {
      _replyCtrl.clear();
      _dispute = result['data'] as Map<String, dynamic>;
      setState(() => _isSending = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to send'), backgroundColor: AppColors.error),
      );
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'open': return const Color(0xFFEF4444);
      case 'investigating': return const Color(0xFFF59E0B);
      case 'resolved': return AppColors.success;
      case 'closed': return AppColors.grey400;
      default: return AppColors.grey400;
    }
  }

  String _categoryLabel(String c) =>
      c.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM, hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(widget.disputeId,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary, letterSpacing: -0.3)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 22),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.grey100),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _dispute == null
              ? const Center(child: Text('Dispute not found'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final d = _dispute!;
    final status = d['status'] as String? ?? 'open';
    final isClosed = status == 'resolved' || status == 'closed';
    final thread = (d['thread'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final resolution = d['resolution'] as Map<String, dynamic>?;

    return Column(
      children: [
        // Info card
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(d['subject'] as String? ?? '',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(status.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _statusColor(status))),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(_categoryLabel(d['category'] as String? ?? ''),
                  style: const TextStyle(fontSize: 12, color: AppColors.grey500, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(d['description'] as String? ?? '',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
              if (resolution != null && resolution['decision'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Resolution', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.success)),
                      const SizedBox(height: 4),
                      Text(resolution['decision'] as String? ?? '',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Thread
        Expanded(
          child: thread.isEmpty
              ? const Center(
                  child: Text('No messages yet.\nAdmin will respond soon.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey400, fontSize: 13, height: 1.5)),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: thread.length,
                  itemBuilder: (_, i) => _MessageBubble(message: thread[i], formatTime: _formatTime),
                ),
        ),

        // Reply box
        if (!isClosed)
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyCtrl,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Write a reply...',
                      hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.grey50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isSending ? null : _sendReply,
                  child: Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            child: const Text('This dispute is closed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.grey400, fontWeight: FontWeight.w500)),
          ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final String Function(String?) formatTime;

  const _MessageBubble({required this.message, required this.formatTime});

  @override
  Widget build(BuildContext context) {
    final isUser = message['from'] == 'user';
    final text = message['text'] as String? ?? '';
    final time = formatTime(message['sentAt'] as String?);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('Support Team',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ),
            Text(text,
                style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isUser ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(time,
                style: TextStyle(
                    fontSize: 10,
                    color: isUser ? Colors.white.withValues(alpha: 0.7) : AppColors.grey400)),
          ],
        ),
      ),
    );
  }
}
