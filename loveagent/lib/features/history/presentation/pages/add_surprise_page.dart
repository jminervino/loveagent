import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../partner/domain/entities/partner.dart';
import '../../../partner/presentation/controllers/partner_controller.dart';
import '../../domain/entities/surprise.dart';
import '../controllers/history_controller.dart';

class AddSurprisePage extends ConsumerStatefulWidget {
  const AddSurprisePage({super.key});

  @override
  ConsumerState<AddSurprisePage> createState() => _AddSurprisePageState();
}

class _AddSurprisePageState extends ConsumerState<AddSurprisePage> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  String _selectedType = 'flores';
  DateTime _selectedDate = DateTime.now();
  Partner? _selectedPartner;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partnersAsync = ref.watch(partnersProvider);
    final controllerState = ref.watch(historyControllerProvider);
    final isLoading = controllerState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Surpresa')),
      body: partnersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (partners) {
          if (partners.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Cadastre uma parceira antes de registrar surpresas.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            );
          }

          _selectedPartner ??= partners.first;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Partner selector (only if multiple)
                if (partners.length > 1) ...[
                  Text('Parceira', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Partner>(
                    value: _selectedPartner,
                    items: partners
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedPartner = v),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.favorite_outline),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Type selector
                Text('Tipo de surpresa', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                _TypeSelector(
                  selected: _selectedType,
                  onChanged: (type) => setState(() => _selectedType = type),
                ),
                const SizedBox(height: 24),

                // Date
                Text('Data', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Note
                Text('Nota (opcional)', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Levei no restaurante italiano que ela queria...',
                  ),
                ),
                const SizedBox(height: 32),

                // Submit
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_selectedPartner == null) return;

    final surprise = Surprise(
      id: '',
      partnerId: _selectedPartner!.id,
      type: _selectedType,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      confirmedByUser: true,
    );

    final created =
        await ref.read(historyControllerProvider.notifier).create(surprise);

    if (created != null && mounted) {
      Navigator.pop(context, true);
    }
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: surpriseTypes.map((type) {
        final surprise = Surprise(
          id: '',
          partnerId: '',
          type: type,
          date: DateTime.now(),
        );
        final isSelected = type == selected;

        return ChoiceChip(
          label: Text('${surprise.typeEmoji} ${surprise.typeLabel}'),
          selected: isSelected,
          onSelected: (_) => onChanged(type),
          selectedColor: AppColors.primary.withOpacity(0.2),
          backgroundColor: Colors.transparent,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
