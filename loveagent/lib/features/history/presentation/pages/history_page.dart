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
      body: surprisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (surprises) {
          if (surprises.isEmpty) {
            return _EmptyState(onAdd: () => _navigateToAdd(context, ref));
          }
          return _TimelineView(
            surprises: surprises,
            onAdd: () => _navigateToAdd(context, ref),
            onDelete: (s) => _confirmDelete(context, ref, s),
          );
        },
      ),
    );
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

class _TimelineView extends StatelessWidget {
  const _TimelineView({
    required this.surprises,
    required this.onAdd,
    required this.onDelete,
  });

  final List<Surprise> surprises;
  final VoidCallback onAdd;
  final void Function(Surprise) onDelete;

  @override
  Widget build(BuildContext context) {
    // Group by month
    final grouped = <String, List<Surprise>>{};
    for (final s in surprises) {
      final key = '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(s);
    }
    final months = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ARQUIVO',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Surpresas\nRealizadas',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    height: 1.0,
                    letterSpacing: -1.5,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Timeline
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final monthKey = months[index];
                final items = grouped[monthKey]!;
                final firstDate = items.first.date;
                final isFirst = index == 0;

                return _MonthSection(
                  label: DateFormat('MMMM yyyy', 'pt_BR').format(firstDate).toUpperCase(),
                  items: items,
                  isFirst: isFirst,
                  onDelete: onDelete,
                );
              },
              childCount: months.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({
    required this.label,
    required this.items,
    required this.isFirst,
    required this.onDelete,
  });

  final String label;
  final List<Surprise> items;
  final bool isFirst;
  final void Function(Surprise) onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 32, top: isFirst ? 0 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month header with dot
          Row(
            children: [
              SizedBox(
                width: 44,
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFirst ? AppColors.tertiary : AppColors.outline,
                      boxShadow: isFirst
                          ? [
                              BoxShadow(
                                color: AppColors.tertiary.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Items with timeline line
          ...items.asMap().entries.map((entry) {
            final surprise = entry.value;
            final isLast = entry.key == items.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Timeline line
                  SizedBox(
                    width: 44,
                    child: Center(
                      child: Container(
                        width: 1,
                        color: isLast
                            ? Colors.transparent
                            : AppColors.primary.withOpacity(0.15),
                      ),
                    ),
                  ),
                  // Card
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SurpriseCard(
                        surprise: surprise,
                        onDelete: () => onDelete(surprise),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withOpacity(0.4),
        border: Border(
          left: BorderSide(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: onDelete,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji + date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      surprise.typeEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    Text(
                      DateFormat('dd MMM', 'pt_BR')
                          .format(surprise.date)
                          .toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 10,
                        letterSpacing: 1,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Type label
                Text(
                  surprise.typeLabel,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    height: 1.2,
                  ),
                ),

                // Partner name
                if (surprise.partnerName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    surprise.partnerName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.outline,
                    ),
                  ),
                ],

                // Note
                if (surprise.note != null && surprise.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    surprise.note!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant.withOpacity(0.6),
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Agent badge
                if (surprise.suggestedByAgent) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 13, color: AppColors.tertiary),
                      const SizedBox(width: 4),
                      Text(
                        'SUGERIDO PELO AGENTE',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: AppColors.tertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
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
              size: 64,
              color: AppColors.primary.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma surpresa\nregistrada',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.w800,
                fontSize: 24,
                letterSpacing: -0.5,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registre as surpresas que você fez para\nacompanhar seu histórico.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.outline,
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
