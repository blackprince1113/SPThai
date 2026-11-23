import 'package:superthai/core/models/models.dart';

class BackupResult {
  final int totalSourcePlans;
  final int updatedPlans;
  final int updatedSteps;
  final int deletedPlans;
  final int deletedSteps;
  final int skippedCount;

  const BackupResult({
    required this.totalSourcePlans,
    required this.updatedPlans,
    required this.updatedSteps,
    required this.deletedPlans,
    required this.deletedSteps,
    required this.skippedCount,
  });
}

abstract interface class LessonRepository {
  Future<List<LessonPlan>> getAll();
  Future<LessonPlan?> getById(String lessonId);
  Future<LessonPlan?> getByCategory(String category);
  Future<void> save(LessonPlan plan, {int? nextIndex});
  Future<void> delete(String lessonId);
  Future<void> updateIndices(List<LessonPlan> plans);
  Future<BackupResult> backupLessonPlans({
    void Function(double progress, String status)? onProgress,
  });
}
