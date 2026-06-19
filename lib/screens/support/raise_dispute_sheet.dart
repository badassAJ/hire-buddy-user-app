import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/dispute_service.dart';

class RaiseDisputeSheet extends StatefulWidget {
  final String bookingId;
  final String? serviceName;

  const RaiseDisputeSheet({
    super.key,
    required this.bookingId,
    this.serviceName,
  });

  @override
  State<RaiseDisputeSheet> createState() => _RaiseDisputeSheetState();
}

class _RaiseDisputeSheetState extends State<RaiseDisputeSheet> {
  final _disputeService = DisputeService();
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  bool _submitting = false;
  String? _selectedCategory;

  static const _categories = [
    ('payment_issue', 'Payment Issue', Icons.payment_outlined),
    ('service_quality', 'Service Quality', Icons.star_outline_rounded),
    ('provider_no_show', 'Provider Didn\'t Show', Icons.person_off_outlined),
    ('cancellation', 'Cancellation Issue', Icons.cancel_outlined),
    ('damage', 'Property Damage', Icons.home_outlined),
    ('behavior', 'Provider Behavior', Icons.report_outlined),
    ('other', 'Other', Icons.help_outline_rounded),
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) {
      _showSnack('Please select a category');
      return;
    }
    if (_subjectController.text.trim().isEmpty) {
      _showSnack('Please enter a subject');
      return;
    }
    if (_descController.text.trim().isEmpty) {
      _showSnack('Please describe the issue');
      return;
    }

    setState(() => _submitting = true);
    final result = await _disputeService.raiseDispute(
      bookingId: widget.bookingId,
      category: _selectedCategory!,
      subject: _subjectController.text.trim(),
      description: _descController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['success'] == true) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dispute raised. Our team will review it shortly.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showSnack(result['message'] ?? 'Failed to raise dispute');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final navBarHeight = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: keyboardHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 32 + navBarHeight),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Raise a Dispute',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            if (widget.serviceName != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.serviceName!,
                style: TextStyle(fontSize: 13, color: AppColors.grey500),
              ),
            ],
            const SizedBox(height: 24),

            // Category
            const Text('What\'s the issue?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final (value, label, icon) = cat;
                final selected = _selectedCategory == value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? Colors.black : AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? Colors.black : AppColors.grey200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: selected ? Colors.white : AppColors.grey500),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Subject
            const Text('Subject', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: 'Brief description of the issue',
                hintStyle: TextStyle(color: AppColors.grey400, fontSize: 14),
                filled: true,
                fillColor: AppColors.grey50,
                counterStyle: TextStyle(color: AppColors.grey400, fontSize: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Description
            const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Describe what happened in detail...',
                hintStyle: TextStyle(color: AppColors.grey400, fontSize: 14),
                filled: true,
                fillColor: AppColors.grey50,
                counterStyle: TextStyle(color: AppColors.grey400, fontSize: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Submit Dispute', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
