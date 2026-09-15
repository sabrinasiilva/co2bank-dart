class CarbonLimit {
  final String month;
  final double limitKgCo2e;
  final double consumedKgCo2e;

  CarbonLimit({
    required this.month,
    required this.limitKgCo2e,
    required this.consumedKgCo2e,
  });

  double get remainingKgCo2e => limitKgCo2e - consumedKgCo2e;
}
