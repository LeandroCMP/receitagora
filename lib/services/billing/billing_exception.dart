class BillingException implements Exception {
  BillingException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
