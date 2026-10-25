import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medication_scheduler/features/medications/presentation/providers/medication_provider.dart';
import 'package:medication_scheduler/features/medications/presentation/pages/medication_setup_page.dart';
import 'package:medication_scheduler/features/medications/presentation/pages/medication_detail_page.dart';
import 'package:medication_scheduler/features/medications/domain/entities/medication.dart';

class MedicationListPage extends StatelessWidget {
  const MedicationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationProvider>(
      builder: (context, medProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Medications'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => Navigator.pushNamed(context, '/setup'),
              ),
            ],
          ),
          body: medProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : medProvider.medications.isEmpty
                  ? _buildEmptyState(context)
                  : _buildMedicationList(context, medProvider),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'No Medications Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first medication to get started',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Medication'),
              onPressed: () => Navigator.pushNamed(context, '/setup'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationList(BuildContext context, MedicationProvider medProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medProvider.medications.length,
      itemBuilder: (context, index) {
        final medication = medProvider.medications[index];
        final isSelected = medProvider.selectedMedication?.id == medication.id;
        return _buildMedicationCard(context, medication, isSelected, medProvider);
      },
    );
  }

  Widget _buildMedicationCard(
    BuildContext context,
    Medication medication,
    bool isSelected,
    MedicationProvider medProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.medication_outlined,
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onPrimaryContainer,
            size: 28,
          ),
        ),
        title: Text(
          medication.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? colorScheme.onPrimaryContainer : null,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (medication.dosage != null) ...[
              const SizedBox(height: 4),
              Text(
                medication.dosage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                          : colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Ref: ${medication.referenceDate.formatShort()} • Every other day',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                        : colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value, medication, medProvider),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'select', child: Text('Select')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () {
          if (!isSelected) {
            medProvider.selectMedication(medication);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MedicationDetailPage(medication: medication),
              ),
            );
          }
        },
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    Medication medication,
    MedicationProvider medProvider,
  ) {
    switch (action) {
      case 'select':
        medProvider.selectMedication(medication);
        break;
      case 'edit':
        _showEditDialog(context, medication, medProvider);
        break;
      case 'delete':
        _confirmDelete(context, medication, medProvider);
        break;
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    Medication medication,
    MedicationProvider medProvider,
  ) async {
    final nameController = TextEditingController(text: medication.name);
    final dosageController = TextEditingController(text: medication.dosage ?? '');
    final notesController = TextEditingController(text: medication.notes ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Medication'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dosageController,
                decoration: const InputDecoration(labelText: 'Dosage (optional)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final updated = medication.copyWith(
                name: nameController.text.trim(),
                dosage: dosageController.text.trim().isEmpty ? null : dosageController.text.trim(),
                notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
              );
              await medProvider.editMedication(updated);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Medication medication,
    MedicationProvider medProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication?'),
        content: Text('Are you sure you want to delete "${medication.name}"? This will also delete all history records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await medProvider.removeMedication(medication.id);
    }
  }
}