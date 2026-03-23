import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/surprise.dart';
import '../controllers/history_controller.dart';
import 'add_surprise_page.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surprisesAsync = ref.watch(surprisesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAdd(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAdd(context, ref),
        child: const Icon(Icons.add),
      ),
      body: surprisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (surprises) {
          if (surprises.isEmpty) {
            return _EmptyState(onAdd: () => _navigateToAdd(context, ref));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(surprisesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: surprises.length,
              itemBuilder: (context, index) {
                final surprise = surprises[index];
                final showMonthHeader = index == 0 ||
                    _monthKey(surprise.date) !=
                        _monthKey(surprises[index - 1].date);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showMonthHeader) ...[
                      if (index > 0) const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _monthLabel(surprise.date),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                    _SurpriseCard(
                      surprise: surprise,
                      onDelete: () =>
                          _confirmDelete(context, ref, surprise),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _monthKey(DateTime date) => '${date.year}-${date.month}';

  String _monthLabel(DateTime date) {
    return DateFormat('MMMM yyyy', 'pt_BR').format(date);
  }

  Future<void> _navigateToAdd(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddSurprisePage()),
    );
    if (result == true) {
      ref.invalidate(surprisesProvider);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Surprise surprise,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover surpresa?'),
        content: Text('Remover "${surprise.typeLabel}" do histórico?'),
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
      await ref.read(historyControllerProvider.notifier).delete(surprise.id);
    }
  }
}

class _SurpriseCard extends StatelessWidget {
  const _SurpriseCard({
    required this.surprise,
    required this.onDelete,
  });

  final Surprise surprise;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                surprise.typeEmoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          surprise.typeLabel,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yy').format(surprise.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  if (surprise.partnerName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      surprise.partnerName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                  if (surprise.note != null && surprise.note!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      surprise.note!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (surprise.suggestedByAgent) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 14, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          'Sugerido pelo agente',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.accent,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Delete
            IconButton(
              icon: Icon(Icons.close, size: 18, color: AppColors.textSecondary),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
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
              Icons.history,
              size: 80,
              color: AppColors.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma surpresa registrada',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registre as surpresas que você fez para acompanhar seu histórico.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Registrar surpresa'),
            ),
          ],
        ),
      ),
    );
  }
}
