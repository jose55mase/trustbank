class CreditOption {
  final String title;
  final String description;
  final double minAmount;
  final double maxAmount;
  final int minTermMonths;
  final int maxTermMonths;
  final double interestRate;
  final String icon;

  CreditOption({
    required this.title,
    required this.description,
    required this.minAmount,
    required this.maxAmount,
    required this.minTermMonths,
    required this.maxTermMonths,
    required this.interestRate,
    required this.icon,
  });
}