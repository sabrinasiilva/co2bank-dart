import '../core/api_client.dart';
import '../core/token_storage.dart';

class TransactionItem {
  final String id;
  final String merchantName;
  final String categoryLabel;
  final double amount;
  final double co2Kg;
  final DateTime occurredAt;

  const TransactionItem({
    required this.id,
    required this.merchantName,
    required this.categoryLabel,
    required this.amount,
    required this.co2Kg,
    required this.occurredAt,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) =>
      TransactionItem(
        id: json['id'] as String,
        merchantName: json['merchant_name'] as String? ?? '',
        categoryLabel: json['category_label'] as String? ?? 'Outros',
        amount: (json['amount'] as num).toDouble(),
        co2Kg: (json['co2_kg'] as num).toDouble(),
        occurredAt: DateTime.parse(json['occurred_at'] as String),
      );
}

class CategorySummary {
  final String category;
  final double co2Kg;

  const CategorySummary({required this.category, required this.co2Kg});

  factory CategorySummary.fromJson(Map<String, dynamic> json) =>
      CategorySummary(
        category: json['category'] as String,
        co2Kg: (json['co2_kg'] as num).toDouble(),
      );
}

class MonthlySummary {
  final int month;
  final int year;
  final double totalCo2Kg;
  final double limitKg;
  final double percentageUsed;
  final double totalSpentBrl;
  final int transactionsCount;
  final List<CategorySummary> topCategories;

  const MonthlySummary({
    required this.month,
    required this.year,
    required this.totalCo2Kg,
    required this.limitKg,
    required this.percentageUsed,
    required this.totalSpentBrl,
    required this.transactionsCount,
    required this.topCategories,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) => MonthlySummary(
        month: json['month'] as int,
        year: json['year'] as int,
        totalCo2Kg: (json['total_co2_kg'] as num).toDouble(),
        limitKg: (json['limit_kg'] as num).toDouble(),
        percentageUsed: (json['percentage_used'] as num).toDouble(),
        totalSpentBrl: (json['total_spent_brl'] as num).toDouble(),
        transactionsCount: json['transactions_count'] as int,
        topCategories: (json['top_categories'] as List)
            .map((e) => CategorySummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class LimitAlert {
  final bool alert;
  final String? message;

  const LimitAlert({required this.alert, this.message});

  factory LimitAlert.fromJson(Map<String, dynamic> json) => LimitAlert(
        alert: json['alert'] as bool,
        message: json['message'] as String?,
      );
}

class TransactionService {
  final ApiClient _client;

  TransactionService._(this._client);

  static Future<TransactionService> authenticated() async {
    final client = ApiClient();
    final token = await TokenStorage.get();
    if (token != null) client.setToken(token);
    return TransactionService._(client);
  }

  Future<List<TransactionItem>> listTransactions({int? month, int? year}) async {
    var path = '/transactions';
    final params = <String>[];
    if (month != null) params.add('month=$month');
    if (year != null) params.add('year=$year');
    if (params.isNotEmpty) path += '?${params.join('&')}';

    try {
      final response = await _client.get(path);
      if (!response.ok) return [];
      return response.bodyList
          .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<MonthlySummary?> monthlySummary({required int month, required int year}) async {
    try {
      final response =
          await _client.get('/summary/monthly?month=$month&year=$year');
      if (response.ok) return MonthlySummary.fromJson(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<LimitAlert?> checkLimit() async {
    try {
      final response = await _client.post('/check-limit', {});
      if (response.ok) return LimitAlert.fromJson(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<TransactionItem?> createTransaction({
    required String merchantName,
    required String merchantCategoryCode,
    required double amount,
    DateTime? occurredAt,
  }) async {
    try {
      final body = <String, dynamic>{
        'merchant_name': merchantName,
        'merchant_category_code': merchantCategoryCode,
        'amount': amount,
        if (occurredAt != null) 'occurred_at': occurredAt.toIso8601String(),
      };
      final response = await _client.post('/transactions', body);
      if (response.ok) return TransactionItem.fromJson(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }
}
