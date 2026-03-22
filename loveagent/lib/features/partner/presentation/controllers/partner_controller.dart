import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/partner_repository_impl.dart';
import '../../domain/entities/partner.dart';
import '../../domain/repositories/partner_repository.dart';

final partnerRepositoryProvider = Provider<PartnerRepository>((ref) {
  return PartnerRepositoryImpl(Supabase.instance.client);
});

// List of all active partners
final partnersProvider = FutureProvider<List<Partner>>((ref) {
  return ref.watch(partnerRepositoryProvider).getPartners();
});

// Single partner by ID
final partnerByIdProvider =
    FutureProvider.family<Partner?, String>((ref, id) {
  return ref.watch(partnerRepositoryProvider).getPartnerById(id);
});

// Controller for mutations
final partnerControllerProvider =
    StateNotifierProvider<PartnerController, AsyncValue<void>>((ref) {
  return PartnerController(ref.watch(partnerRepositoryProvider), ref);
});

class PartnerController extends StateNotifier<AsyncValue<void>> {
  PartnerController(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  final PartnerRepository _repository;
  final Ref _ref;

  Future<Partner?> create(Partner partner) async {
    state = const AsyncValue.loading();
    try {
      final created = await _repository.createPartner(partner);
      _ref.invalidate(partnersProvider);
      state = const AsyncValue.data(null);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> update(Partner partner) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updatePartner(partner);
      _ref.invalidate(partnersProvider);
      _ref.invalidate(partnerByIdProvider(partner.id));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> delete(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deletePartner(id);
      _ref.invalidate(partnersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
