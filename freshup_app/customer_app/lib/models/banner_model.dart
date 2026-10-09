class BannerModel {
  final int id;
  final String title;
  final String subtitle;
  final String image;
  final int? linkProductId;

  BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    this.linkProductId,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      image: json['image'] ?? '',
      linkProductId: json['link_product_id'] != null
          ? int.tryParse(json['link_product_id'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image': image,
      'link_product_id': linkProductId,
    };
  }
}
