import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../calendar/domain/entities/special_date.dart';
import '../../../calendar/presentation/controllers/calendar_controller.dart';
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

class _Dashboard extends ConsumerWidget {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final upcomingAsync = ref.watch(upcomingDatesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Countdown card
          upcomingAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (dates) => _CountdownSection(
              dates: dates,
              partnerLikes: partner.likes,
            ),
          ),

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

class _CountdownSection extends StatelessWidget {
  const _CountdownSection({
    required this.dates,
    required this.partnerLikes,
  });

  final List<SpecialDate> dates;
  final List<String> partnerLikes;

  @override
  Widget build(BuildContext context) {
    if (dates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          color: AppColors.success.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: AppColors.success, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tudo tranquilo!',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nenhuma data importante nos próximos dias.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final next = dates.first;
    final days = next.daysUntil ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _CountdownCard(
        date: next,
        days: days,
        partnerLikes: partnerLikes,
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({
    required this.date,
    required this.days,
    required this.partnerLikes,
  });

  final SpecialDate date;
  final int days;
  final List<String> partnerLikes;

  Color get _bgColor {
    if (days == 0) return AppColors.error;
    if (days <= 1) return AppColors.error;
    if (days <= 7) return AppColors.accent;
    if (days <= 15) return Colors.amber.shade700;
    return AppColors.primary;
  }

  String get _daysText {
    if (days == 0) return 'HOJE!';
    if (days == 1) return 'AMANHÃ';
    return '$days dias';
  }

  String? get _hint {
    if (partnerLikes.isEmpty) return null;
    final likesText = partnerLikes.take(2).join(' e ');
    return 'Ela gosta de $likesText';
  }

  @override
  Widget build(BuildContext context) {
    final displayDate = date.nextOccurrence ?? date.date;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_bgColor, _bgColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _bgColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Row(
              children: [
                if (date.isAnnual)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.repeat, size: 16, color: Colors.white70),
                  ),
                Expanded(
                  child: Text(
                    date.label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (date.partnerName != null)
                  Text(
                    date.partnerName!,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Big number
            Center(
              child: Text(
                _daysText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: days == 0 || days == 1 ? 40 : 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Date
            Center(
              child: Text(
                DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR')
                    .format(displayDate),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),

            // Hint
            if (_hint != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _hint!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
