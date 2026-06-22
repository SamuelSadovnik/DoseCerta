import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/account_type.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/form_app_bar.dart';
import '../../../../shared/widgets/hero_card.dart';
import '../../../../shared/widgets/labeled_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import 'register_view_model.dart';

class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key, required this.accountType});

  final AccountType accountType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = registerViewModelProvider(accountType);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);

    ref.listen(provider, (previous, next) {
      if (next.registerSuccess && previous?.registerSuccess != true) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.registerSuccess,
          arguments: accountType,
        );
      }
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    final heroTitle = accountType == AccountType.personal
        ? 'Uso pessoal'
        : 'Responsável';
    final heroSubtitle = accountType == AccountType.personal
        ? 'Cuide dos seus próprios remédios.'
        : 'Cuide dos medicamentos de quem você ama.';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const FormAppBar(title: 'Criar conta'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              HeroCard(
                title: heroTitle,
                subtitle: heroSubtitle,
                badge: 'Segurança e cuidado',
              ),
              const SizedBox(height: AppSpacing.xl),
              LabeledTextField(
                label: 'Nome completo',
                prefixIcon: Icons.person_outline,
                hint: 'Seu nome',
                onChanged: vm.onNameChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                label: 'E-mail de acesso',
                prefixIcon: Icons.mail_outline,
                hint: 'seu@email.com',
                keyboardType: TextInputType.emailAddress,
                onChanged: vm.onEmailChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                label: 'Senha',
                prefixIcon: Icons.lock_outline,
                hint: 'Sua senha secreta',
                obscureText: state.obscurePassword,
                onChanged: vm.onPasswordChanged,
                suffixIcon: IconButton(
                  icon: Icon(
                    state.obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: vm.togglePasswordVisibility,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _TermsCheckbox(
                value: state.acceptedTerms,
                onChanged: vm.toggleTerms,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Finalizar cadastro',
                isLoading: state.isLoading,
                onPressed: vm.canSubmit ? vm.submit : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false),
                  child: Text(
                    'Já possuo uma conta',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.primary,
                side: const BorderSide(color: AppColors.divider, width: 1.5),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(text: 'Li e concordo com os '),
                      TextSpan(
                        text: 'Termos de uso',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: ' e a '),
                      TextSpan(
                        text: 'Política de privacidade',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
