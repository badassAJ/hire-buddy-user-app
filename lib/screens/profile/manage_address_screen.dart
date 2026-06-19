import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/saved_address.dart';
import '../../services/address_service.dart';
import '../booking/add_address_sheet.dart';

class ManageAddressScreen extends StatefulWidget {
  const ManageAddressScreen({super.key});

  @override
  State<ManageAddressScreen> createState() => _ManageAddressScreenState();
}

class _ManageAddressScreenState extends State<ManageAddressScreen> {
  final _service = AddressService();
  List<SavedAddress> _addresses = [];
  bool _isLoading = true;
  Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _addresses = await _service.listAddresses();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _delete(SavedAddress addr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Address', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text(
          'Remove "${addr.label}"? This cannot be undone.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _processingIds.add(addr.id));
    try {
      await _service.deleteAddress(addr.id);
      if (!mounted) return;
      setState(() => _addresses.removeWhere((a) => a.id == addr.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${addr.label}" deleted'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to delete address. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _processingIds.remove(addr.id));
    }
  }

  Future<void> _setDefault(SavedAddress addr) async {
    setState(() => _processingIds.add(addr.id));
    try {
      await _service.setDefault(addr.id);
      if (!mounted) return;
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update default. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _processingIds.remove(addr.id));
    }
  }

  void _openSheet({SavedAddress? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAddressSheet(existing: existing, onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navBarHeight = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Addresses',
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: _addresses.isEmpty ? _buildEmpty(navBarHeight) : _buildList(navBarHeight),
            ),
    );
  }

  Widget _buildList(double navBarHeight) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 100 + navBarHeight),
      children: [
        ..._addresses.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AddressCard(
                address: a,
                isProcessing: _processingIds.contains(a.id),
                onEdit: () => _openSheet(existing: a),
                onDelete: () => _delete(a),
                onSetDefault: a.isDefault ? null : () => _setDefault(a),
              ),
            )),
        if (_addresses.length < 5)
          _AddNewButton(onTap: () => _openSheet()),
      ],
    );
  }

  Widget _buildEmpty(double navBarHeight) {
    return ListView(
      padding: EdgeInsets.fromLTRB(32, 60, 32, 32 + navBarHeight),
      children: [
        Container(
          width: 80, height: 80,
          margin: const EdgeInsets.only(bottom: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_off_rounded, size: 40, color: AppColors.primary),
        ),
        const Text('No addresses saved',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text('Add your home, work or other addresses\nfor quick checkout.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5)),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () => _openSheet(),
          icon: const Icon(Icons.add_location_alt_rounded, size: 18),
          label: const Text('Add Address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}

class _AddNewButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddNewButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_location_alt_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text('Add New Address',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final SavedAddress address;
  final bool isProcessing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  const _AddressCard({
    required this.address,
    required this.isProcessing,
    required this.onEdit,
    required this.onDelete,
    this.onSetDefault,
  });

  IconData get _icon {
    switch (address.addressType) {
      case 'work': return Icons.work_outline_rounded;
      case 'other': return Icons.location_on_outlined;
      default: return Icons.home_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isProcessing ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(18),
          border: address.isDefault
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5)
              : Border.all(color: AppColors.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: address.isDefault
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.grey200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(address.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                      if (address.isDefault)
                        const SizedBox(height: 3),
                      if (address.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                  ),
                ),
                if (isProcessing)
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                else
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: AppColors.grey400, size: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    itemBuilder: (_) => [
                      if (onSetDefault != null)
                        const PopupMenuItem(
                          value: 'default',
                          child: Row(children: [
                            Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.primary),
                            SizedBox(width: 10),
                            Text('Set as Default', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ]),
                        ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                          SizedBox(width: 10),
                          Text('Edit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                          SizedBox(width: 10),
                          Text('Delete', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.error)),
                        ]),
                      ),
                    ],
                    onSelected: (val) {
                      if (val == 'default') onSetDefault?.call();
                      if (val == 'edit') onEdit();
                      if (val == 'delete') onDelete();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Text(
                address.displayLine,
                style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
              ),
            ),
            if (address.landmark?.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Text(
                  'Near ${address.landmark}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
