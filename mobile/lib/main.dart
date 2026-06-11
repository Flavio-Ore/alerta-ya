import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:alertaya/app/app.dart';
import 'package:alertaya/app/di/injection.dart';
import 'package:alertaya/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno ANTES de cualquier otro init.
  // El archivo .env está en assets — gitignoreado, cada dev tiene el suyo.
  await dotenv.load(fileName: '.env');

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
  await Hive.initFlutter();
  await Hive.openBox<bool>('app_prefs');
  await configureDependencies();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Solicitar permiso de notificaciones en Android 13+ (silencioso — si el
  // usuario lo niega, se puede activar luego desde Configuración Personal).
  if (!kIsWeb && Platform.isAndroid) {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  runApp(const AlertaYaApp());
}
