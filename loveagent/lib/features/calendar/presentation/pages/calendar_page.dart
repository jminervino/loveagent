import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/special_date.dart';
import '../controllers/calendar_controller.dart';
import '../widgets/date_card.dart';
import 'add_date_page.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingDatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAdd(context),
          ),
        ],
      ),
      body: upcomingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (dates) {
          if (dates.isEmpty) {
            return _EmptyState(onAdd: () => _navigateToAdd(context));
          }

          // Group by urgency
          final critical = dates.where((d) =>
              d.urgency == UrgencyLevel.critical ||
              d.urgency == UrgencyLevel.high).toList();
          final upcoming = dates.where((d) =>
              d.urgency == UrgencyLevel.medium ||
              d.urgency == UrgencyLevel.low).toList();
          final later = dates.where((d) =>
              d.urgency == UrgencyLevel.none).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(upcomingDatesProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (critical.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Atenção',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 8),
                  ...critical.map((d) => _buildDateCard(context, ref, d)),
                  const SizedBox(height: 24),
                ],
                if (upcoming.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Próximas',
                    icon: Icons.upcoming_outlined,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(height: 8),
                  ...upcoming.map((d) => _buildDateCard(context, ref, d)),
                  const SizedBox(height: 24),
                ],
                if (later.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Mais adiante',
                    icon: Icons.calendar_month_outlined,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  ...later.map((d) => _buildDateCard(context, ref, d)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateCard(BuildContext context, WidgetRef ref, SpecialDate date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DateCard(
        date: date,
        onDelete: date.isSystem
            ? null
            : () => _confirmDelete(context, ref, date),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SpecialDate date,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover data?'),
        content: Text('Remover "${date.label}" do calendário?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(calendarControllerProvider.notifier).delete(date);
    }
  }

  void _navigateToAdd(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddDatePage()),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 80,
              color: AppColors.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma data próxima',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cadastre uma parceira para ver as datas automáticas, ou adicione datas manualmente',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar data'),
            ),
          ],
        ),
      ),
    );
  }
}
