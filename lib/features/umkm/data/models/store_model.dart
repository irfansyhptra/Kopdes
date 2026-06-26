class StoreModel {
  final String id;
  final String userId;
  final String businessName;
  final String description;
  final String address;
  final String phone;
  final String status;

  const StoreModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.description,
    required this.address,
    required this.phone,
    required this.status,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      businessName: json['businessName'] as String,
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING_VERIFICATION',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'businessName': businessName,
      'description': description,
      'address': address,
      'phone': phone,
      'status': status,
    };
  }
}
