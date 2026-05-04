import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/feedback_page.dart';

class DependentSuccessPage extends StatelessWidget {
  const DependentSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FeedbackPage(
      config: FeedbackPageConfig(
        iconType: FeedbackIconType.successRed,
        title: 'Cadastro Realizado com Sucesso!',
        buttons: [
          FeedbackButton(
            label: 'Ir para Início',
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
          ),
        ],
      ),
    );
  }
}
