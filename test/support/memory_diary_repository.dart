import 'package:dnevnik/features/diary/domain/diary_repository.dart';
import 'package:dnevnik/features/diary/domain/diary_snapshot.dart';

class MemoryDiaryRepository implements DiaryRepository {
  DiarySnapshot? snapshot;

  @override
  Future<DiarySnapshot?> load() async => snapshot;

  @override
  Future<void> save(DiarySnapshot snapshot) async {
    this.snapshot = DiarySnapshot.fromJson(snapshot.toJson());
  }
}
