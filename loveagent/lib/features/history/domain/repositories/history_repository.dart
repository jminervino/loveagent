import '../entities/surprise.dart';

abstract class HistoryRepository {
  Future<List<Surprise>> getSurprises();
  Future<List<Surprise>> getSurprisesByPartner(String partnerId);
  Future<Surprise> createSurprise(Surprise surprise);
  Future<Surprise> updateSurprise(Surprise surprise);
  Future<void> deleteSurprise(String id);
}
