import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_error.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../shared/widgets/form_app_bar.dart';
import '../../../shared/widgets/labeled_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../../auth/presentation/providers/auth_providers.dart';

const _additionalInfoKey = 'dosecerta.profile.additional_info';
const _emergencyContactsKey = 'dosecerta.profile.emergency_contacts';
const _notificationPrefsKey = 'dosecerta.profile.notifications';

class AdditionalInfoPage extends ConsumerStatefulWidget {
  const AdditionalInfoPage({super.key});

  @override
  ConsumerState<AdditionalInfoPage> createState() => _AdditionalInfoPageState();
}

class _AdditionalInfoPageState extends ConsumerState<AdditionalInfoPage> {
  late final TextEditingController _allergies;
  late final TextEditingController _conditions;
  late final TextEditingController _bloodType;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    final data = ref
        .read(localCacheProvider)
        .readJson<Map<String, dynamic>>(
          _additionalInfoKey,
          (json) => Map<String, dynamic>.from(json as Map),
        );
    final initial = user?.additionalInfo ?? data;
    _allergies = TextEditingController(text: initial?['allergies'] as String?);
    _conditions = TextEditingController(
      text: initial?['conditions'] as String?,
    );
    _bloodType = TextEditingController(text: initial?['bloodType'] as String?);
    _notes = TextEditingController(text: initial?['notes'] as String?);
    _loadProfile();
  }

  @override
  void dispose() {
    _allergies.dispose();
    _conditions.dispose();
    _bloodType.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final result = await ref.read(authRepositoryProvider).getProfile();
      final data = result.user.additionalInfo;
      if (!mounted) return;
      if (data == null || data.values.every((value) => value.trim().isEmpty)) {
        final localPayload = _payload();
        if (localPayload.values.any((value) => value.trim().isNotEmpty)) {
          await ref
              .read(authRepositoryProvider)
              .updateProfile(additionalInfo: localPayload);
          ref.invalidate(currentUserProvider);
        }
        return;
      }
      setState(() {
        _allergies.text = data['allergies'] ?? '';
        _conditions.text = data['conditions'] ?? '';
        _bloodType.text = data['bloodType'] ?? '';
        _notes.text = data['notes'] ?? '';
      });
    } catch (_) {
      // Mantem os dados locais quando o backend nao estiver disponivel.
    }
  }

  Map<String, String> _payload() => {
    'allergies': _allergies.text.trim(),
    'conditions': _conditions.text.trim(),
    'bloodType': _bloodType.text.trim(),
    'notes': _notes.text.trim(),
  };

  Future<void> _save() async {
    final payload = _payload();
    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(additionalInfo: payload);
      ref.invalidate(currentUserProvider);
      await ref.read(localCacheProvider).writeJson(_additionalInfoKey, payload);
      if (mounted) _showMessage(context, 'Informações salvas no banco.');
    } catch (e) {
      await ref.read(localCacheProvider).writeJson(_additionalInfoKey, payload);
      if (mounted) {
        _showMessage(
          context,
          describeApiError(
            e,
            fallback:
                'Backend indisponível. Informações salvas neste aparelho.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Informações adicionais',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _IntroCard(
            icon: Icons.medical_information_outlined,
            title: 'Dados importantes para atendimento',
            text:
                'Registre informações que ajudam cuidadores e profissionais de saúde em situações de urgência.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsCard(
            children: [
              LabeledTextField(
                label: 'Alergias',
                hint: 'Ex.: dipirona, amendoim, látex',
                controller: _allergies,
              ),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                label: 'Doenças ou condições',
                hint: 'Ex.: diabetes, hipertensão, asma',
                controller: _conditions,
              ),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                label: 'Tipo sanguíneo',
                hint: 'Ex.: O+, A-, não sei',
                controller: _bloodType,
              ),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                label: 'Observações médicas',
                hint: 'Ex.: usa marcapasso, restrições, cuidados especiais',
                controller: _notes,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: 'Salvar informações', onPressed: _save),
        ],
      ),
    );
  }
}

class EmergencyContactsPage extends ConsumerStatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  ConsumerState<EmergencyContactsPage> createState() =>
      _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends ConsumerState<EmergencyContactsPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _relation = TextEditingController();
  List<_EmergencyContact> _contacts = const [];

  @override
  void initState() {
    super.initState();
    final userContacts = ref
        .read(currentUserProvider)
        ?.emergencyContacts
        .map(_EmergencyContact.fromJson)
        .toList();
    _contacts = userContacts?.isNotEmpty == true
        ? userContacts!
        : _readContacts();
    _loadProfile();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relation.dispose();
    super.dispose();
  }

  List<_EmergencyContact> _readContacts() {
    final data = ref
        .read(localCacheProvider)
        .readJson<List<dynamic>>(
          _emergencyContactsKey,
          (json) => List<dynamic>.from(json as List),
        );
    return (data ?? const [])
        .whereType<Map>()
        .map((item) => _EmergencyContact.fromJson(item))
        .toList();
  }

  Future<void> _persist(List<_EmergencyContact> contacts) async {
    final payload = contacts.map((contact) => contact.toJson()).toList();
    await ref
        .read(localCacheProvider)
        .writeJson(_emergencyContactsKey, payload);
    await ref
        .read(authRepositoryProvider)
        .updateProfile(emergencyContacts: payload);
    ref.invalidate(currentUserProvider);
  }

  Future<void> _loadProfile() async {
    try {
      final result = await ref.read(authRepositoryProvider).getProfile();
      final contacts = result.user.emergencyContacts
          .map(_EmergencyContact.fromJson)
          .toList();
      if (!mounted) return;
      if (contacts.isEmpty && _contacts.isNotEmpty) {
        await ref
            .read(authRepositoryProvider)
            .updateProfile(
              emergencyContacts: _contacts
                  .map((contact) => contact.toJson())
                  .toList(),
            );
        ref.invalidate(currentUserProvider);
        return;
      }
      setState(() => _contacts = contacts);
      await ref
          .read(localCacheProvider)
          .writeJson(
            _emergencyContactsKey,
            contacts.map((contact) => contact.toJson()).toList(),
          );
    } catch (_) {
      // Mantem os dados locais quando o backend nao estiver disponivel.
    }
  }

  Future<void> _addContact() async {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      _showMessage(context, 'Informe pelo menos nome e telefone.');
      return;
    }
    final next = [
      ..._contacts,
      _EmergencyContact(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        relation: _relation.text.trim(),
      ),
    ];
    try {
      await _persist(next);
      setState(() => _contacts = next);
      _name.clear();
      _phone.clear();
      _relation.clear();
      if (mounted) _showMessage(context, 'Contato salvo no banco.');
    } catch (e) {
      await ref
          .read(localCacheProvider)
          .writeJson(
            _emergencyContactsKey,
            next.map((contact) => contact.toJson()).toList(),
          );
      setState(() => _contacts = next);
      if (mounted) {
        _showMessage(
          context,
          describeApiError(
            e,
            fallback: 'Backend indisponível. Contato salvo neste aparelho.',
          ),
        );
      }
    }
  }

  Future<void> _removeContact(int index) async {
    final next = [..._contacts]..removeAt(index);
    try {
      await _persist(next);
      setState(() => _contacts = next);
    } catch (e) {
      await ref
          .read(localCacheProvider)
          .writeJson(
            _emergencyContactsKey,
            next.map((contact) => contact.toJson()).toList(),
          );
      setState(() => _contacts = next);
      if (mounted) {
        _showMessage(
          context,
          describeApiError(
            e,
            fallback: 'Backend indisponível. Remoção salva neste aparelho.',
          ),
        );
      }
    }
  }

  Future<void> _call(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      _showMessage(context, 'Não foi possível iniciar a ligação.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Contatos de emergência',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsCard(
            children: [
              LabeledTextField(
                label: 'Nome',
                hint: 'Ex.: Maria Souza',
                controller: _name,
              ),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                label: 'Telefone',
                hint: 'Ex.: (11) 99999-9999',
                controller: _phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                label: 'Relação',
                hint: 'Ex.: filha, cuidador, vizinho',
                controller: _relation,
              ),
              const SizedBox(height: AppSpacing.lg),
              SecondaryButton(
                label: 'Adicionar contato',
                onPressed: _addContact,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_contacts.isEmpty)
            const _EmptyCard(
              icon: Icons.contact_phone_outlined,
              text: 'Nenhum contato cadastrado ainda.',
            )
          else
            for (var i = 0; i < _contacts.length; i++) ...[
              _ContactCard(
                contact: _contacts[i],
                onCall: () => _call(_contacts[i].phone),
                onRemove: () => _removeContact(i),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class NotificationsSettingsPage extends ConsumerStatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  ConsumerState<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState
    extends ConsumerState<NotificationsSettingsPage> {
  bool _enabled = true;
  bool _medications = true;
  bool _appointments = true;
  bool _caregiver = true;

  @override
  void initState() {
    super.initState();
    final data = ref
        .read(localCacheProvider)
        .readJson<Map<String, dynamic>>(
          _notificationPrefsKey,
          (json) => Map<String, dynamic>.from(json as Map),
        );
    _enabled = data?['enabled'] as bool? ?? true;
    _medications = data?['medications'] as bool? ?? true;
    _appointments = data?['appointments'] as bool? ?? true;
    _caregiver = data?['caregiver'] as bool? ?? true;
  }

  Future<void> _save() async {
    await ref.read(localCacheProvider).writeJson(_notificationPrefsKey, {
      'enabled': _enabled,
      'medications': _medications,
      'appointments': _appointments,
      'caregiver': _caregiver,
    });
    if (mounted) _showSaved(context);
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Notificações',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusCard(
            active: _enabled,
            title: _enabled ? 'Notificações ativadas' : 'Notificações pausadas',
            subtitle: _enabled
                ? 'O DoseCerta pode avisar sobre doses, consultas e cuidados.'
                : 'Os avisos estão pausados neste dispositivo.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsCard(
            children: [
              _SwitchRow(
                title: 'Ativar notificações',
                subtitle: 'Controle geral dos alertas do app.',
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
              const Divider(height: 1),
              _SwitchRow(
                title: 'Lembretes de medicamentos',
                subtitle: 'Avisos antes do horário das doses.',
                value: _enabled && _medications,
                onChanged: _enabled
                    ? (value) => setState(() => _medications = value)
                    : null,
              ),
              const Divider(height: 1),
              _SwitchRow(
                title: 'Consultas',
                subtitle: 'Avisos de consultas agendadas.',
                value: _enabled && _appointments,
                onChanged: _enabled
                    ? (value) => setState(() => _appointments = value)
                    : null,
              ),
              const Divider(height: 1),
              _SwitchRow(
                title: 'Responsáveis',
                subtitle: 'Avisos para cuidadores e dependentes.',
                value: _enabled && _caregiver,
                onChanged: _enabled
                    ? (value) => setState(() => _caregiver = value)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: 'Salvar preferências', onPressed: _save),
        ],
      ),
    );
  }
}

class PrivacySecurityPage extends ConsumerStatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  ConsumerState<PrivacySecurityPage> createState() =>
      _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends ConsumerState<PrivacySecurityPage> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _name = TextEditingController(text: user?.name ?? '');
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _saveProfileAndPassword() async {
    final changingPassword =
        _currentPassword.text.isNotEmpty || _newPassword.text.isNotEmpty;
    if (changingPassword &&
        (_currentPassword.text.isEmpty || _newPassword.text.length < 6)) {
      _showMessage(
        context,
        'Informe a senha atual e uma nova senha com 6+ caracteres.',
      );
      return;
    }
    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(
            name: _name.text.trim(),
            email: _email.text.trim(),
            currentPassword: changingPassword ? _currentPassword.text : null,
            newPassword: changingPassword ? _newPassword.text : null,
          );
      _currentPassword.clear();
      _newPassword.clear();
      ref.invalidate(currentUserProvider);
      if (mounted) _showMessage(context, 'Alterações salvas no banco.');
    } catch (e) {
      if (mounted) {
        _showMessage(
          context,
          describeApiError(e, fallback: 'Não foi possível salvar alterações.'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Privacidade e segurança',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsCard(
            children: [
              LabeledTextField(
                label: 'Nome',
                hint: 'Seu nome',
                controller: _name,
              ),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                label: 'E-mail',
                hint: 'seu@email.com',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsCard(
            children: [
              LabeledTextField(
                label: 'Senha atual',
                hint: 'Digite sua senha atual',
                controller: _currentPassword,
                obscureText: true,
              ),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                label: 'Nova senha',
                hint: 'Mínimo de 6 caracteres',
                controller: _newPassword,
                obscureText: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: 'Salvar', onPressed: _saveProfileAndPassword),
        ],
      ),
    );
  }
}

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return _SettingsScaffold(
      title: 'Tema',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _IntroCard(
            icon: Icons.contrast_outlined,
            title: 'Escolha a aparência',
            text: 'A preferência fica salva neste dispositivo.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsCard(
            children: [
              _RadioRow(
                title: 'Claro',
                subtitle: 'Interface branca padrão do DoseCerta.',
                value: ThemeMode.light,
                groupValue: mode,
                onChanged: (value) =>
                    ref.read(themeModeProvider.notifier).setMode(value),
              ),
              const Divider(height: 1),
              _RadioRow(
                title: 'Escuro',
                subtitle: 'Interface com fundos escuros e menor brilho.',
                value: ThemeMode.dark,
                groupValue: mode,
                onChanged: (value) =>
                    ref.read(themeModeProvider.notifier).setMode(value),
              ),
              const Divider(height: 1),
              _RadioRow(
                title: 'Sistema',
                subtitle: 'Segue a configuração do aparelho.',
                value: ThemeMode.system,
                groupValue: mode,
                onChanged: (value) =>
                    ref.read(themeModeProvider.notifier).setMode(value),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AboutDoseCertaPage extends StatelessWidget {
  const AboutDoseCertaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Sobre o DoseCerta',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _IntroCard(
            icon: Icons.favorite_outline,
            title: 'DoseCerta',
            text:
                'O DoseCerta ajuda pacientes e cuidadores a organizar medicamentos, doses, consultas e contatos importantes de saúde.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsCard(
            children: [
              Text(
                'As informações registradas no app servem como apoio à rotina de cuidado e não substituem orientação médica. Em caso de urgência, procure atendimento especializado.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (_) => const _TermsSheet(),
                ),
                icon: Icon(Icons.description_outlined),
                label: Text('Termos de uso da aplicação'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsScaffold extends StatelessWidget {
  const _SettingsScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FormAppBar(title: title),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.huge,
        ),
        children: [child],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1B1F1F) : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: dark ? const Color(0xFF3B3030) : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.active,
    required this.title,
    required this.subtitle,
  });

  final bool active;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: active ? AppColors.successLight : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          Icon(
            active
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            color: active ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
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

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : context.appTextMuted,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.onCall,
    required this.onRemove,
  });

  final _EmergencyContact contact;
  final VoidCallback onCall;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      children: [
        Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.person_outline, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    [
                      contact.relation,
                      contact.phone,
                    ].where((item) => item.isNotEmpty).join(' • '),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(label: 'Ligar', onPressed: onCall),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: onRemove,
              icon: Icon(Icons.delete_outline, color: AppColors.error),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      children: [
        Icon(icon, color: context.appTextMuted, size: 32),
        const SizedBox(height: AppSpacing.sm),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TermsSheet extends StatelessWidget {
  const _TermsSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Termos de uso',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Ao usar o DoseCerta, você concorda em manter suas informações atualizadas e entende que os lembretes são apoio à rotina, não substituição de orientação médica. Dados salvos localmente neste dispositivo devem ser protegidos pelo próprio usuário.',
            style: TextStyle(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Entendi',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContact {
  const _EmergencyContact({
    required this.name,
    required this.phone,
    required this.relation,
  });

  final String name;
  final String phone;
  final String relation;

  factory _EmergencyContact.fromJson(Map<dynamic, dynamic> json) {
    return _EmergencyContact(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      relation: json['relation'] as String? ?? '',
    );
  }

  Map<String, String> toJson() => {
    'name': name,
    'phone': phone,
    'relation': relation,
  };
}

void _showSaved(BuildContext context) {
  _showMessage(context, 'Informações salvas.');
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
