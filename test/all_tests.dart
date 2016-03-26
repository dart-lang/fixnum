import 'package:test/test.dart';

import 'int32_test.dart' as int32;
import 'int64_test.dart' as int64;

void main() {
  group('int32', int32.main);
  group('int64', int64.main);
}
