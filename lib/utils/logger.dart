import 'package:logging/logging.dart';

final logger = Logger('RunawayApp');

void setupLogger() {
  Logger.root.level = Level.ALL; // 모든 로그 레벨 출력
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}