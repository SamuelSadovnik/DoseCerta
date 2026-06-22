import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/account_type.dart';
import '../../../../core/providers/account_type_provider.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/alert_app_bar.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../../shared/widgets/feedback_page.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/secondary_button.dart';
import '../../../home/domain/entities/dose_schedule.dart';
import '../../domain/alert_action.dart';
import 'medication_alert_view_model.dart';

class MedicationAlertPage extends ConsumerWidget {
  const MedicationAlertPage({super.key, this.dose});

  final DoseSchedule? dose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doseId = dose?.id;
    final provider = medicationAlertViewModelProvider(doseId);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    final accountType = ref.watch(currentAccountTypeProvider);
    final isCaregiver = accountType == AccountType.caregiver;
    final canAct =
        dose?.status == DoseStatus.pending ||
        dose?.status == DoseStatus.postponed;

    if (state.actionTaken == AlertAction.taken) {
      return _buildTakenFeedback(context, isCaregiver);
    }
    if (state.actionTaken == AlertAction.postponed) {
      return _buildPostponedFeedback(context, isCaregiver);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AlertAppBar(onClose: () => Navigator.of(context).maybePop()),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: BrandLogo(iconSize: 72, fontSize: 22)),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  dose == null ? 'Dose indisponível' : 'Medicamento',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _InfoCard(dose: dose),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _SmallCard(
                      label: 'HORÁRIO',
                      value: _formatTime(dose?.scheduledAt),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _SmallCard(
                      label: 'STATUS',
                      value: _statusText(dose?.status),
                      valueColor: AppColors.success,
                    ),
                  ),
                ],
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  state.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              PrimaryButton(
                label: 'Tomei agora',
                trailingIcon: Icons.check_circle,
                isLoading: state.isLoading,
                onPressed: canAct ? vm.takeNow : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: 'Adiar 10 min',
                leadingIcon: Icons.snooze,
                onPressed: canAct ? vm.postpone : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '--:--';
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  String _statusText(DoseStatus? status) {
    return switch (status) {
      DoseStatus.pending => 'Pendente',
      DoseStatus.taken => 'Tomada',
      DoseStatus.missed => 'Perdida',
      DoseStatus.postponed => 'Adiada',
      null => 'Indisponível',
    };
  }

  Widget _buildTakenFeedback(BuildContext context, bool isCaregiver) {
    if (isCaregiver) {
      return FeedbackPage(
        config: FeedbackPageConfig(
          iconType: FeedbackIconType.successGreen,
          title: 'Tudo certo!',
          subtitle: 'Seu responsável foi avisado que você concluiu esta ação.',
          buttons: [
            FeedbackButton(
              label: 'Voltar para o início',
              onPressed: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
            ),
          ],
          showEmergencyButton: true,
          emergencySubtitle: 'Chamar responsável ou contato',
          onEmergency: () =>
              Navigator.of(context).pushNamed(AppRoutes.emergency),
        ),
      );
    }
    return FeedbackPage(
      config: FeedbackPageConfig(
        iconType: FeedbackIconType.successGreen,
        title: 'Tudo certo!',
        subtitle: 'Você tomou a sua dose!',
        buttons: [
          FeedbackButton(
            label: 'Voltar',
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
        showEmergencyButton: true,
        emergencySubtitle: 'Chamar contato principal',
        onEmergency: () => Navigator.of(context).pushNamed(AppRoutes.emergency),
      ),
    );
  }

  Widget _buildPostponedFeedback(BuildContext context, bool isCaregiver) {
    if (isCaregiver) {
      return FeedbackPage(
        config: FeedbackPageConfig(
          iconType: FeedbackIconType.error,
          title: 'Adiamento!',
          subtitle: 'Seu responsável foi avisado que você adiou o remédio.',
          buttons: [
            FeedbackButton(
              label: 'Voltar para o início',
              onPressed: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
            ),
          ],
          showEmergencyButton: true,
          emergencySubtitle: 'Chamar responsável ou contato',
          onEmergency: () =>
              Navigator.of(context).pushNamed(AppRoutes.emergency),
        ),
      );
    }
    return FeedbackPage(
      config: FeedbackPageConfig(
        iconType: FeedbackIconType.error,
        title: 'Adiamento!',
        subtitle: 'Sua dose foi adiada!',
        buttons: [
          FeedbackButton(
            label: 'Voltar',
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
        showEmergencyButton: true,
        emergencySubtitle: 'Chamar contato principal',
        onEmergency: () => Navigator.of(context).pushNamed(AppRoutes.emergency),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.dose});

  final DoseSchedule? dose;

  @override
  Widget build(BuildContext context) {
    final title = dose == null
        ? 'Abra esta tela pela dose na página inicial.'
        : '${dose!.medicationName} ${dose!.dosage}';
    final note = dose?.note?.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Text(
            'MEDICAÇÃO',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    note,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (dose != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Sem observações para esta dose.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallCard extends StatelessWidget {
  const _SmallCard({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
