import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/app/di/injection.dart';
import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/features/alerts/presentation/bloc/alerts_bloc.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AlertsBloc>()..add(const AlertsLoaded()),
      child: const _AlertsView(),
    );
  }
}

class _AlertsView extends StatelessWidget {
  const _AlertsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.bgLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Alertas', style: AppTextStyles.h2),
        actions: [
          BlocBuilder<AlertsBloc, AlertsState>(
            builder: (context, state) {
              if (state is AlertsData && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () =>
                      context.read<AlertsBloc>().add(const AlertsMarkAllRead()),
                  child: Text(
                    'Marcar todo leído',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.primary),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<AlertsBloc, AlertsState>(
        builder: (context, state) {
          if (state is AlertsLoading || state is AlertsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AlertsFailure) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<AlertsBloc>().add(const AlertsLoaded()),
            );
          }
          if (state is AlertsData) {
            if (state.notifications.isEmpty) return const _EmptyView();
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<AlertsBloc>().add(const AlertsRefreshed()),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.notifications.length,
                separatorBuilder: (_, __) => const Divider(
                    height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final n = state.notifications[index];
                  return _NotificationTile(
                    title: n.title,
                    body: n.body,
                    district: n.district,
                    isRead: n.isRead,
                    createdAt: n.createdAt,
                    onTap: () {
                      context
                          .read<AlertsBloc>()
                          .add(AlertsNotificationTapped(n.id));
                      if (n.incidentId != null) {
                        context.push('/map/incident/${n.incidentId}');
                      }
                    },
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.body,
    required this.district,
    required this.isRead,
    required this.createdAt,
    required this.onTap,
  });
  final String title;
  final String body;
  final String district;
  final bool isRead;
  final DateTime createdAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isRead ? null : AppColors.primary.withOpacity(0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6, right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRead ? Colors.transparent : AppColors.accent,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight:
                          isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: AppTextStyles.bodySecondary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Text(district, style: AppTextStyles.caption),
                      const Spacer(),
                      Text(_timeAgo(createdAt), style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inDays}d';
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none_outlined,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Sin alertas', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text(
              'Las alertas de tu zona aparecerán acá.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('No se pudo cargar', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text(message,
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
}
