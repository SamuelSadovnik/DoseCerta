import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../../shared/widgets/labeled_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import 'login_state.dart';
import 'login_view_model.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginViewModelProvider);
    final vm = ref.read(loginViewModelProvider.notifier);

    ref.listen(loginViewModelProvider, (previous, next) {
      if (next.loginSuccess && previous?.loginSuccess != true) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
      }
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              const Center(child: BrandLogo(iconSize: 88, fontSize: 28)),
              const SizedBox(height: AppSpacing.xl),
              _LoginCard(state: state, vm: vm),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ainda não tem acesso? ',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.accountType),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Criar conta',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.add_circle_outline,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.state, required this.vm});

  final LoginState state;
  final LoginViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppRadius.hero),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledTextField(
                variant: LabeledTextFieldVariant.rect,
                label: null,
                hint: 'E-mail ou CPF',
                prefixIcon: Icons.person_outline,
                onChanged: vm.onIdentifierChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                variant: LabeledTextFieldVariant.rect,
                label: null,
                hint: 'Senha',
                prefixIcon: Icons.lock_outline,
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
              // const SizedBox(height: AppSpacing.sm),
              // Align(
              //   alignment: Alignment.centerRight,
              //   child: TextButton(
              //     style: TextButton.styleFrom(
              //       padding: EdgeInsets.zero,
              //       minimumSize: const Size(0, 0),
              //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              //     ),
              //     onPressed: () => ScaffoldMessenger.of(
              //       context,
              //     ).showSnackBar(const SnackBar(content: Text('Em breve'))),
              //     child: Text(
              //       'Esqueceu a senha?',
              //       style: TextStyle(
              //         color: AppColors.primary,
              //         fontSize: 14,
              //         fontWeight: FontWeight.w700,
              //       ),
              //     ),
              //   ),
              // ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Entrar',
                isLoading: state.isLoading,
                onPressed: vm.submit,
              ),
            ],
          ),
        ),
        // Decoração discreta — círculo vermelho translúcido no canto superior
        // direito (SKILL §10.1).
        Positioned(
          top: -28,
          right: -28,
          child: IgnorePointer(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
