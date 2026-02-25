import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'models/user.dart';
import 'models/record_item.dart';
import 'models/transcript_item.dart';
import 'models/ai_summary_item.dart';
import 'models/vocabulary_item.dart';

class IsarService {
  static Isar? _isar;

  static Future<Isar> open() async {
    if (_isar != null && _isar!.isOpen) {
      return _isar!;
    }

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      schemas: [
        UserSchema,
        RecordItemSchema,
        TranscriptItemSchema,
        AISummaryItemSchema,
        VocabularyItemSchema,
      ],
      directory: dir.path,
    );
    return _isar!;
  }
}

