// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  group('isX tests', () {
    test('isEven', () {
      expect((-Int32.one).isEven, false);
      expect(Int32.zero.isEven, true);
      expect(Int32.one.isEven, false);
      expect(Int32.two.isEven, true);
    });
    test('isMaxValue', () {
      expect(Int32.minValue.isMaxValue, false);
      expect(Int32.zero.isMaxValue, false);
      expect(Int32.maxValue.isMaxValue, true);
    });
    test('isMinValue', () {
      expect(Int32.minValue.isMinValue, true);
      expect(Int32.zero.isMinValue, false);
      expect(Int32.maxValue.isMinValue, false);
    });
    test('isNegative', () {
      expect(Int32.minValue.isNegative, true);
      expect(Int32.zero.isNegative, false);
      expect(Int32.one.isNegative, false);
    });
    test('isOdd', () {
      expect((-Int32.one).isOdd, true);
      expect(Int32.zero.isOdd, false);
      expect(Int32.one.isOdd, true);
      expect(Int32.two.isOdd, false);
    });
    test('isZero', () {
      expect(Int32.minValue.isZero, false);
      expect(Int32.zero.isZero, true);
      expect(Int32.maxValue.isZero, false);
    });
    test('bitLength', () {
      expect(Int32(-2).bitLength, 1);
      expect((-Int32.one).bitLength, 0);
      expect(Int32.zero.bitLength, 0);
      expect(Int32.one.bitLength, 1);
      expect(Int32(2).bitLength, 2);
      expect(Int32.maxValue.bitLength, 31);
      expect(Int32.minValue.bitLength, 31);
    });
  });

  group('arithmetic operators', () {
    var n1 = Int32(1234);
    var n2 = Int32(9876);
    var n3 = Int32(-1234);
    var n4 = Int32(-9876);

    test('+', () {
      expect(n1 + n2, Int32(11110));
      expect(n3 + n2, Int32(8642));
      expect(n3 + n4, Int32(-11110));
      expect(n3 + Int64(1), Int64(-1233));
      expect(Int32.maxValue + 1, Int32.minValue);
    });

    test('-', () {
      expect(n1 - n2, Int32(-8642));
      expect(n3 - n2, Int32(-11110));
      expect(n3 - n4, Int32(8642));
      expect(n3 - Int64(1), Int64(-1235));
      expect(Int32.minValue - 1, Int32.maxValue);
    });

    test('unary -', () {
      expect(-n1, Int32(-1234));
      expect(-Int32.zero, Int32.zero);
    });

    test('*', () {
      expect(n1 * n2, Int32(12186984));
      expect(n2 * n3, Int32(-12186984));
      expect(n3 * n3, Int32(1522756));
      expect(n3 * n2, Int32(-12186984));
      expect(Int32(0x12345678) * Int32(0x22222222), Int32(-899716112));
      expect((Int32(123456789) * Int32(987654321)), Int32(-67153019));
      expect(Int32(0x12345678) * Int64(0x22222222),
          Int64.fromInts(0x026D60DC, 0xCA5F6BF0));
      expect((Int32(123456789) * 987654321), Int32(-67153019));
    });

    test('~/', () {
      expect(Int32(829893893) ~/ Int32(1919), Int32(432461));
      expect(Int32(0x12345678) ~/ Int32(0x22), Int32(0x12345678 ~/ 0x22));
      expect(Int32(829893893) ~/ Int64(1919), Int32(432461));
      expect(Int32(0x12345678) ~/ Int64(0x22), Int32(0x12345678 ~/ 0x22));
      expect(Int32(829893893) ~/ 1919, Int32(432461));
      expect(
          () => Int32(17) ~/ Int32.zero,
          // with dart2js, `UnsupportedError` is thrown
          // on the VM: IntegerDivisionByZeroException
          throwsA(anyOf(const TypeMatcher<IntegerDivisionByZeroException>(),
              isUnsupportedError)));
    });

    test('%', () {
      expect(Int32(0x12345678) % Int32(0x22), Int32(0x12345678 % 0x22));
      expect(Int32(0x12345678) % Int64(0x22), Int32(0x12345678 % 0x22));
    });

    test('remainder', () {
      expect(Int32(0x12345678).remainder(Int32(0x22)),
          Int32(0x12345678.remainder(0x22)));
      expect(Int32(0x12345678).remainder(Int32(-0x22)),
          Int32(0x12345678.remainder(-0x22)));
      expect(Int32(-0x12345678).remainder(Int32(-0x22)),
          Int32(-0x12345678.remainder(-0x22)));
      expect(Int32(-0x12345678).remainder(Int32(0x22)),
          Int32(-0x12345678.remainder(0x22)));
      expect(Int32(0x12345678).remainder(Int64(0x22)),
          Int32(0x12345678.remainder(0x22)));
    });

    test('abs', () {
      // NOTE: Int32.minValue.abs() is undefined
      expect((Int32.minValue + 1).abs(), Int32.maxValue);
      expect(Int32(-1).abs(), Int32(1));
      expect(Int32(0).abs(), Int32(0));
      expect(Int32(1).abs(), Int32(1));
      expect(Int32.maxValue.abs(), Int32.maxValue);
    });

    test('clamp', () {
      var value = Int32(17);
      expect(value.clamp(20, 30), Int32(20));
      expect(value.clamp(10, 20), Int32(17));
      expect(value.clamp(10, 15), Int32(15));

      expect(value.clamp(Int32(20), Int32(30)), Int32(20));
      expect(value.clamp(Int32(10), Int32(20)), Int32(17));
      expect(value.clamp(Int32(10), Int32(15)), Int32(15));

      expect(value.clamp(Int64(20), Int64(30)), Int32(20));
      expect(value.clamp(Int64(10), Int64(20)), Int32(17));
      expect(value.clamp(Int64(10), Int64(15)), Int32(15));
      expect(value.clamp(Int64.minValue, Int64(30)), Int32(17));
      expect(value.clamp(Int64(10), Int64.maxValue), Int32(17));

      expect(() => value.clamp(30.5, 40.5), throwsArgumentError);
      expect(() => value.clamp(5.5, 10.5), throwsArgumentError);
      expect(() => value.clamp('a', 1), throwsArgumentError);
      expect(() => value.clamp(1, 'b'), throwsArgumentError);
      expect(() => value.clamp('a', 1), throwsArgumentError);
    });
  });

  group('leading/trailing zeros', () {
    test('numberOfLeadingZeros', () {
      expect(Int32(0).numberOfLeadingZeros(), 32);
      expect(Int32(1).numberOfLeadingZeros(), 31);
      expect(Int32(0xffff).numberOfLeadingZeros(), 16);
      expect(Int32(-1).numberOfLeadingZeros(), 0);
    });
    test('numberOfTrailingZeros', () {
      expect(Int32(0).numberOfTrailingZeros(), 32);
      expect(Int32(0x80000000).numberOfTrailingZeros(), 31);
      expect(Int32(1).numberOfTrailingZeros(), 0);
      expect(Int32(0x10000).numberOfTrailingZeros(), 16);
    });
  });

  group('comparison operators', () {
    test('compareTo', () {
      expect(Int32(0).compareTo(-1), 1);
      expect(Int32(0).compareTo(0), 0);
      expect(Int32(0).compareTo(1), -1);
      expect(Int32(0).compareTo(Int32(-1)), 1);
      expect(Int32(0).compareTo(Int32(0)), 0);
      expect(Int32(0).compareTo(Int32(1)), -1);
      expect(Int32(0).compareTo(Int64(-1)), 1);
      expect(Int32(0).compareTo(Int64(0)), 0);
      expect(Int32(0).compareTo(Int64(1)), -1);
    });

    test('<', () {
      expect(Int32(17) < Int32(18), true);
      expect(Int32(17) < Int32(17), false);
      expect(Int32(17) < Int32(16), false);
      expect(Int32(17) < Int64(18), true);
      expect(Int32(17) < Int64(17), false);
      expect(Int32(17) < Int64(16), false);
      expect(Int32.minValue < Int32.maxValue, true);
      expect(Int32.maxValue < Int32.minValue, false);
    });

    test('<=', () {
      expect(Int32(17) <= Int32(18), true);
      expect(Int32(17) <= Int32(17), true);
      expect(Int32(17) <= Int32(16), false);
      expect(Int32(17) <= Int64(18), true);
      expect(Int32(17) <= Int64(17), true);
      expect(Int32(17) <= Int64(16), false);
      expect(Int32.minValue <= Int32.maxValue, true);
      expect(Int32.maxValue <= Int32.minValue, false);
    });

    test('==', () {
      expect(Int32(17), isNot(equals(Int32(18))));
      expect(Int32(17), equals(Int32(17)));
      expect(Int32(17), isNot(equals(Int32(16))));
      expect(Int32(17), isNot(equals(Int64(18))));
      expect(Int32(17), equals(Int64(17)));
      expect(Int32(17), isNot(equals(Int64(16))));
      expect(Int32.minValue, isNot(equals(Int32.maxValue)));
      expect(Int32(17), isNot(equals(18)));
      expect(Int32(17) == 17, isTrue);
      expect(Int32(17), isNot(equals(16)));
      expect(Int32(17), isNot(equals(Object())));
      expect(Int32(17), isNot(equals(null)));
    });

    test('>=', () {
      expect(Int32(17) >= Int32(18), false);
      expect(Int32(17) >= Int32(17), true);
      expect(Int32(17) >= Int32(16), true);
      expect(Int32(17) >= Int64(18), false);
      expect(Int32(17) >= Int64(17), true);
      expect(Int32(17) >= Int64(16), true);
      expect(Int32.minValue >= Int32.maxValue, false);
      expect(Int32.maxValue >= Int32.minValue, true);
    });

    test('>', () {
      expect(Int32(17) > Int32(18), false);
      expect(Int32(17) > Int32(17), false);
      expect(Int32(17) > Int32(16), true);
      expect(Int32(17) > Int64(18), false);
      expect(Int32(17) > Int64(17), false);
      expect(Int32(17) > Int64(16), true);
      expect(Int32.minValue > Int32.maxValue, false);
      expect(Int32.maxValue > Int32.minValue, true);
    });
  });

  group('bitwise operators', () {
    test('&', () {
      expect(Int32(0x12345678) & Int32(0x22222222),
          Int32(0x12345678 & 0x22222222));
      expect(Int32(0x12345678) & Int64(0x22222222),
          Int64(0x12345678 & 0x22222222));
    });

    test('|', () {
      expect(Int32(0x12345678) | Int32(0x22222222),
          Int32(0x12345678 | 0x22222222));
      expect(Int32(0x12345678) | Int64(0x22222222),
          Int64(0x12345678 | 0x22222222));
    });

    test('^', () {
      expect(Int32(0x12345678) ^ Int32(0x22222222),
          Int32(0x12345678 ^ 0x22222222));
      expect(Int32(0x12345678) ^ Int64(0x22222222),
          Int64(0x12345678 ^ 0x22222222));
    });

    test('~', () {
      expect(~(Int32(0x12345678)), Int32(~0x12345678));
      expect(-(Int32(0x12345678)), Int64(-0x12345678));
    });
  });

  group('bitshift operators', () {
    test('<<', () {
      expect(Int32(0x12345678) << 7, Int32(0x12345678 << 7));
      expect(Int32(0x12345678) << 32, Int32.zero);
      expect(Int32(0x12345678) << 33, Int32.zero);
      expect(() => Int32(17) << -1, throwsArgumentError);
    });

    test('>>', () {
      expect(Int32(0x12345678) >> 7, Int32(0x12345678 >> 7));
      expect(Int32(0x12345678) >> 32, Int32.zero);
      expect(Int32(0x12345678) >> 33, Int32.zero);
      expect(Int32(-42) >> 32, Int32(-1));
      expect(Int32(-42) >> 33, Int32(-1));
      expect(() => Int32(17) >> -1, throwsArgumentError);
    });

    test('shiftRightUnsigned', () {
      expect(Int32(0x12345678).shiftRightUnsigned(7), Int32(0x12345678 >> 7));
      expect(Int32(0x12345678).shiftRightUnsigned(32), Int32.zero);
      expect(Int32(0x12345678).shiftRightUnsigned(33), Int32.zero);
      expect(Int32(-42).shiftRightUnsigned(32), Int32.zero);
      expect(Int32(-42).shiftRightUnsigned(33), Int32.zero);
      expect(() => (Int32(17).shiftRightUnsigned(-1)), throwsArgumentError);
    });
  });

  group('conversions', () {
    test('toSigned', () {
      expect(Int32.one.toSigned(2), Int32.one);
      expect(Int32.one.toSigned(1), -Int32.one);
      expect(Int32.maxValue.toSigned(32), Int32.maxValue);
      expect(Int32.minValue.toSigned(32), Int32.minValue);
      expect(Int32.maxValue.toSigned(31), -Int32.one);
      expect(Int32.minValue.toSigned(31), Int32.zero);
      expect(() => Int32.one.toSigned(0), throwsRangeError);
      expect(() => Int32.one.toSigned(33), throwsRangeError);
    });
    test('toUnsigned', () {
      expect(Int32.one.toUnsigned(1), Int32.one);
      expect(Int32.one.toUnsigned(0), Int32.zero);
      expect(Int32.maxValue.toUnsigned(32), Int32.maxValue);
      expect(Int32.minValue.toUnsigned(32), Int32.minValue);
      expect(Int32.maxValue.toUnsigned(31), Int32.maxValue);
      expect(Int32.minValue.toUnsigned(31), Int32.zero);
      expect(() => Int32.one.toUnsigned(-1), throwsRangeError);
      expect(() => Int32.one.toUnsigned(33), throwsRangeError);
    });
    test('toDouble', () {
      expect(Int32(17).toDouble(), same(17.0));
      expect(Int32(-17).toDouble(), same(-17.0));
    });
    test('toInt', () {
      expect(Int32(17).toInt(), 17);
      expect(Int32(-17).toInt(), -17);
    });
    test('toInt32', () {
      expect(Int32(17).toInt32(), Int32(17));
      expect(Int32(-17).toInt32(), Int32(-17));
    });
    test('toInt64', () {
      expect(Int32(17).toInt64(), Int64(17));
      expect(Int32(-17).toInt64(), Int64(-17));
    });
    test('toBytes', () {
      expect(Int32(0).toBytes(), [0, 0, 0, 0]);
      expect(Int32(0x01020304).toBytes(), [4, 3, 2, 1]);
      expect(Int32(0x04030201).toBytes(), [1, 2, 3, 4]);
      expect(Int32(-1).toBytes(), [0xff, 0xff, 0xff, 0xff]);
    });
  });

  group('parse', () {
    test('base 10', () {
      void checkInt(int x) {
        expect(Int32.parseRadix('$x', 10), Int32(x));
      }

      checkInt(0);
      checkInt(1);
      checkInt(1000);
      checkInt(12345678);
      checkInt(2147483647);
      checkInt(2147483648);
      checkInt(4294967295);
      checkInt(4294967296);
      expect(() => Int32.parseRadix('xyzzy', -1), throwsArgumentError);
      expect(() => Int32.parseRadix('plugh', 10), throwsFormatException);
    });

    test('parseRadix', () {
      void check(String s, int r, String x) {
        expect(Int32.parseRadix(s, r).toString(), x);
      }

      check('deadbeef', 16, '-559038737');
      check('95', 12, '113');
    });

    test('parseInt', () {
      expect(Int32.parseInt('0'), Int32(0));
      expect(Int32.parseInt('1000'), Int32(1000));
      expect(Int32.parseInt('4294967296'), Int32(4294967296));
    });

    test('parseHex', () {
      expect(Int32.parseHex('deadbeef'), Int32(0xdeadbeef));
      expect(Int32.parseHex('cafebabe'), Int32(0xcafebabe));
      expect(Int32.parseHex('8badf00d'), Int32(0x8badf00d));
    });
  });

  group('string representation', () {
    test('toString', () {
      expect(Int32(0).toString(), '0');
      expect(Int32(1).toString(), '1');
      expect(Int32(-1).toString(), '-1');
      expect(Int32(1000).toString(), '1000');
      expect(Int32(-1000).toString(), '-1000');
      expect(Int32(123456789).toString(), '123456789');
      expect(Int32(2147483647).toString(), '2147483647');
      expect(Int32(2147483648).toString(), '-2147483648');
      expect(Int32(2147483649).toString(), '-2147483647');
      expect(Int32(2147483650).toString(), '-2147483646');
      expect(Int32(-2147483648).toString(), '-2147483648');
      expect(Int32(-2147483649).toString(), '2147483647');
      expect(Int32(-2147483650).toString(), '2147483646');
    });
  });

  group('toHexString', () {
    test('returns hexadecimal string representation', () {
      expect(Int32(-1).toHexString(), '-1');
      expect((Int32(-1) >> 8).toHexString(), '-1');
      expect((Int32(-1) << 8).toHexString(), '-100');
      expect(Int32(123456789).toHexString(), '75bcd15');
      expect(Int32(-1).shiftRightUnsigned(8).toHexString(), 'ffffff');
    });
  });

  group('toRadixString', () {
    test('returns base n string representation', () {
      expect(Int32(123456789).toRadixString(5), '223101104124');
    });
  });
}
