import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/data_service.dart';

class LessonMigrationService {
  static Future<void> markAsMeaning(LessonPlan plan, int stepIndex) async {
    if (stepIndex < 0 || stepIndex >= plan.steps.length) return;

    plan.steps[stepIndex].type = "Meaning";

    await DataService.instance.addLessonPlan(plan);
  }
}
