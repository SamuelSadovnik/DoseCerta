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
          label: 'Ir para início',
          onPressed: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
        ),
      );
    } else {
      buttons.add(
        FeedbackButton(
          label: 'Ir para início',
          onPressed: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
        ),
      );
      buttons.add(
        FeedbackButton(
          label: 'Adicionar pessoa cuidada',
          style: FeedbackButtonStyle.secondary,
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.newDependent,
            (route) => route.settings.name == AppRoutes.home,
          ),
        ),
      );
    }

    return FeedbackPage(
      config: FeedbackPageConfig(
        iconType: FeedbackIconType.successRed,
        title: 'Cadastro realizado\ncom sucesso!',
        subtitle: accountType == AccountType.personal
            ? 'Sua conta está pronta. Vamos cuidar dos seus medicamentos.'
            : 'Sua conta está pronta. Você pode adicionar uma pessoa cuidada agora ou começar pelo início.',
        buttons: buttons,
      ),
    );
  }
}
