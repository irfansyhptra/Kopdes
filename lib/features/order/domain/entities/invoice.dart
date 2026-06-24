class Invoice {
  final String id;
  final String orderId;
  final String invoiceNumber;
  final String? pdfUrl;
  final DateTime issuedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Invoice({
    required this.id,
    required this.orderId,
    required this.invoiceNumber,
    this.pdfUrl,
    required this.issuedAt,
    required this.createdAt,
    required this.updatedAt,
  });
}
