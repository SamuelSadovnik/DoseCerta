import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/feedback_page.dart';
import '../../domain/entities/dependent.dart';

class DependentSuccessPage extends ConsumerWidget {
  const DependentSuccessPage({super.key, this.dependent});

  final Dependent? dependent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstName = dependent?.name.split(' ').first ?? 'A pessoa';
    final code = dependent?.activationCode;

    return FeedbackPage(
      config: FeedbackPageConfig(
        iconType: FeedbackIconType.successRed,
        title: 'Pessoa cuidada adicionada',
        subtitle:
            '$firstName já está no DoseCerta. Você já pode cuidar dessa pessoa pelo app. O convite é opcional.',
        buttons: [
          if (dependent != null && code != null)
            FeedbackButton(
              label: 'Ver código de convite',
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.dependentDetail,
                  (route) => route.settings.name == AppRoutes.home,
                  arguments: dependent,
                );
              },
            ),
          FeedbackButton(
            label: 'Ir para Início',
            style: dependent == null
                ? FeedbackButtonStyle.primary
                : FeedbackButtonStyle.secondary,
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
          ),
        ],
      ),
    );
  }
}
