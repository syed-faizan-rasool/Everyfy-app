class NotificationModel {
  final int id;
  final int? userId;
  final String role;
  final String title;
  final String message;
  final String type;
  final int? orderId;
  final String? orderNumber;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    this.userId,
    required this.role,
    required this.title,
    required this.message,
    this.type = 'order',
    this.orderId,
    this.orderNumber,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return NotificationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? ''),
      role: json['role']?.toString() ?? 'customer',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'order',
      orderId: json['order_id'] is int ? json['order_id'] : int.tryParse(json['order_id']?.toString() ?? ''),
      orderNumber: json['order_number']?.toString(),
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read'] == '1',
      createdAt: parsedDate,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      role: role,
      title: title,
      message: message,
      type: type,
      orderId: orderId,
      orderNumber: orderNumber,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

