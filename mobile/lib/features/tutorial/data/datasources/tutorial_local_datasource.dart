import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

abstract class TutorialLocalDataSource {
  bool isTutorialSeen();
  Future<void> markTutorialSeen();
  Future<void> resetTutorial();
}

@LazySingleton(as: TutorialLocalDataSource)
class TutorialLocalDataSourceImpl implements TutorialLocalDataSource {
  static const String _boxName = 'app_prefs';
  static const String _key = 'tutorial_seen';

  @override
  bool isTutorialSeen() =>
      Hive.box<bool>(_boxName).get(_key, defaultValue: false)!;

  @override
  Future<void> markTutorialSeen() =>
      Hive.box<bool>(_boxName).put(_key, true);

  @override
  Future<void> resetTutorial() =>
      Hive.box<bool>(_boxName).put(_key, false);
}
