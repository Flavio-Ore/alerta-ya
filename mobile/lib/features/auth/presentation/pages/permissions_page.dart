import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:alertaya/app/di/injection.dart';
import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/storage/secure_storage_service.dart';
import 'package:alertaya/core/widgets/alertaya_button.dart';

const permissionsRequestedKey = 'permissions_requested';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  final _storage = getIt<SecureStorageService>();
  int _currentIndex = 0;
  bool _requesting = false;
  bool _permanentlyDenied = false;

  List<_PermissionItem> get _items => [
        const _PermissionItem(
          permission: Permission.microphone,
          icon: Icons.mic_outlined,
          title: 'Micrófono',
          description:
              'Permite grabar audio cifrado durante una emergencia de pánico.',
        ),
        const _PermissionItem(
          permission: Permission.locationWhenInUse,
          icon: Icons.location_on_outlined,
          title: 'Ubicación',
          description:
              'Comparte tu posición GPS durante alertas y emergencias activas.',
        ),
        const _PermissionItem(
          permission: Permission.sms,
          icon: Icons.sms_outlined,
          title: 'SMS',
          description:
              'Envía un mensaje automático a tu contacto de confianza si activas pánico.',
        ),
        const _PermissionItem(
          permission: Permission.camera,
          icon: Icons.photo_camera_outlined,
          title: 'Cámara',
          description:
              'Permite adjuntar evidencia visual al reportar incidentes.',
        ),
        if (!kIsWeb && Platform.isAndroid)
          const _PermissionItem(
            permission: Permission.notification,
            icon: Icons.notifications_active_outlined,
            title: 'Notificaciones',
            description:
                'Recibe alertas en tiempo real cuando ocurre algo cerca de tu zona.',
          ),
      ];

  _PermissionItem get _current => _items[_currentIndex];

  Future<void> _requestCurrent() async {
    if (_requesting) return;
    setState(() {
      _requesting = true;
      _permanentlyDenied = false;
    });

    final status = await _current.permission.request();
    if (!mounted) return;

    if (status.isPermanentlyDenied || status.isRestricted) {
      setState(() {
        _requesting = false;
        _permanentlyDenied = true;
      });
      return;
    }

    setState(() => _requesting = false);
    await _next();
  }

  Future<void> _next() async {
    if (_currentIndex < _items.length - 1) {
      setState(() {
        _currentIndex++;
        _permanentlyDenied = false;
      });
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    await _storage.write(permissionsRequestedKey, 'true');
    if (!mounted) return;
    context.go('/map');
  }

  @override
  Widget build(BuildContext context) {
    final progress = _items.isEmpty ? 1.0 : (_currentIndex + 1) / _items.length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                color: AppColors.secondary,
                backgroundColor: AppColors.surfaceContainerHigh,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _current.icon,
                        color: AppColors.primary,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      _current.title,
                      style: AppTextStyles.headlineLg,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _current.description,
                      style: AppTextStyles.bodyMd,
                      textAlign: TextAlign.center,
                    ),
                    if (_permanentlyDenied) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Este permiso está bloqueado. Puedes activarlo desde la configuración del sistema.',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.severityModerate,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              if (_permanentlyDenied) ...[
                const AlertaYaButton(
                  label: 'Abrir configuración',
                  onPressed: openAppSettings,
                ),
                const SizedBox(height: 8),
              ] else
                AlertaYaButton(
                  label: _requesting ? 'Solicitando...' : 'Permitir',
                  onPressed: _requesting ? null : _requestCurrent,
                ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: TextButton(
                  onPressed: _requesting ? null : _next,
                  child: Text(
                    _currentIndex == _items.length - 1
                        ? 'Continuar'
                        : 'Omitir por ahora',
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionItem {
  const _PermissionItem({
    required this.permission,
    required this.icon,
    required this.title,
    required this.description,
  });

  final Permission permission;
  final IconData icon;
  final String title;
  final String description;
}
