import 'dart:ui';

import 'package:dnevnik/app/diary_app.dart';
import 'package:dnevnik/features/diary/application/diary_controller.dart';
import 'package:dnevnik/features/diary/data/preferences_diary_repository.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final repository = PreferencesDiaryRepository(preferences);
  final controller = DiaryController(repository);
  final systemLanguage = PlatformDispatcher.instance.locale.languageCode;
  await controller.load(preferredLanguage: systemLanguage);

  runApp(DiaryApp(controller: controller));
}
