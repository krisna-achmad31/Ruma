import '../entities/life_stage_entity.dart';

abstract class LifeStageRepository {
  Stream<WeddingPlanEntity?> watchWedding(String familyId);
  Stream<BabyPlanEntity?> watchBaby(String familyId);
  Stream<LebaranPlanEntity?> watchLebaran(String familyId);

  Future<void> saveWedding(String familyId, WeddingPlanEntity plan);
  Future<void> saveBaby(String familyId, BabyPlanEntity plan);
  Future<void> saveLebaran(String familyId, LebaranPlanEntity plan);

  /// Menghapus satu rencana: 'wedding', 'baby', atau 'lebaran'.
  Future<void> deletePlan(String familyId, String stage);
}
