class TimeStampHandler {
  static String getStringFromSecond(double second) => second < 60
      ? '${second.toInt()}s'
      : second == 60 ? '1m' : '${second ~/ 60}m ${(second % 60).toInt()}s';
}
