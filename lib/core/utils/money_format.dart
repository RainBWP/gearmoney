class MoneyFormatter {
  static String formatFromInt(int amount) {
    final doubleValue = amount / 100;
    return doubleValue.toStringAsFixed(2);
  }
  static int parseToInt(String amount) {
    final doubleValue = double.tryParse(amount);
    if (doubleValue == null) {
      throw FormatException('Invalid money format');
    }
    return (doubleValue * 100).round();
  }
}
