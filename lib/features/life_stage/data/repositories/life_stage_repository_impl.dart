import '../../domain/entities/life_stage_entity.dart';
import '../../domain/repositories/life_stage_repository.dart';
import '../datasources/life_stage_remote_datasource.dart';

class LifeStageRepositoryImpl implements LifeStageRepository {
  final LifeStageRemoteDataSource _remote;

  LifeStageRepositoryImpl(this._remote);

  @override
  Stream<WeddingPlanEntity?> watchWedding(String familyId) => _remote.watchWedding(familyId);

  @override
  Stream<BabyPlanEntity?> watchBaby(String familyId) => _remote.watchBaby(familyId);

  @override
  Stream<LebaranPlanEntity?> watchLebaran(String familyId) => _remote.watchLebaran(familyId);

  @override
  Future<void> saveWedding(String familyId, WeddingPlanEntity plan) => _remote.saveWedding(familyId, plan);

  @override
  Future<void> saveBaby(String familyId, BabyPlanEntity plan) => _remote.saveBaby(familyId, plan);

  @override
  Future<void> saveLebaran(String familyId, LebaranPlanEntity plan) => _remote.saveLebaran(familyId, plan);

  @override
  Future<void> deletePlan(String familyId, String stage) => _remote.deletePlan(familyId, stage);
}
