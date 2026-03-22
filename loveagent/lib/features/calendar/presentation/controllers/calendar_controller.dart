import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/calendar_repository_impl.dart';
import '../../domain/entities/special_date.dart';
import '../../domain/repositories/calendar_repository.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepositoryImpl(Supabase.instance.client);
});

// Upcoming dates (next 90 days — covers the agent's 30-day window + buffer)
final upcomingDatesProvider = FutureProvider<List<SpecialDate>>((ref) {
  return ref.watch(calendarRepositoryProvider).getUpcomingDates(days: 90);
});

// Dates by partner
final datesByPartnerProvider =
    FutureProvider.family<List<SpecialDate>, String>((ref, partnerId) {
  return ref.watch(calendarRepositoryProvider).getDatesByPartner(partnerId);
});

// Controller for mutations
final calendarControllerProvider =
    StateNotifierProvider<CalendarController, AsyncValue<void>>((ref) {
  return CalendarController(ref.watch(calendarRepositoryProvider), ref);
});

class CalendarController extends StateNotifier<AsyncValue<void>> {
  CalendarController(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  final CalendarRepository _repository;
  final Ref _ref;

  Future<SpecialDate?> create(SpecialDate date) async {
    state = const AsyncValue.loading();
    try {
      final created = await _repository.createDate(date);
      _invalidate(date.partnerId);
      state = const AsyncValue.data(null);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> update(SpecialDate date) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateDate(date);
      _invalidate(date.partnerId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> delete(SpecialDate date) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteDate(date.id);
      _invalidate(date.partnerId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void _invalidate(String partnerId) {
    _ref.invalidate(upcomingDatesProvider);
    _ref.invalidate(datesByPartnerProvider(partnerId));
  }
}
