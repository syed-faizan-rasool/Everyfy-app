import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/address_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/animated_widgets.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  List<AddressModel> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getAddresses();
    if (mounted) {
      setState(() {
        _addresses = list;
        _isLoading = false;
      });
      final auth = context.read<AuthProvider>();
      if (auth.selectedAddress == null && list.isNotEmpty) {
        final def = list.firstWhere((a) => a.isDefault, orElse: () => list.first);
        auth.setAddress(def);
      }
    }
  }

  void _openAddAddressSheet() {
    final addressLineController = TextEditingController();
    final areaController = TextEditingController();
    final cityController = TextEditingController(text: 'Gojra');
    String selectedLabel = 'Home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add New Address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Label Selector (Home / Work / Other)
                  Row(
                    children: ['Home', 'Work', 'Other'].map((label) {
                      final isSelected = selectedLabel == label;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedLabel = label);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: addressLineController,
                    decoration: const InputDecoration(
                      labelText: 'Street Address / House No.',
                      hintText: 'e.g. House 42, Street 8',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: areaController,
                    decoration: const InputDecoration(
                      labelText: 'Area / Sector',
                      hintText: 'e.g. Gulberg III, DHA Phase 5',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (addressLineController.text.trim().isEmpty || areaController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill out all address fields')),
                          );
                          return;
                        }

                        final newAddress = AddressModel(
                          id: 0,
                          label: selectedLabel,
                          addressLine: addressLineController.text.trim(),
                          area: areaController.text.trim(),
                          city: cityController.text.trim(),
                          isDefault: _addresses.isEmpty,
                        );

                        final nav = Navigator.of(context);
                        final sm = ScaffoldMessenger.of(context);
                        final auth = this.context.read<AuthProvider>();

                        final savedAddress = await ApiService.saveAddress(newAddress);
                        final finalAddr = savedAddress ?? newAddress;

                        if (mounted) {
                          setState(() {
                            _addresses.add(finalAddr);
                          });
                          auth.setAddress(finalAddr);
                          nav.pop();
                          sm.showSnackBar(
                            const SnackBar(content: Text('New delivery address saved!')),
                          );
                        }
                      },
                      child: const Text('Save & Select Address'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Delivery Address'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _addresses.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_off_rounded,
                              size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Saved Addresses',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Add your home or office address to receive fresh grocery delivery in 10-15 minutes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final address = _addresses[i];
                    final selected = auth.selectedAddress?.id == address.id;
                    return _AddressCard(
                      address: address,
                      selected: selected,
                      onTap: () {
                        context.read<AuthProvider>().setAddress(address);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: BouncingButton(
            onTap: _openAddAddressSheet,
            child: OutlinedButton.icon(
              onPressed: _openAddAddressSheet,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add New Address'),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final bool selected;
  final VoidCallback onTap;

  const _AddressCard({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (address.label.toLowerCase()) {
      case 'home':
        return Icons.home_rounded;
      case 'office':
      case 'work':
        return Icons.business_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.textPrimary.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryLight : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(),
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: selected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${address.addressLine}, ${address.area}, ${address.city}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.cardBorder,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
