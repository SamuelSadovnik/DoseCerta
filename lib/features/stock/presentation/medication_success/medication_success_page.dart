import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/feedback_page.dart';

class MedicationSuccessPage extends StatelessWidget {
  const MedicationSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FeedbackPage(
      config: FeedbackPageConfig(
        iconType: FeedbackIconType.successRed,
        title: 'Cadastro realizado com sucesso!',
        buttons: [
          FeedbackButton(
            label: 'Ir para estoque',
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.stock, (_) => false),
          ),
        ],
      ),
    );
  }
}
