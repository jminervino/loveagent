import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../partner/domain/entities/partner.dart';
import '../../../partner/presentation/controllers/partner_controller.dart';
import '../../../partner/presentation/pages/partner_form_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnersAsync = ref.watch(partnersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('LoveAgent')),
      body: partnersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (partners) {
          if (partners.isEmpty) {
            return _EmptyState();
          }
          return _Dashboard(partner: partners.first);
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 80,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Bem-vindo ao LoveAgent!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Cadastre sua parceira para começar a receber sugestões personalizadas.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PartnerFormPage(),
                  ),
                );
              },
              icon: const Icon(Icons.favorite),
              label: const Text('Cadastrar Parceira'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.partner});

  final Partner partner;

  String _statusLabel(String status) {
    switch (status) {
      case 'namorada':
        return 'Namorada';
      case 'noiva':
        return 'Noiva';
      case 'esposa':
        return 'Esposa';
      default:
        return status;
    }
  }

  String _budgetLabel(String budget) {
    switch (budget) {
      case 'economico':
        return 'Econômico';
      case 'moderado':
        return 'Moderado';
      case 'generoso':
        return 'Generoso';
      default:
        return budget;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Partner card
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PartnerFormPage(partner: partner),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: partner.photoUrl != null
                          ? NetworkImage(partner.photoUrl!)
                          : null,
                      child: partner.photoUrl == null
                          ? const Icon(Icons.person, size: 30, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            partner.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _statusLabel(partner.status),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick info row
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  icon: Icons.cake_outlined,
                  label: 'Aniversário',
                  value: partner.birthDate != null
                      ? '${partner.birthDate!.day.toString().padLeft(2, '0')}/${partner.birthDate!.month.toString().padLeft(2, '0')}'
                      : 'Não informado',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: Icons.attach_money,
                  label: 'Orçamento',
                  value: _budgetLabel(partner.budgetLevel),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Likes
          if (partner.likes.isNotEmpty) ...[
            Text('Gosta de', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: partner.likes
                  .map((tag) => Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Quick actions
          Text('Ações rápidas', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.calendar_month,
                  label: 'Calendário',
                  onTap: () => context.go('/calendar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.history,
                  label: 'Histórico',
                  onTap: () => context.push('/history'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.auto_awesome,
                  label: 'Sugestões',
                  onTap: () => context.go('/suggestions'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
