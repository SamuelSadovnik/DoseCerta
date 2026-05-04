import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/stock/domain/entities/medication.dart';
import '../providers/admin_providers.dart';

class AdminMedicationsPage extends ConsumerWidget {
  const AdminMedicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminMedicationsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Medicamentos',
          style: TextStyle(color: AppColors.primary),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (meds) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminMedicationsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            itemCount: meds.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (_, i) => _MedTile(med: meds[i]),
          ),
        ),
      ),
    );
  }
}

class _MedTile extends StatelessWidget {
  const _MedTile({required this.med});
  final Medication med;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: AppColors.primaryLight,
        child: Icon(Icons.medical_services, color: AppColors.primary),
      ),
      title: Text(
        '${med.name} (${med.dosage})',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${med.currentQuantity}/${med.initialQuantity} ${med.unit.plural} · ${med.frequency}',
      ),
      trailing: med.isCritical
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'CRÍTICO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }
}
