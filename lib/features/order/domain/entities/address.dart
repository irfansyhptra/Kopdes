class Address {
  final String id;
  final String userId;
  final String title;
  final String recipientName;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final bool isDefault;

  const Address({
    required this.id,
    required this.userId,
    required this.title,
    required this.recipientName,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.isDefault,
  });
}
