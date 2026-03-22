abstract class AppConstants {
  static const String appName = 'LoveAgent';
  static const int maxPhotosPartner = 3;
  static const int maxBioLength = 500;
  static const List<int> reminderDays = [30, 15, 7, 1];
  static const String agentCronSchedule = '0 8 * * *'; // daily at 08h
}
