class AddressModel {
  final int id;
  final String label; // Home, Work, Other
  final String addressLine;
  final String area;
  final String city;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.label,
    required this.addressLine,
    required this.area,
    required this.city,
    this.isDefault = false,
  });
}
