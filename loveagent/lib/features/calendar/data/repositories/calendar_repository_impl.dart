import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/special_date.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../models/special_date_model.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  CalendarRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<SpecialDate>> getDatesByPartner(String partnerId) async {
    final response = await _client
        .from('special_dates')
        .select()
        .eq('partner_id', partnerId)
        .order('date');

    return response.map((map) => SpecialDateModel.fromMap(map)).toList();
  }

  @override
  Future<List<SpecialDate>> getUpcomingDates({int days = 30}) async {
    final userId = _client.auth.currentUser!.id;

    final response = await _client.rpc('get_upcoming_dates', params: {
      'p_user_id': userId,
      'p_days': days,
    });

    return (response as List)
        .map((map) =>
            SpecialDateModel.fromUpcomingMap(map as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SpecialDate> createDate(SpecialDate date) async {
    final model = SpecialDateModel(
      id: '',
      partnerId: date.partnerId,
      label: date.label,
      date: date.date,
      isAnnual: date.isAnnual,
    );

    final response = await _client
        .from('special_dates')
        .insert(model.toInsertMap())
        .select()
        .single();

    return SpecialDateModel.fromMap(response);
  }

  @override
  Future<SpecialDate> updateDate(SpecialDate date) async {
    final model = SpecialDateModel(
      id: date.id,
      partnerId: date.partnerId,
      label: date.label,
      date: date.date,
      isAnnual: date.isAnnual,
    );

    final response = await _client
        .from('special_dates')
        .update(model.toUpdateMap())
        .eq('id', date.id)
        .select()
        .single();

    return SpecialDateModel.fromMap(response);
  }

  @override
  Future<void> deleteDate(String id) async {
    await _client.from('special_dates').delete().eq('id', id);
  }
}
