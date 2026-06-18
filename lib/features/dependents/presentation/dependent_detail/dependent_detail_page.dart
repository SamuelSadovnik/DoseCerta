import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/selected_dependent_provider.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../shared/widgets/form_app_bar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/secondary_button.dart';
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
    final hasNoTreatments = medsAsync.maybeWhen(
      data: (meds) => meds.isEmpty,
      orElse: () => false,
    );

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
            _CareProfileSection(
              dependent: dep,
              onEditHealth: _editHealthInfo,
              onEditContacts: _editEmergencyContacts,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (hasNoTreatments) ...[
              _NoTreatmentsIntro(dependentName: dep.name),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Cadastrar tratamento',
                leadingIcon: Icons.add,
                trailingIcon: null,
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.newMedication);
                },
              ),
            ] else ...[
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
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
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
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
                label: 'Cadastrar tratamento',
                leadingIcon: Icons.add,
                trailingIcon: null,
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.newMedication);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editHealthInfo() async {
    final updated = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _HealthInfoSheet(initial: _dependent.healthInfo),
    );
    if (updated == null) return;

    try {
      final dep = await ref
          .read(dependentRepositoryProvider)
          .updateCareProfile(id: _dependent.id, healthInfo: updated);
      if (!mounted) return;
      setState(() => _dependent = dep);
      ref.invalidate(dependentsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cartão de Saúde atualizado.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar os dados.')),
      );
    }
  }

  Future<void> _editEmergencyContacts() async {
    final updated = await showModalBottomSheet<List<Map<String, String>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) =>
          _EmergencyContactsSheet(initial: _dependent.emergencyContacts),
    );
    if (updated == null) return;

    try {
      final dep = await ref
          .read(dependentRepositoryProvider)
          .updateCareProfile(id: _dependent.id, emergencyContacts: updated);
      if (!mounted) return;
      setState(() => _dependent = dep);
      ref.invalidate(dependentsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rede de emergência atualizada.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar os contatos.')),
      );
    }
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
                    'Essa pessoa também pode marcar as próprias doses pelo app.',
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
                'Perfil gerenciado por você',
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
            'Você já pode cuidar dessa pessoa por aqui. Se ela também for usar o app, compartilhe este código para vincular a conta dela.',
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
            'Convite opcional. Use essa opção quando o código anterior expirar ou a pessoa não conseguir vincular a conta.',
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

class _CareProfileSection extends StatelessWidget {
  const _CareProfileSection({
    required this.dependent,
    required this.onEditHealth,
    required this.onEditContacts,
  });

  final Dependent dependent;
  final VoidCallback onEditHealth;
  final VoidCallback onEditContacts;

  @override
  Widget build(BuildContext context) {
    final healthEntries = _healthEntries(dependent.healthInfo);
    final contacts = dependent.emergencyContacts;
    final primaryContact = _primaryContact(contacts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title: 'Segurança e emergência'),
        const SizedBox(height: AppSpacing.sm),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.medical_information_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cartão de Saúde',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onEditHealth,
                    child: const Text('Editar'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (healthEntries.isEmpty)
                Text(
                  'Nenhuma informação médica cadastrada para ${dependent.name.split(' ').first}.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                )
              else
                for (final entry in healthEntries.take(4)) ...[
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.value,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.contact_emergency_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rede de emergência',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onEditContacts,
                    child: Text(contacts.isEmpty ? 'Cadastrar' : 'Editar'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (primaryContact == null)
                Text(
                  'Nenhum contato de emergência cadastrado.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                )
              else ...[
                Text(
                  primaryContact['name'] ?? '',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    primaryContact['relation'] ?? '',
                    primaryContact['phone'] ?? '',
                  ].where((value) => value.trim().isNotEmpty).join(' • '),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SecondaryButton(
                  label: 'Ligar para contato principal',
                  leadingIcon: Icons.phone,
                  onPressed: () =>
                      _call(context, primaryContact['phone'] ?? ''),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static List<MapEntry<String, String>> _healthEntries(
    Map<String, String>? info,
  ) {
    return <MapEntry<String, String>>[
      MapEntry('Alergias', info?['allergies'] ?? ''),
      MapEntry('Condições', info?['conditions'] ?? ''),
      MapEntry('Tipo sanguíneo', info?['bloodType'] ?? ''),
      MapEntry('Medicamentos contínuos', info?['continuousMedications'] ?? ''),
      MapEntry('Médico', info?['doctor'] ?? ''),
      MapEntry('Plano de saúde', info?['healthInsurance'] ?? ''),
      MapEntry('Hospital preferencial', info?['preferredHospital'] ?? ''),
      MapEntry('Observações', info?['notes'] ?? ''),
    ].where((entry) => entry.value.trim().isNotEmpty).toList();
  }

  static Map<String, String>? _primaryContact(
    List<Map<String, String>> contacts,
  ) {
    if (contacts.isEmpty) return null;
    for (final contact in contacts) {
      if (contact['isPrimary'] == 'true') return contact;
    }
    return contacts.first;
  }

  static Future<void> _call(BuildContext context, String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return;
    final launched = await launchUrl(Uri(scheme: 'tel', path: cleaned));
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível iniciar a ligação.')),
      );
    }
  }
}

class _HealthInfoSheet extends StatefulWidget {
  const _HealthInfoSheet({required this.initial});

  final Map<String, String>? initial;

  @override
  State<_HealthInfoSheet> createState() => _HealthInfoSheetState();
}

class _HealthInfoSheetState extends State<_HealthInfoSheet> {
  late final TextEditingController _allergies;
  late final TextEditingController _conditions;
  late final TextEditingController _bloodType;
  late final TextEditingController _continuousMedications;
  late final TextEditingController _doctor;
  late final TextEditingController _healthInsurance;
  late final TextEditingController _preferredHospital;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _allergies = TextEditingController(text: initial?['allergies']);
    _conditions = TextEditingController(text: initial?['conditions']);
    _bloodType = TextEditingController(text: initial?['bloodType']);
    _continuousMedications = TextEditingController(
      text: initial?['continuousMedications'],
    );
    _doctor = TextEditingController(text: initial?['doctor']);
    _healthInsurance = TextEditingController(text: initial?['healthInsurance']);
    _preferredHospital = TextEditingController(
      text: initial?['preferredHospital'],
    );
    _notes = TextEditingController(text: initial?['notes']);
  }

  @override
  void dispose() {
    _allergies.dispose();
    _conditions.dispose();
    _bloodType.dispose();
    _continuousMedications.dispose();
    _doctor.dispose();
    _healthInsurance.dispose();
    _preferredHospital.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cartão de Saúde',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.md),
            _SheetField(label: 'Alergias', controller: _allergies),
            _SheetField(label: 'Condições', controller: _conditions),
            _SheetField(label: 'Tipo sanguíneo', controller: _bloodType),
            _SheetField(
              label: 'Medicamentos contínuos',
              controller: _continuousMedications,
            ),
            _SheetField(label: 'Médico de referência', controller: _doctor),
            _SheetField(label: 'Plano de saúde', controller: _healthInsurance),
            _SheetField(
              label: 'Hospital preferencial',
              controller: _preferredHospital,
            ),
            _SheetField(label: 'Observações', controller: _notes),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Salvar Cartão de Saúde',
              onPressed: () => Navigator.of(context).pop({
                'allergies': _allergies.text.trim(),
                'conditions': _conditions.text.trim(),
                'bloodType': _bloodType.text.trim(),
                'continuousMedications': _continuousMedications.text.trim(),
                'doctor': _doctor.text.trim(),
                'healthInsurance': _healthInsurance.text.trim(),
                'preferredHospital': _preferredHospital.text.trim(),
                'notes': _notes.text.trim(),
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyContactsSheet extends StatefulWidget {
  const _EmergencyContactsSheet({required this.initial});

  final List<Map<String, String>> initial;

  @override
  State<_EmergencyContactsSheet> createState() =>
      _EmergencyContactsSheetState();
}

class _EmergencyContactsSheetState extends State<_EmergencyContactsSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _relation = TextEditingController();
  late List<Map<String, String>> _contacts;

  @override
  void initState() {
    super.initState();
    _contacts = widget.initial.map((contact) => {...contact}).toList();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relation.dispose();
    super.dispose();
  }

  void _add() {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) return;
    final isPrimary = _contacts.isEmpty;
    setState(() {
      _contacts = [
        ..._contacts,
        {
          'name': _name.text.trim(),
          'phone': _phone.text.trim(),
          'relation': _relation.text.trim(),
          'isPrimary': isPrimary.toString(),
        },
      ];
      _name.clear();
      _phone.clear();
      _relation.clear();
    });
  }

  void _setPrimary(int index) {
    setState(() {
      _contacts = [
        for (var i = 0; i < _contacts.length; i++)
          {..._contacts[i], 'isPrimary': (i == index).toString()},
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Rede de emergência',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.md),
            _SheetField(label: 'Nome', controller: _name),
            _SheetField(label: 'Telefone', controller: _phone),
            _SheetField(label: 'Relação', controller: _relation),
            SecondaryButton(
              label: 'Adicionar contato',
              leadingIcon: Icons.add,
              onPressed: _add,
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < _contacts.length; i++) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: IconButton(
                  icon: Icon(
                    _contacts[i]['isPrimary'] == 'true'
                        ? Icons.star
                        : Icons.star_border,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _setPrimary(i),
                ),
                title: Text(_contacts[i]['name'] ?? ''),
                subtitle: Text(
                  [
                    _contacts[i]['relation'] ?? '',
                    _contacts[i]['phone'] ?? '',
                  ].where((value) => value.trim().isNotEmpty).join(' • '),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => setState(() => _contacts.removeAt(i)),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Salvar rede',
              onPressed: () => Navigator.of(context).pop(_contacts),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _NoTreatmentsIntro extends StatelessWidget {
  const _NoTreatmentsIntro({required this.dependentName});

  final String dependentName;

  @override
  Widget build(BuildContext context) {
    final firstName = dependentName.split(' ').first;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.medication, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ainda não há tratamento cadastrado',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quando quiser acompanhar medicamentos, estoque e doses de $firstName, cadastre o primeiro tratamento. Isso não depende do aceite do convite.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
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
