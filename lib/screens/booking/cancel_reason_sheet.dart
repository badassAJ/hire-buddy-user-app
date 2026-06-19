import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

const _bookingReasons = [
  ('Changed my mind', 'changed_mind'),
  ('Found a cheaper option', 'cheaper_option'),
  ('Provider not responding', 'provider_not_responding'),
  ('Scheduled wrong date/time', 'wrong_schedule'),
  ('Emergency / personal reason', 'emergency'),
  ('Other', 'other'),
];

const _orderReasons = [
  ('Ordered by mistake', 'ordered_by_mistake'),
  ('Found better price elsewhere', 'cheaper_option'),
  ('Delivery taking too long', 'delivery_delay'),
  ('Item no longer needed', 'no_longer_needed'),
  ('Other', 'other'),
];

Future<String?> showCancelReasonSheet(
  BuildContext context, {
  required bool isOrder,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CancelReasonSheet(isOrder: isOrder),
  );
}

class _CancelReasonSheet extends StatefulWidget {
  final bool isOrder;
  const _CancelReasonSheet({required this.isOrder});

  @override
  State<_CancelReasonSheet> createState() => _CancelReasonSheetState();
}

class _CancelReasonSheetState extends State<_CancelReasonSheet> {
  int? _selectedIndex;
  final _otherController = TextEditingController();

  List<(String, String)> get _reasons =>
      widget.isOrder ? _orderReasons : _bookingReasons;

  bool get _isOtherSelected =>
      _selectedIndex != null && _reasons[_selectedIndex!].$2 == 'other';

  String? get _confirmReason {
    if (_selectedIndex == null) return null;
    if (_isOtherSelected) {
      final txt = _otherController.text.trim();
      return txt.isEmpty ? null : txt;
    }
    return _reasons[_selectedIndex!].$1;
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final navBarHeight = MediaQuery.of(context).viewPadding.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isOrder ? 'Cancel Order' : 'Cancel Booking',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Please select a reason below',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 22),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey[100]),
            const SizedBox(height: 8),

            // Reason list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _reasons.length,
              itemBuilder: (context, i) {
                final (label, _) = _reasons[i];
                final selected = _selectedIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? Colors.red.withValues(alpha: 0.04) : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? Colors.red.withValues(alpha: 0.4) : const Color(0xFFEEEEEE),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected ? Colors.red : Colors.white,
                            border: Border.all(
                              color: selected ? Colors.red : Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          child: selected
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? Colors.red.shade700 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // "Other" free text field
            if (_isOtherSelected)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: TextField(
                  controller: _otherController,
                  maxLength: 200,
                  maxLines: 3,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Describe your reason…',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    counterStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),

            // Buttons
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + navBarHeight),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmReason == null
                          ? null
                          : () => Navigator.pop(context, _confirmReason),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        disabledBackgroundColor: Colors.grey[100],
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.grey[400],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        widget.isOrder ? 'Confirm Cancellation' : 'Cancel Booking',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        widget.isOrder ? 'Keep My Order' : 'Keep My Booking',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
