import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/history_repository_impl.dart';
import '../../domain/entities/surprise.dart';
import '../../domain/repositories/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl(Supabase.instance.client);
});

final surprisesProvider = FutureProvider<List<Surprise>>((ref) {
  return ref.watch(historyRepositoryProvider).getSurprises();
});

final surprisesByPartnerProvider =
    FutureProvider.family<List<Surprise>, String>((ref, partnerId) {
  return ref.watch(historyRepositoryProvider).getSurprisesByPartner(partnerId);
});

final historyControllerProvider =
    StateNotifierProvider<HistoryController, AsyncValue<void>>((ref) {
  return HistoryController(ref.watch(historyRepositoryProvider), ref);
});

class HistoryController extends StateNotifier<AsyncValue<void>> {
  HistoryController(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  final HistoryRepository _repository;
  final Ref _ref;

  Future<Surprise?> create(Surprise surprise) async {
    state = const AsyncValue.loading();
    try {
      final created = await _repository.createSurprise(surprise);
      _ref.invalidate(surprisesProvider);
      state = const AsyncValue.data(null);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> delete(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteSurprise(id);
      _ref.invalidate(surprisesProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
