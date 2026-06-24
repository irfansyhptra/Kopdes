import '../../domain/entities/invoice.dart';

class InvoiceModel extends Invoice {
  const InvoiceModel({
    required super.id,
    required super.orderId,
    required super.invoiceNumber,
    super.pdfUrl,
    required super.issuedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String? ?? '',
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      pdfUrl: json['pdfUrl'] as String?,
      issuedAt: json['issuedAt'] != null
          ? DateTime.parse(json['issuedAt'] as String)
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'invoiceNumber': invoiceNumber,
      'pdfUrl': pdfUrl,
      'issuedAt': issuedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Invoice toEntity() {
    return Invoice(
      id: id,
      orderId: orderId,
      invoiceNumber: invoiceNumber,
      pdfUrl: pdfUrl,
      issuedAt: issuedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
