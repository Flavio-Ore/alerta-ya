import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/app/di/injection.dart';
import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/widgets/app_empty_state.dart';
import 'package:alertaya/core/widgets/app_error_state.dart';
import 'package:alertaya/features/alerts/presentation/bloc/alerts_bloc.dart';
import 'package:alertaya/features/my_reports/presentation/bloc/my_reports_bloc.dart';
import 'package:alertaya/features/my_reports/presentation/pages/my_reports_tab.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AlertsBloc>(
          create: (_) => getIt<AlertsBloc>()..add(const AlertsLoaded()),
        ),
        BlocProvider<MyReportsBloc>(
          create: (_) =>
              getIt<MyReportsBloc>()..add(const MyReportsLoaded(page: 1)),
        ),
      ],
      child: const _AlertsView(),
    );
  }
}

class _AlertsView extends StatefulWidget {
  const _AlertsView();

  @override
  State<_AlertsView> createState() => _AlertsViewState();
}

class _AlertsViewState extends State<_AlertsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Alertas', style: AppTextStyles.headlineMd),
        actions: [
          BlocBuilder<AlertsBloc, AlertsState>(
            builder: (context, state) {
              if (state is AlertsData && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () => context
                      .read<AlertsBloc>()
                      .add(const AlertsMarkAllRead()),
                  child: Text(
                    'Marcar todo como leído',
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.primary),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          labelStyle:
              AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: AppTextStyles.labelMd,
          tabs: const [
            Tab(text: 'Notificaciones'),
            Tab(text: 'Mis reportes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _NotificationsTab(),
          MyReportsTab(),
        ],
      ),
    );
  }
}

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlertsBloc, AlertsState>(
      builder: (context, state) {
        if (state is AlertsLoading || state is AlertsInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AlertsFailure) {
          return AppErrorState(
            message: state.message,
            onRetry: () =>
                context.read<AlertsBloc>().add(const AlertsLoaded()),
          );
        }
        if (state is AlertsData) {
          if (state.notifications.isEmpty) {
            return const AppEmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'Sin alertas',
              subtitle: 'Las alertas de tu zona aparecerán acá.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<AlertsBloc>().add(const AlertsRefreshed()),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppColors.outline),
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
        color: isRead
            ? null
            : AppColors.primary.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Punto de no leído
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6, right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRead ? Colors.transparent : AppColors.secondary,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLg.copyWith(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: AppTextStyles.bodyMd,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Text(district, style: AppTextStyles.labelMd),
                      const Spacer(),
                      Text(_timeAgo(createdAt), style: AppTextStyles.labelMd),
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
