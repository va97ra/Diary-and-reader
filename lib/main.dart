import 'dart:ui';

import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/data/book_version_repository_factory.dart';
import 'package:dnevnik/features/books/data/workspace_repository_factory.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final repository = await createAuthorWorkspaceRepository(preferences);
  final versionRepository = await createBookVersionRepository(preferences);
  final controller = AuthorWorkspaceController(
    repository,
    versionRepository: versionRepository,
  );
  final systemLanguage = PlatformDispatcher.instance.locale.languageCode;
  await controller.load(preferredLanguage: systemLanguage);

  runApp(AuthorStudioApp(controller: controller));
}
