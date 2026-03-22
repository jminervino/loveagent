import '../entities/partner.dart';

abstract class PartnerRepository {
  Future<List<Partner>> getPartners();
  Future<Partner?> getPartnerById(String id);
  Future<Partner> createPartner(Partner partner);
  Future<Partner> updatePartner(Partner partner);
  Future<void> deletePartner(String id);
}
