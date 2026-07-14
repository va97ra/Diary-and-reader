import 'package:dnevnik/features/diary/domain/diary_snapshot.dart';

abstract interface class DiaryRepository {
  Future<DiarySnapshot?> load();
  Future<void> save(DiarySnapshot snapshot);
}
