import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/partner.dart';
import '../controllers/partner_controller.dart';
import '../widgets/tag_input_field.dart';

class PartnerFormPage extends ConsumerStatefulWidget {
  const PartnerFormPage({super.key, this.partner});

  final Partner? partner;

  bool get isEditing => partner != null;

  @override
  ConsumerState<PartnerFormPage> createState() => _PartnerFormPageState();
}

class _PartnerFormPageState extends ConsumerState<PartnerFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;

  DateTime? _birthDate;
  DateTime? _relationshipStart;
  String _status = 'namorada';
  String _budgetLevel = 'moderado';
  List<String> _likes = [];
  List<String> _dislikes = [];

  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    final p = widget.partner;
    _nameController = TextEditingController(text: p?.name ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');
    _birthDate = p?.birthDate;
    _relationshipStart = p?.relationshipStart;
    _status = p?.status ?? 'namorada';
    _budgetLevel = p?.budgetLevel ?? 'moderado';
    _likes = List.from(p?.likes ?? []);
    _dislikes = List.from(p?.dislikes ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isBirthDate}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isBirthDate ? _birthDate : _relationshipStart) ?? now,
      firstDate: DateTime(1950),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        if (isBirthDate) {
          _birthDate = picked;
        } else {
          _relationshipStart = picked;
        }
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser!.id;

    final partner = Partner(
      id: widget.partner?.id ?? '',
      userId: userId,
      name: _nameController.text.trim(),
      birthDate: _birthDate,
      relationshipStart: _relationshipStart,
      status: _status,
      likes: _likes,
      dislikes: _dislikes,
      budgetLevel: _budgetLevel,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final controller = ref.read(partnerControllerProvider.notifier);
    bool success;

    if (widget.isEditing) {
      success = await controller.update(partner);
    } else {
      final created = await controller.create(partner);
      success = created != null;
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing ? 'Parceira atualizada' : 'Parceira cadastrada',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(partnerControllerProvider);
    final isLoading = controllerState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar parceira' : 'Nova parceira'),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _handleDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === NOME ===
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome dela',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Digite o nome' : null,
              ),
              const SizedBox(height: 16),

              // === STATUS ===
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.favorite_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'namorada', child: Text('Namorada')),
                  DropdownMenuItem(value: 'noiva', child: Text('Noiva')),
                  DropdownMenuItem(value: 'esposa', child: Text('Esposa')),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 16),

              // === DATAS ===
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Aniversário dela',
                      value: _birthDate,
                      dateFormat: _dateFormat,
                      onTap: () => _pickDate(isBirthDate: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'Início do namoro',
                      value: _relationshipStart,
                      dateFormat: _dateFormat,
                      onTap: () => _pickDate(isBirthDate: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // === GOSTOS ===
              Text(
                'O que ela gosta',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TagInputField(
                tags: _likes,
                hintText: 'Ex: flores amarelas, chocolate, sushi...',
                onChanged: (tags) => setState(() => _likes = tags),
              ),
              const SizedBox(height: 16),

              // === NÃO GOSTA ===
              Text(
                'O que ela NÃO gosta',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TagInputField(
                tags: _dislikes,
                hintText: 'Ex: surpresas em público, rosas...',
                onChanged: (tags) => setState(() => _dislikes = tags),
              ),
              const SizedBox(height: 24),

              // === ORÇAMENTO ===
              DropdownButtonFormField<String>(
                value: _budgetLevel,
                decoration: const InputDecoration(
                  labelText: 'Orçamento médio',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'economico',
                    child: Text('Econômico'),
                  ),
                  DropdownMenuItem(
                    value: 'moderado',
                    child: Text('Moderado'),
                  ),
                  DropdownMenuItem(
                    value: 'generoso',
                    child: Text('Generoso'),
                  ),
                ],
                onChanged: (v) => setState(() => _budgetLevel = v!),
              ),
              const SizedBox(height: 16),

              // === NOTAS ===
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Notas livres',
                  hintText:
                      'Qualquer detalhe que ajude o agente a sugerir melhor...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // === SAVE ===
              ElevatedButton(
                onPressed: isLoading ? null : _handleSave,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isEditing ? 'Salvar' : 'Cadastrar'),
              ),

              if (controllerState is AsyncError) ...[
                const SizedBox(height: 16),
                Text(
                  'Erro ao salvar. Tente novamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.error),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover parceira?'),
        content: const Text('Isso vai remover o perfil e todas as datas associadas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(partnerControllerProvider.notifier)
          .delete(widget.partner!.id);

      if (success && mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.dateFormat,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today, size: 20),
        ),
        child: Text(
          value != null ? dateFormat.format(value!) : 'Selecionar',
          style: TextStyle(
            color: value != null
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
