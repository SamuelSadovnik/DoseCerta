import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/feedback_page.dart';

class AppointmentSuccessPage extends StatelessWidget {
  const AppointmentSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FeedbackPage(
      config: FeedbackPageConfig(
        iconType: FeedbackIconType.successRed,
        title: 'Cadastro realizado com sucesso!',
        buttons: [
          FeedbackButton(
            label: 'Ir para consultas',
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.appointments, (_) => false),
          ),
        ],
      ),
    );
  }
}
