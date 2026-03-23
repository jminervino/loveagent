import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../partner/presentation/controllers/partner_controller.dart';
import '../../../partner/presentation/pages/partner_form_page.dart';
import '../../../partner/presentation/pages/partner_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final partnersAsync = ref.watch(partnersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User info card
          authState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (user) {
              if (user == null) return const SizedBox.shrink();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          (user.name ?? user.email)[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name ?? 'Usuário',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: user.isPremium
                                    ? AppColors.accent.withOpacity(0.1)
                                    : AppColors.textSecondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                user.isPremium ? 'Premium' : 'Gratuito',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: user.isPremium
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Parceira section
          _SectionTitle(title: 'Parceira'),
          const SizedBox(height: 8),
          partnersAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (partners) {
              if (partners.isEmpty) {
                return _SettingsTile(
                  icon: Icons.favorite_outline,
                  title: 'Cadastrar parceira',
                  subtitle: 'Nenhuma parceira cadastrada',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PartnerFormPage()),
                  ),
                );
              }
              return Column(
                children: [
                  _SettingsTile(
                    icon: Icons.favorite,
                    title: partners.first.name,
                    subtitle: 'Editar perfil da parceira',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PartnerFormPage(partner: partners.first),
                      ),
                    ),
                  ),
                  if (partners.length > 1)
                    _SettingsTile(
                      icon: Icons.people_outline,
                      title: 'Todas as parceiras',
                      subtitle: '${partners.length} cadastradas',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PartnerPage()),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // App section
          _SectionTitle(title: 'Aplicativo'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notificações',
            subtitle: 'Em breve',
            enabled: false,
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Plano Premium',
            subtitle: 'Em breve',
            enabled: false,
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // Account section
          _SectionTitle(title: 'Conta'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Alterar senha',
            subtitle: 'Enviar email de redefinição',
            onTap: () => _resetPassword(context, ref),
          ),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Sair',
            subtitle: 'Encerrar sessão',
            titleColor: AppColors.error,
            onTap: () => _confirmLogout(context, ref),
          ),
          const SizedBox(height: 32),

          // App version
          Center(
            child: Text(
              'LoveAgent v1.0.0',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redefinir senha'),
        content: Text(
            'Enviaremos um email para ${user.email} com o link de redefinição.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success =
          await ref.read(authControllerProvider.notifier).resetPassword(user.email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Email de redefinição enviado!'
                : 'Erro ao enviar email. Tente novamente.'),
          ),
        );
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja encerrar a sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.titleColor,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Card(
        margin: const EdgeInsets.only(bottom: 4),
        child: ListTile(
          leading: Icon(icon, color: titleColor ?? AppColors.primary),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: titleColor,
            ),
          ),
          subtitle: subtitle != null
              ? Text(subtitle!, style: const TextStyle(fontSize: 12))
              : null,
          trailing: enabled
              ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
              : null,
          onTap: enabled ? onTap : null,
        ),
      ),
    );
  }
}
