import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/providers/selected_dependent_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/form_app_bar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../history/presentation/providers/history_providers.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../stock/presentation/providers/stock_providers.dart';
import '../providers/dependent_providers.dart';

class LinkDependentPage extends ConsumerStatefulWidget {
  const LinkDependentPage({super.key});

  @override
  ConsumerState<LinkDependentPage> createState() => _LinkDependentPageState();
}

class _LinkDependentPageState extends ConsumerState<LinkDependentPage> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  bool _isUnlinking = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Digite o código.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dep = await ref.read(dependentRepositoryProvider).link(code: code);
      if (!mounted) return;
      ref.read(selectedCareContextProvider.notifier).state =
          const CareContext.allDependents();
      ref.invalidate(homeDataProvider);
      ref.invalidate(historySummariesProvider);
      ref.invalidate(medicationsProvider);
      ref.invalidate(dependentsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vinculado com sucesso a ${dep.name}.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = describeApiError(e, fallback: 'Não foi possível vincular.');
      });
    }
  }

  Future<void> _unlink() async {
    setState(() {
      _isUnlinking = true;
      _error = null;
    });
    try {
      await ref.read(dependentRepositoryProvider).unlink();
      ref.read(selectedCareContextProvider.notifier).state =
          const CareContext.allDependents();
      ref.invalidate(homeDataProvider);
      ref.invalidate(historySummariesProvider);
      ref.invalidate(medicationsProvider);
      ref.invalidate(dependentsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vínculo removido com sucesso.')),
      );
    } catch (e) {
      setState(() {
        _error = describeApiError(
          e,
          fallback: 'Não foi possível remover o vínculo.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isUnlinking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dependentsAsync = ref.watch(dependentsProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const FormAppBar(title: 'Vincular responsável'),
      body: SafeArea(
        top: false,
        child: dependentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _LinkForm(
            controller: _controller,
            isLoading: _isLoading,
            error: _error,
            onSubmit: _submit,
          ),
          data: (deps) {
            final linked = deps.where((dep) => dep.isLinked).firstOrNull;
            if (linked != null) {
              return _LinkedState(
                dependentName: linked.name,
                caregiverName: linked.caregiverName,
                linkedAt: linked.linkedAt,
                isLoading: _isUnlinking,
                error: _error,
                onUnlink: _unlink,
              );
            }
            return _LinkForm(
              controller: _controller,
              isLoading: _isLoading,
              error: _error,
              onSubmit: _submit,
            );
          },
        ),
      ),
    );
  }
}

class _LinkForm extends StatelessWidget {
  const _LinkForm({
    required this.controller,
    required this.isLoading,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isLoading;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Digite o código enviado pelo seu responsável. Sua conta continua sendo sua; o vínculo só permite que ele acompanhe doses, consultas e histórico.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Código de convite',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              UpperCaseTextFormatter(),
              LengthLimitingTextInputFormatter(12),
            ],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
            decoration: InputDecoration(
              hintText: 'A7K9X2B1',
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              error!,
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Vincular',
            isLoading: isLoading,
            trailingIcon: Icons.link,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _LinkedState extends StatelessWidget {
  const _LinkedState({
    required this.dependentName,
    required this.caregiverName,
    required this.linkedAt,
    required this.isLoading,
    required this.error,
    required this.onUnlink,
  });

  final String dependentName;
  final String? caregiverName;
  final DateTime? linkedAt;
  final bool isLoading;
  final String? error;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user, color: AppColors.success, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conta já vinculada',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sua conta está vinculada ao responsável $_displayName. As doses e consultas criadas por ele aparecem na sua tela inicial.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (linkedAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Vinculado em ${linkedAt!.day.toString().padLeft(2, '0')}/${linkedAt!.month.toString().padLeft(2, '0')}/${linkedAt!.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(error!, style: TextStyle(color: AppColors.error, fontSize: 13)),
        ],
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Desvincular responsável',
          isLoading: isLoading,
          trailingIcon: Icons.link_off,
          onPressed: onUnlink,
        ),
      ],
    );
  }

  String get _displayName => caregiverName ?? dependentName;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
