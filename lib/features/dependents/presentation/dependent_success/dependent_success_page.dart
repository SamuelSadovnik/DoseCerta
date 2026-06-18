import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/selected_dependent_provider.dart';
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
            '$firstName já está no DoseCerta. Você pode cadastrar um tratamento agora, compartilhar o código ou ir para o início.',
        buttons: [
          if (dependent != null)
            FeedbackButton(
              label: 'Cadastrar tratamento',
              onPressed: () {
                ref.read(selectedCareContextProvider.notifier).state =
                    CareContext.dependent(dependent!.id);
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.newMedication,
                  (route) => route.settings.name == AppRoutes.home,
                );
              },
            ),
          if (code != null)
            FeedbackButton(
              label: 'Copiar código de convite',
              style: FeedbackButtonStyle.secondary,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Código copiado')));
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
