import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  group('Int32 OverflowException', () {
    group('Biger than Int32.MAX_INTEGER', () {
      test('Constructor', () {
        Type? type;
        try {
          Int32 _ = Int32(Int32.MAX_INTEGER + 1);
        } catch (e) {
          type = e.runtimeType;
        }
        expect(type, OverflowException);
      });

      test('Plus', () {
        Type? type;
        try {
          IntX _ = Int32(Int32.MAX_INTEGER) + Int32(1);
        } catch (e) {
          type = e.runtimeType;
        }
        expect(type, OverflowException);
      });

      test('Minus', () {
        Type? type;
        try {
          IntX _ = Int32(Int32.MAX_INTEGER) - Int32(-1);
        } catch (e) {
          type = e.runtimeType;
        }
        expect(type, OverflowException);
      });

      test('Multiply', () {
        Type? type;
        try {
          IntX _ = Int32(Int32.MAX_INTEGER) * Int32(2);
        } catch (e) {
          type = e.runtimeType;
        }
        expect(type, OverflowException);
      });

      test('<<', () {
        Type? type;
        try {
          IntX _ = Int32(Int32.MAX_INTEGER) << 1;
        } catch (e) {
          type = e.runtimeType;
        }
        expect(type, OverflowException);
      });
    });

    group('Valid Int32', () {
      test('Constructor', () {
        Type? type;
        try {
          Int32 _ = Int32(0);
        } catch (e) {
          type = e.runtimeType;
        }
        expect(type, null);
      });

      test('Plus', () {
        Type? type;
        try {
          IntX _ = Int32(3) + Int32(2);
        } catch (e) {
          type = e.runtimeType;
        }
        expect(type, null);
      });

      test('Minus', () {
        Type? type;
        try {
          IntX _ = Int32(3) - Int32(2);
        } catch (e) {
          type = e.runtimeType;
        }
        expect(type, null);
      });

      test('Multiply', () {
        Type? type;
        try {
          IntX _ = Int32(3) * Int32(2);
        } catch (e) {
          type = e.runtimeType;
        }
        expect(type, null);
      });

      test('<<', () {
        Type? type;
        try {
          IntX _ = Int32(3) << 2;
        } catch (e) {
          type = e.runtimeType;
        }
        expect(type, null);
      });
    });

    group('Lower than Int32.MIN_INTEGER', () {
      test('Constructor', () {
        Type? type;
        try {
          Int32 _ = Int32(Int32.MIN_INTEGER - 1);
        } catch (e) {
          type = e.runtimeType;
        }
        expect(type, OverflowException);
      });

      test('Plus', () {
        Type? type;
        try {
          IntX _ = Int32(Int32.MIN_INTEGER) + Int32(-1);
        } catch (e) {
          type = e.runtimeType;
        }
        expect(type, OverflowException);
      });

      test('Minus', () {
        Type? type;
        try {
          IntX _ = Int32(Int32.MIN_INTEGER) - Int32(1);
        } catch (e) {
          type = e.runtimeType;
        }
        expect(type, OverflowException);
      });

      test('Multiply', () {
        Type? type;
        try {
          IntX x = Int32(Int32.MIN_INTEGER) * Int32(2);
          print(x);
        } catch (e) {
          type = e.runtimeType;
        }
        expect(type, OverflowException);
      });

      test('<<', () {
        Type? type;
        try {
          IntX _ = Int32(Int32.MIN_INTEGER) << 1;
        } catch (e) {
          type = e.runtimeType;
        }
        expect(type, OverflowException);
      });
    });
  });
}
