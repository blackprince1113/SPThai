import 'package:superthai/core/models/models.dart';

abstract interface class LessonRepository {
  Future<List<LessonPlan>> getAll();
  Future<LessonPlan?> getById(String lessonId);
  Future<LessonPlan?> getByCategory(String category);
  Future<void> save(LessonPlan plan, {int? nextIndex});
  Future<void> delete(String lessonId);
  Future<void> updateIndices(List<LessonPlan> plans);
}
