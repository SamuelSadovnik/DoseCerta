import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/selected_dependent_provider.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../shared/widgets/form_app_bar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../stock/presentation/providers/stock_providers.dart';
import '../../domain/entities/dependent.dart';
import '../providers/dependent_providers.dart';

class DependentDetailPage extends ConsumerStatefulWidget {
  const DependentDetailPage({super.key, required this.dependent});

  final Dependent dependent;

  @override
  ConsumerState<DependentDetailPage> createState() =>
      _DependentDetailPageState();
}

class _DependentDetailPageState extends ConsumerState<DependentDetailPage> {
  CareContext? _previousSelection;
  ProviderContainer? _container;
  bool _selectionApplied = false;
  late Dependent _dependent;
  bool _isRegeneratingCode = false;

  @override
  void initState() {
    super.initState();
    _dependent = widget.dependent;
    // Pull doses/history of this dependent into the shared providers so the
    // user can dive into the dependent's Home/History via the bottom nav and
    // continue filtered by them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _previousSelection = ref.read(selectedCareContextProvider);
      ref.read(selectedCareContextProvider.notifier).state =
          CareContext.dependent(_dependent.id);
      _selectionApplied = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container ??= ProviderScope.containerOf(context, listen: false);
  }

  @override
  void dispose() {
    final previousSelection = _previousSelection;
    final container = _container;
    final shouldRestore = _selectionApplied;

    if (shouldRestore && container != null) {
      Future<void>(() {
        container.read(selectedCareContextProvider.notifier).state =
            previousSelection ?? const CareContext.allDependents();
      });
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dep = _dependent;
    final medsAsync = ref.watch(medicationsByDependentProvider(dep.id));
    final homeAsync = ref.watch(homeDataProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const FormAppBar(title: 'Pessoa cuidada'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            _Header(dependent: dep),
            const SizedBox(height: AppSpacing.lg),
            _LinkSection(
              dependent: dep,
              isRegeneratingCode: _isRegeneratingCode,
              onRegenerateCode: _regenerateActivationCode,
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(title: 'Próxima dose'),
            const SizedBox(height: AppSpacing.sm),
            homeAsync.when(
              loading: () => const _Card(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (e, _) =>
                  _Card(child: Text('Erro ao carregar próxima dose: $e')),
              data: (data) {
                final next = data.todayDoses.isEmpty
                    ? null
                    : data.todayDoses
                          .where(
                            (d) =>
                                d.scheduledAt.isAfter(DateTime.now()) ||
                                d.status.name == 'pending' ||
                                d.status.name == 'postponed',
                          )
                          .map((d) => d)
                          .firstOrNull;
                if (next == null) {
                  return const _Card(
                    child: Text('Nenhuma dose agendada por enquanto.'),
                  );
                }
                final time = DateFormat(
                  'dd/MM \'às\' HH:mm',
                ).format(next.scheduledAt);
                return _Card(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.medical_services,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${next.medicationName} • ${next.dosage}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(title: 'Tratamentos ativos'),
            const SizedBox(height: AppSpacing.sm),
            medsAsync.when(
              loading: () => const _Card(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (e, _) => _Card(child: Text('Erro: $e')),
              data: (meds) {
                if (meds.isEmpty) {
                  return const _Card(
                    child: Text('Nenhum medicamento cadastrado ainda.'),
                  );
                }
                return Column(
                  children: meds
                      .map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _MedicationTile(
                            name: m.name,
                            dosage: m.dosage,
                            frequency: m.frequency,
                            currentQuantity: m.currentQuantity,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Cadastrar medicamento',
              leadingIcon: Icons.add,
              trailingIcon: null,
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.newMedication);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _regenerateActivationCode() async {
    if (_isRegeneratingCode) return;

    setState(() => _isRegeneratingCode = true);
    try {
      final updated = await ref
          .read(dependentRepositoryProvider)
          .regenerateActivationCode(_dependent.id);
      if (!mounted) return;

      setState(() => _dependent = updated);
      ref.invalidate(dependentsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Novo código de vínculo gerado'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível gerar um novo código.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isRegeneratingCode = false);
      }
    }
  }
}

class _LinkSection extends StatelessWidget {
  const _LinkSection({
    required this.dependent,
    required this.isRegeneratingCode,
    required this.onRegenerateCode,
  });

  final Dependent dependent;
  final bool isRegeneratingCode;
  final VoidCallback onRegenerateCode;

  @override
  Widget build(BuildContext context) {
    if (dependent.isLinked) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_user, color: AppColors.success, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conta vinculada',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Essa pessoa já tem o próprio app. As doses agora podem ser marcadas por ela.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final code = dependent.activationCode;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primaryLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Aguardando vinculação',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Essa pessoa pode instalar o app, criar uma conta e digitar este código em "Vincular a um responsável" para passar a marcar as doses por conta própria.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (code == null)
            Text(
              'Código indisponível',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: context.appSurfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      code,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy),
                  color: AppColors.primary,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Código copiado'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isRegeneratingCode ? null : onRegenerateCode,
              icon: isRegeneratingCode
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(
                isRegeneratingCode
                    ? 'Gerando novo código...'
                    : 'Gerar novo código',
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Use essa opção quando o código anterior expirar ou a pessoa não conseguir vincular a conta.',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.dependent});

  final Dependent dependent;

  @override
  Widget build(BuildContext context) {
    final initial = dependent.name.isEmpty
        ? '?'
        : dependent.name[0].toUpperCase();
    final birth = dependent.birthDate == null
        ? null
        : DateFormat('dd/MM/yyyy').format(dependent.birthDate!);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              initial,
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dependent.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dependent.relationship.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                if (birth != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Nascimento: $birth',
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
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: child,
    );
  }
}

class _MedicationTile extends StatelessWidget {
  const _MedicationTile({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.currentQuantity,
  });

  final String name;
  final String dosage;
  final String frequency;
  final int currentQuantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.medication, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name • $dosage',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$frequency · $currentQuantity restantes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
