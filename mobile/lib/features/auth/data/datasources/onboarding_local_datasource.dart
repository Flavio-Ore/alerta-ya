import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

abstract class OnboardingLocalDataSource {
  bool isFirstLaunch();
  Future<void> completeOnboarding();
}

@LazySingleton(as: OnboardingLocalDataSource)
class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  static const String _boxName = 'app_prefs';
  static const String _key = 'onboarding_completed';

  @override
  bool isFirstLaunch() =>
      !Hive.box<bool>(_boxName).get(_key, defaultValue: false)!;

  @override
  Future<void> completeOnboarding() =>
      Hive.box<bool>(_boxName).put(_key, true);
}
