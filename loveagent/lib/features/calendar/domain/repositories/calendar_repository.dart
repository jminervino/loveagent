import '../entities/special_date.dart';

abstract class CalendarRepository {
  Future<List<SpecialDate>> getDatesByPartner(String partnerId);
  Future<List<SpecialDate>> getUpcomingDates({int days = 30});
  Future<SpecialDate> createDate(SpecialDate date);
  Future<SpecialDate> updateDate(SpecialDate date);
  Future<void> deleteDate(String id);
}
