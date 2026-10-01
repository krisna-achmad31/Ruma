class MonthlyReportEntity {
  final String monthKey;
  final double totalWealth;
  final double cash;
  final double investment;
  final double income;
  final double expense;
  final double investmentContribution;
  final double endingBalance;
  final double wealthChangePercent;
  final Map<String, double> trend6Months;

  const MonthlyReportEntity({
    required this.monthKey,
    required this.totalWealth,
    required this.cash,
    required this.investment,
    required this.income,
    required this.expense,
    required this.investmentContribution,
    required this.endingBalance,
    required this.wealthChangePercent,
    required this.trend6Months,
  });
}
