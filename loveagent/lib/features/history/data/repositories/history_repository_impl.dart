import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/surprise.dart';
import '../../domain/repositories/history_repository.dart';
import '../models/surprise_model.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Surprise>> getSurprises() async {
    final response = await _client
        .from('surprises')
        .select('*, partners(name)')
        .order('date', ascending: false);

    return response
        .map((map) => SurpriseModel.fromMapWithPartner(map))
        .toList();
  }

  @override
  Future<List<Surprise>> getSurprisesByPartner(String partnerId) async {
    final response = await _client
        .from('surprises')
        .select()
        .eq('partner_id', partnerId)
        .order('date', ascending: false);

    return response.map((map) => SurpriseModel.fromMap(map)).toList();
  }

  @override
  Future<Surprise> createSurprise(Surprise surprise) async {
    final model = SurpriseModel(
      id: '',
      partnerId: surprise.partnerId,
      type: surprise.type,
      date: surprise.date,
      note: surprise.note,
      suggestedByAgent: surprise.suggestedByAgent,
      confirmedByUser: surprise.confirmedByUser,
    );

    final response = await _client
        .from('surprises')
        .insert(model.toInsertMap())
        .select()
        .single();

    return SurpriseModel.fromMap(response);
  }

  @override
  Future<Surprise> updateSurprise(Surprise surprise) async {
    final model = SurpriseModel(
      id: surprise.id,
      partnerId: surprise.partnerId,
      type: surprise.type,
      date: surprise.date,
      note: surprise.note,
      confirmedByUser: surprise.confirmedByUser,
    );

    final response = await _client
        .from('surprises')
        .update(model.toUpdateMap())
        .eq('id', surprise.id)
        .select()
        .single();

    return SurpriseModel.fromMap(response);
  }

  @override
  Future<void> deleteSurprise(String id) async {
    await _client.from('surprises').delete().eq('id', id);
  }
}
