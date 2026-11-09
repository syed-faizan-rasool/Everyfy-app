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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'address_line': addressLine,
      'area': area,
      'city': city,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      label: json['label'] ?? 'Home',
      addressLine: json['address_line'] ?? json['addressLine'] ?? '',
      area: json['area'] ?? '',
      city: json['city'] ?? 'Gojra',
      isDefault: json['is_default'] == 1 || json['is_default'] == true || json['isDefault'] == true,
    );
  }
}
