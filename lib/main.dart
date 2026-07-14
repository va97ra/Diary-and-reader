import 'dart:ui';

import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/data/preferences_author_workspace_repository.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final repository = PreferencesAuthorWorkspaceRepository(preferences);
  final controller = AuthorWorkspaceController(repository);
  final systemLanguage = PlatformDispatcher.instance.locale.languageCode;
  await controller.load(preferredLanguage: systemLanguage);

  runApp(AuthorStudioApp(controller: controller));
}
