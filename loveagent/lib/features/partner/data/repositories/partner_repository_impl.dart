import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/partner.dart';
import '../../domain/repositories/partner_repository.dart';
import '../models/partner_model.dart';

class PartnerRepositoryImpl implements PartnerRepository {
  PartnerRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Partner>> getPartners() async {
    final response = await _client
        .from('partners')
        .select()
        .eq('is_active', true)
        .order('created_at');

    return response.map((map) => PartnerModel.fromMap(map)).toList();
  }

  @override
  Future<Partner?> getPartnerById(String id) async {
    final response =
        await _client.from('partners').select().eq('id', id).maybeSingle();

    if (response == null) return null;
    return PartnerModel.fromMap(response);
  }

  @override
  Future<Partner> createPartner(Partner partner) async {
    final model = PartnerModel(
      id: '',
      userId: partner.userId,
      name: partner.name,
      birthDate: partner.birthDate,
      relationshipStart: partner.relationshipStart,
      status: partner.status,
      likes: partner.likes,
      dislikes: partner.dislikes,
      budgetLevel: partner.budgetLevel,
      notes: partner.notes,
      photoUrl: partner.photoUrl,
    );

    final response = await _client
        .from('partners')
        .insert(model.toInsertMap())
        .select()
        .single();

    return PartnerModel.fromMap(response);
  }

  @override
  Future<Partner> updatePartner(Partner partner) async {
    final model = PartnerModel(
      id: partner.id,
      userId: partner.userId,
      name: partner.name,
      birthDate: partner.birthDate,
      relationshipStart: partner.relationshipStart,
      status: partner.status,
      likes: partner.likes,
      dislikes: partner.dislikes,
      budgetLevel: partner.budgetLevel,
      notes: partner.notes,
      photoUrl: partner.photoUrl,
    );

    final response = await _client
        .from('partners')
        .update(model.toUpdateMap())
        .eq('id', partner.id)
        .select()
        .single();

    return PartnerModel.fromMap(response);
  }

  @override
  Future<void> deletePartner(String id) async {
    await _client.from('partners').update({'is_active': false}).eq('id', id);
  }
}
