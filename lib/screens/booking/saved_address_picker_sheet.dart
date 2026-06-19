import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product_model.dart';
import '../../services/address_service.dart';
import 'add_address_sheet.dart';

Future<AddressModel?> showSavedAddressPicker(BuildContext context) {
  return showModalBottomSheet<AddressModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SavedAddressPickerSheet(),
  );
}

class _SavedAddressPickerSheet extends StatefulWidget {
  const _SavedAddressPickerSheet();

  @override
  State<_SavedAddressPickerSheet> createState() => _SavedAddressPickerSheetState();
}

class _SavedAddressPickerSheetState extends State<_SavedAddressPickerSheet> {
  final _service = AddressService();
  List<AddressModel> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final saved = await _service.listAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = saved.map((s) => AddressModel(
          id: s.id,
          fullAddress: [
            if (s.flatNumber?.isNotEmpty == true) s.flatNumber!,
            if (s.society?.isNotEmpty == true) s.society!,
          ].join(', '),
          city: s.city,
          state: s.state ?? '',
          flatNumber: s.flatNumber,
          society: s.society,
          landmark: s.landmark,
          addressType: s.addressType,
          nickname: s.nickname,
          isDefault: s.isDefault,
          latitude: s.latitude,
          longitude: s.longitude,
        )).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Inside your _SavedAddressPickerSheetState class:
  Future<void> _openAddSheet() async {
    if (!mounted) return;
    
    // 🌟 UPDATED: Catch the AddressModel returned by the AddAddressSheet
    final AddressModel? newAddr = await showModalBottomSheet<AddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAddressSheet(onSaved: _load, existing: null),
    );

    // 🌟 NEW: If an address was created, immediately return it to selectOrAddAddress!
    if (newAddr != null && mounted) {
      Navigator.pop(context, newAddr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navBarHeight = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.82),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Choose Address',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.grey400, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 4),

          // Content
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
            )
          else if (_addresses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
              child: Column(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_off_rounded, color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(height: 16),
                  const Text('No saved addresses',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text('Add your first address to get started',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: _addresses.length,
                itemBuilder: (context, i) => _AddressTile(
                  address: _addresses[i],
                  showDefaultBadge: true,
                  onTap: () => Navigator.pop(context, _addresses[i]),
                ),
              ),
            ),

          // Sticky "Add New Address" button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[100]!, width: 1)),
            ),
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + navBarHeight),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openAddSheet,
                icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                label: const Text('Add New Address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.04),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final AddressModel address;
  final bool showDefaultBadge;
  final VoidCallback onTap;

  const _AddressTile({required this.address, required this.showDefaultBadge, required this.onTap});

  IconData get _icon {
    switch (address.addressType?.toLowerCase()) {
      case 'work': return Icons.work_outline_rounded;
      case 'other': return Icons.location_on_outlined;
      default: return Icons.home_rounded;
    }
  }

  String get _subtitle {
    final parts = <String>[];
    if (address.fullAddress.isNotEmpty) parts.add(address.fullAddress);
    if (address.landmark?.isNotEmpty == true) parts.add(address.landmark!);
    if (address.city.isNotEmpty) parts.add(address.city);
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: (showDefaultBadge && address.isDefault)
              ? AppColors.primary.withValues(alpha: 0.04)
              : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (showDefaultBadge && address.isDefault)
                ? AppColors.primary.withValues(alpha: 0.25)
                : const Color(0xFFEEEEEE),
            width: (showDefaultBadge && address.isDefault) ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: (showDefaultBadge && address.isDefault)
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(address.displayLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                      if (showDefaultBadge && address.isDefault) ...[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Default',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ),
                      ],
                    ],
                  ),
                  if (_subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(_subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.grey300, size: 22),
          ],
        ),
      ),
    );
  }
}
