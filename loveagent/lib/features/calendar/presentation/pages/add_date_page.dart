import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
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
  Recurrence _recurrence = Recurrence.annual;
  String? _selectedPartnerId;

  // For monthly: only need a day number
  int _monthlyDay = DateTime.now().day;

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
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_recurrence != Recurrence.monthly && _date == null) {
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

    // For monthly, create a date with the selected day
    final dateToSave = _recurrence == Recurrence.monthly
        ? DateTime(DateTime.now().year, DateTime.now().month, _monthlyDay)
        : _date!;

    final specialDate = SpecialDate(
      id: '',
      partnerId: _selectedPartnerId!,
      label: _labelController.text.trim(),
      date: dateToSave,
      isAnnual: _recurrence == Recurrence.annual,
      recurrence: _recurrence,
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
              // Quick suggestions
              Text(
                'SUGESTÕES RÁPIDAS',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3,
                  color: AppColors.outline,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickChip(label: 'Mesversário', onTap: (l) {
                    _labelController.text = l;
                    setState(() => _recurrence = Recurrence.monthly);
                  }),
                  _QuickChip(label: 'Primeiro beijo', onTap: _setLabel),
                  _QuickChip(label: 'Primeiro encontro', onTap: _setLabel),
                  _QuickChip(label: 'Pedido de namoro', onTap: _setLabel),
                  _QuickChip(label: 'Noivado', onTap: _setLabel),
                  _QuickChip(label: 'Casamento', onTap: _setLabel),
                ],
              ),
              const SizedBox(height: 24),

              // Partner selector
              Text(
                'PARCEIRA',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3,
                  color: AppColors.outline,
                ),
              ),
              const SizedBox(height: 6),
              partnersAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Erro: $e'),
                data: (partners) {
                  if (partners.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      color: AppColors.surfaceContainerLow,
                      child: Text(
                        'Cadastre uma parceira primeiro',
                        style: TextStyle(color: AppColors.outline),
                      ),
                    );
                  }

                  if (partners.length == 1 && _selectedPartnerId == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() => _selectedPartnerId = partners.first.id);
                    });
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedPartnerId,
                    decoration: const InputDecoration(
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
              const SizedBox(height: 20),

              // Label
              Text(
                'NOME DA DATA',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3,
                  color: AppColors.outline,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _labelController,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: AppColors.onSurface),
                decoration: const InputDecoration(
                  hintText: 'Ex: Mesversário, Primeiro beijo',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Digite um nome' : null,
              ),
              const SizedBox(height: 20),

              // Recurrence selector
              Text(
                'REPETIÇÃO',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3,
                  color: AppColors.outline,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _RecurrenceChip(
                    label: 'Mensal',
                    icon: Icons.repeat,
                    selected: _recurrence == Recurrence.monthly,
                    onTap: () => setState(() => _recurrence = Recurrence.monthly),
                  ),
                  const SizedBox(width: 8),
                  _RecurrenceChip(
                    label: 'Anual',
                    icon: Icons.cake_outlined,
                    selected: _recurrence == Recurrence.annual,
                    onTap: () => setState(() => _recurrence = Recurrence.annual),
                  ),
                  const SizedBox(width: 8),
                  _RecurrenceChip(
                    label: 'Única',
                    icon: Icons.looks_one_outlined,
                    selected: _recurrence == Recurrence.once,
                    onTap: () => setState(() => _recurrence = Recurrence.once),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Date input — changes based on recurrence
              if (_recurrence == Recurrence.monthly) ...[
                Text(
                  'DIA DO MÊS',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3,
                    color: AppColors.outline,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _monthlyDay,
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceContainerHigh,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 16,
                      ),
                      items: List.generate(31, (i) => i + 1)
                          .map((day) => DropdownMenuItem(
                                value: day,
                                child: Text('Dia $day'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _monthlyDay = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Todo dia $_monthlyDay de cada mês',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else ...[
                Text(
                  'DATA',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3,
                    color: AppColors.outline,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(2),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _date != null
                          ? _dateFormat.format(_date!)
                          : 'Selecionar data',
                      style: TextStyle(
                        color: _date != null
                            ? AppColors.onSurface
                            : AppColors.outline,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),

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

class _RecurrenceChip extends StatelessWidget {
  const _RecurrenceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(2),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryContainer.withOpacity(0.3)
                  : AppColors.surfaceContainerLow,
              border: Border.all(
                color: selected
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.outlineVariant.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.outline,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                    color: selected ? AppColors.primary : AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      backgroundColor: AppColors.primaryContainer.withOpacity(0.15),
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: AppColors.primary,
        fontSize: 12,
      ),
    );
  }
}
