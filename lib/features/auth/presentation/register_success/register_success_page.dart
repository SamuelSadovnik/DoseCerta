import 'package:flutter/material.dart';

import '../../../../core/enums/account_type.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/feedback_page.dart';

class RegisterSuccessPage extends StatelessWidget {
  const RegisterSuccessPage({super.key, required this.accountType});

  final AccountType accountType;

  @override
  Widget build(BuildContext context) {
    final buttons = <FeedbackButton>[];
    if (accountType == AccountType.personal) {
      buttons.add(
        FeedbackButton(
          label: 'Ir para Início',
          onPressed: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
        ),
      );
    } else {
      buttons.add(
        FeedbackButton(
          label: 'Cadastrar dependente',
          onPressed: () => Navigator.of(
            context,
          ).pushReplacementNamed(AppRoutes.newDependent),
        ),
      );
      buttons.add(
        FeedbackButton(
          label: 'Ir para Início',
          style: FeedbackButtonStyle.secondary,
          onPressed: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
        ),
      );
    }

    return FeedbackPage(
      config: FeedbackPageConfig(
        iconType: FeedbackIconType.successRed,
        title: 'Cadastro Realizado\ncom Sucesso!',
        subtitle: 'Sua conta está pronta. Vamos cuidar dos seus medicamentos.',
        buttons: buttons,
      ),
    );
  }
}
