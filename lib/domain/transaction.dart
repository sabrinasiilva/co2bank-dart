class Transaction {
  final String id;
  final String merchantCategoryCode;
  final double amount;
  final DateTime occurredAt;

  Transaction({
    required this.id,
    required this.merchantCategoryCode,
    required this.amount,
    required this.occurredAt,
  });
}
