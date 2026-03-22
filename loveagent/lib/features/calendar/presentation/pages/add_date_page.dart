import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../partner/domain/entities/partner.dart';
import '../../../partner/presentation/controllers/partner_controller.dart';
import '../../domain/entities/special_date.dart';
import '../controllers/calendar_controller.dart';

class AddDatePage extends ConsumerStatefulWidget {
  const AddDatePage({super.key, this.preselectedPartnerId});

  final String? preselectedPartnerId;

  @override
  ConsumerState<AddDatePage> createState() => _AddDatePageState();
}

class _AddDatePageState extends ConsumerState<AddDatePage> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  DateTime? _date;
  bool _isAnnual = true;
  String? _selectedPartnerId;

  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _selectedPartnerId = widget.preselectedPartnerId;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma data')),
      );
      return;
    }
    if (_selectedPartnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a parceira')),
      );
      return;
    }

    final specialDate = SpecialDate(
      id: '',
      partnerId: _selectedPartnerId!,
      label: _labelController.text.trim(),
      date: _date!,
      isAnnual: _isAnnual,
    );

    final created =
        await ref.read(calendarControllerProvider.notifier).create(specialDate);

    if (created != null && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data adicionada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final partnersAsync = ref.watch(partnersProvider);
    final controllerState = ref.watch(calendarControllerProvider);
    final isLoading = controllerState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Nova data especial')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Suggestions
              Text(
                'Sugestões rápidas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickChip(label: 'Primeiro beijo', onTap: _setLabel),
                  _QuickChip(label: 'Primeiro encontro', onTap: _setLabel),
                  _QuickChip(label: 'Pedido de namoro', onTap: _setLabel),
                  _QuickChip(label: 'Noivado', onTap: _setLabel),
                  _QuickChip(label: 'Casamento', onTap: _setLabel),
                  _QuickChip(label: 'Dia especial', onTap: _setLabel),
                ],
              ),
              const SizedBox(height: 24),

              // Partner selector
              partnersAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Erro ao carregar parceiras: $e'),
                data: (partners) {
                  if (partners.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Cadastre uma parceira primeiro',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }

                  // Auto-select if only one partner
                  if (partners.length == 1 && _selectedPartnerId == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() => _selectedPartnerId = partners.first.id);
                    });
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedPartnerId,
                    decoration: const InputDecoration(
                      labelText: 'Parceira',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    items: partners.map((p) {
                      return DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedPartnerId = v),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Label
              TextFormField(
                controller: _labelController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nome da data',
                  hintText: 'Ex: Primeiro beijo',
                  prefixIcon: Icon(Icons.label_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Digite um nome' : null,
              ),
              const SizedBox(height: 16),

              // Date picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _date != null
                        ? _dateFormat.format(_date!)
                        : 'Selecionar data',
                    style: TextStyle(
                      color: _date != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Annual toggle
              SwitchListTile(
                title: const Text('Repete todo ano'),
                subtitle: const Text('Ativa lembretes anuais automáticos'),
                value: _isAnnual,
                onChanged: (v) => setState(() => _isAnnual = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              // Save
              ElevatedButton(
                onPressed: isLoading ? null : _handleSave,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Adicionar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setLabel(String label) {
    _labelController.text = label;
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: () => onTap(label),
      backgroundColor: AppColors.primary.withOpacity(0.08),
      side: BorderSide.none,
    );
  }
}
