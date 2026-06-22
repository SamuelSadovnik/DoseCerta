import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
import '../../../appointments/domain/entities/appointment.dart';
import '../../domain/alert_action.dart';
import 'appointment_alert_view_model.dart';

class AppointmentAlertPage extends ConsumerWidget {
  const AppointmentAlertPage({super.key, this.appointment});

  final Appointment? appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = appointmentAlertViewModelProvider(appointment?.id);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    final accountType = ref.watch(currentAccountTypeProvider);
    final isCaregiver = accountType == AccountType.caregiver;
    final isCompleted = appointment?.status == AppointmentStatus.completed;
    final isCancelled = appointment?.status == AppointmentStatus.cancelled;
    final isConfirmed = appointment?.status == AppointmentStatus.confirmed;

    if (state.actionTaken == AlertAction.confirmed) {
      return _buildStatusFeedback(
        context,
        title: 'Consulta confirmada',
        subtitle: 'A consulta foi marcada como confirmada.',
      );
    }
    if (state.actionTaken == AlertAction.completed) {
      return _buildStatusFeedback(
        context,
        title: 'Consulta concluída',
        subtitle: 'Consulta marcada como realizada.',
      );
    }
    if (state.actionTaken == AlertAction.cancelled) {
      return _buildStatusFeedback(
        context,
        iconType: FeedbackIconType.error,
        title: 'Consulta cancelada',
        subtitle: 'Consulta removida da agenda ativa.',
      );
    }
    if (state.actionTaken == AlertAction.rescheduled) {
      return _buildRescheduledFeedback(context, isCaregiver);
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
                  'Consulta',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.person, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PROFISSIONAL',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            appointment?.doctorName ?? 'Consulta indisponível',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            appointment?.specialty ??
                                'Especialidade não informada',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _IconCard(
                      icon: Icons.schedule,
                      label: 'Horário',
                      value: appointment == null
                          ? '--:--'
                          : DateFormat(
                              'dd/MM HH:mm',
                            ).format(appointment!.scheduledAt),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _IconCard(
                      icon: Icons.place,
                      label: 'Local',
                      value: appointment?.location ?? 'Não informado',
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
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: AppColors.success, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Consulta realizada',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (isCancelled)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Consulta cancelada',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                if (!isConfirmed) ...[
                  PrimaryButton(
                    label: 'Confirmar consulta',
                    trailingIcon: Icons.event_available,
                    isLoading: state.isLoading,
                    onPressed: appointment == null ? null : vm.confirm,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                PrimaryButton(
                  label: 'Marcar como realizada',
                  trailingIcon: Icons.check_circle,
                  isLoading: state.isLoading,
                  onPressed: appointment == null ? null : vm.complete,
                ),
                const SizedBox(height: AppSpacing.sm),
                SecondaryButton(
                  label: 'Reagendar',
                  leadingIcon: Icons.event_repeat,
                  onPressed: appointment == null
                      ? null
                      : () => Navigator.of(context).pushNamed(
                          AppRoutes.newAppointment,
                          arguments: appointment,
                        ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  onPressed: appointment == null || state.isLoading
                      ? null
                      : vm.cancel,
                  icon: Icon(Icons.cancel_outlined, color: AppColors.error),
                  label: Text(
                    'Cancelar consulta',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFeedback(
    BuildContext context, {
    FeedbackIconType iconType = FeedbackIconType.successGreen,
    required String title,
    required String subtitle,
  }) {
    return FeedbackPage(
      config: FeedbackPageConfig(
        iconType: iconType,
        title: title,
        subtitle: subtitle,
        buttons: [
          FeedbackButton(
            label: 'Voltar para consultas',
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.appointments, (_) => false),
          ),
        ],
        showEmergencyButton: true,
        emergencySubtitle: 'Chamar responsável ou contato',
        onEmergency: () => Navigator.of(context).pushNamed(AppRoutes.emergency),
      ),
    );
  }

  Widget _buildRescheduledFeedback(BuildContext context, bool isCaregiver) {
    if (isCaregiver) {
      return FeedbackPage(
        config: FeedbackPageConfig(
          iconType: FeedbackIconType.error,
          title: 'Reagendamento!',
          subtitle:
              'Seu responsável foi avisado que você reagendou a consulta.',
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
        subtitle: 'Consulta reagendada!',
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

class _IconCard extends StatelessWidget {
  const _IconCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
