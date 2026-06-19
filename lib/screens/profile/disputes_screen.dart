import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/dispute_service.dart';
import 'dispute_detail_screen.dart';

class DisputesScreen extends StatefulWidget {
  const DisputesScreen({super.key});

  @override
  State<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen> {
  final _service = DisputeService();
  List<Map<String, dynamic>> _disputes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _disputes = await _service.listMyDisputes();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('My Disputes',
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5)),
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
          : RefreshIndicator(
              onRefresh: _load,
              child: _disputes.isEmpty ? _buildEmpty() : _buildList(),
            ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Icon(Icons.gavel_rounded, size: 80, color: Colors.grey[200]),
        const SizedBox(height: 20),
        const Text('No Disputes',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.grey500)),
        const SizedBox(height: 8),
        const Text('Any disputes you raise will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.grey400, height: 1.5)),
      ],
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _disputes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _DisputeCard(
        dispute: _disputes[i],
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DisputeDetailScreen(disputeId: _disputes[i]['disputeId'] as String)),
          );
          _load();
        },
      ),
    );
  }
}

class _DisputeCard extends StatelessWidget {
  final Map<String, dynamic> dispute;
  final VoidCallback onTap;

  const _DisputeCard({required this.dispute, required this.onTap});

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

  @override
  Widget build(BuildContext context) {
    final status = dispute['status'] as String? ?? 'open';
    final subject = dispute['subject'] as String? ?? '';
    final category = dispute['category'] as String? ?? '';
    final disputeId = dispute['disputeId'] as String? ?? '';
    final thread = (dispute['thread'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final hasUnread = thread.isNotEmpty && thread.last['from'] == 'admin';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary)),
                ),
                const SizedBox(width: 8),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_categoryLabel(category),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey500)),
                ),
                const Spacer(),
                if (hasUnread) ...[
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  const Text('Admin replied', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(disputeId,
                style: const TextStyle(fontSize: 11, color: AppColors.grey400, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
