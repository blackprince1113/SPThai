import 'package:flutter/material.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/features/lessons/data/lesson_repository.dart';
import 'package:superthai/ui/widgets/common/shared_core_widgets.dart';
import 'package:superthai/ui/widgets/settings/shared_settings_widgets.dart';

enum BackupState { idle, running, completed, error }

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  BackupState _state = BackupState.idle;
  double _progress = 0.0;
  String _statusMessage = '';
  BackupResult? _result;
  String? _errorMessage;

  Future<void> _startBackup() async {
    setState(() {
      _state = BackupState.running;
      _progress = 0.0;
      _statusMessage = 'Preparing backup...';
      _result = null;
      _errorMessage = null;
    });

    try {
      final res = await DataService.instance.backupLessonPlans(
        onProgress: (p, status) {
          if (mounted) {
            setState(() {
              _progress = p;
              _statusMessage = status;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _state = BackupState.completed;
          _progress = 1.0;
          _result = res;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = BackupState.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const backupColor = Colors.indigo;

    return PopScope(
      canPop: _state != BackupState.running,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _state == BackupState.running) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup in progress. Please wait...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: const ThaiAppBar(
          title: "Backup Lesson Plans",
          showProfile: false,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ThaiInfoBox(
                icon: Icons.cloud_upload_rounded,
                text:
                    "Backup lesson plans from lesson_plans_v2 to backup_lesson_plans. Only changed data will be copied (Incremental Backup).",
                color: backupColor,
              ),
              const SizedBox(height: 24),
              if (_state == BackupState.idle) _buildIdleView(backupColor),
              if (_state == BackupState.running) _buildRunningView(theme, backupColor),
              if (_state == BackupState.completed) _buildCompletedView(theme, backupColor),
              if (_state == BackupState.error) _buildErrorView(theme, backupColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdleView(Color backupColor) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.indigo.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.backup_table_rounded,
                size: 64,
                color: Colors.indigo,
              ),
              const SizedBox(height: 16),
              const Text(
                'Ready to Backup',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The system will scan all lesson_plans_v2 data and copy changed items to backup_lesson_plans.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ThaiButton(
          text: "START BACKUP",
          color: backupColor,
          onPressed: _startBackup,
        ),
      ],
    );
  }

  Widget _buildRunningView(ThemeData theme, Color backupColor) {
    final percentage = (_progress * 100).clamp(0, 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Backing up data... ($percentage%)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 14,
              backgroundColor: Colors.indigo.withValues(alpha: 0.1),
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedView(ThemeData theme, Color backupColor) {
    final res = _result;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 64,
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              const Text(
                'Backup Completed Successfully!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              if (res != null) ...[
                _buildStatRow(
                  icon: Icons.library_books_rounded,
                  label: 'Total Lesson Plans',
                  value: '${res.totalSourcePlans} plans',
                ),
                const Divider(height: 20),
                _buildStatRow(
                  icon: Icons.edit_note_rounded,
                  label: 'Updated Lesson Plans',
                  value: '${res.updatedPlans} items',
                ),
                const Divider(height: 20),
                _buildStatRow(
                  icon: Icons.list_alt_rounded,
                  label: 'Updated Steps',
                  value: '${res.updatedSteps} items',
                ),
                if (res.deletedPlans > 0 || res.deletedSteps > 0) ...[
                  const Divider(height: 20),
                  _buildStatRow(
                    icon: Icons.delete_sweep_rounded,
                    label: 'Deleted Stale Items',
                    value:
                        '${res.deletedPlans} plans (${res.deletedSteps} steps)',
                  ),
                ],
                const Divider(height: 20),
                _buildStatRow(
                  icon: Icons.speed_rounded,
                  label: 'Unchanged Items (Skipped)',
                  value: '${res.skippedCount} items',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 28),
        ThaiButton(
          text: "BACK UP AGAIN",
          color: backupColor,
          onPressed: _startBackup,
        ),
      ],
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(ThemeData theme, Color backupColor) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              const Text(
                'Backup Failed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'An unknown error occurred.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        ThaiButton(
          text: "RETRY BACKUP",
          color: backupColor,
          onPressed: _startBackup,
        ),
      ],
    );
  }
}
