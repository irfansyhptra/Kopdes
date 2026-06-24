class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final ApiMetadata? metadata;

  ApiResponse({required this.success, this.message, this.data, this.metadata});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    final rawData = json['data'];
    return ApiResponse<T>(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
      data: rawData != null ? fromJsonT(rawData) : null,
      metadata: json['meta'] != null
          ? ApiMetadata.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ApiMetadata {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  ApiMetadata({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory ApiMetadata.fromJson(Map<String, dynamic> json) {
    return ApiMetadata(
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}
