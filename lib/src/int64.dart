// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: constant_identifier_names

// `dart:html` is only available on dart2js (dart2wasm won't support it), so we
// can check availability of it to test whether we're compiling to JS. Other
// targets (AOT, JIT, Wasm) support 64-bit `int`s.
import 'int64_native.dart' if (dart.library.html) 'int64_emulated.dart';
import 'intx.dart';
import 'utilities.dart' as u;

/// An immutable 64-bit signed integer, in the range `[-2^63, 2^63 - 1]`.
/// Arithmetic operations may overflow in order to maintain this range.
abstract class Int64 implements IntX {
  /// The maximum positive value attainable by an [Int64], namely
  /// 9,223,372,036,854,775,807.
  static const Int64 MAX_VALUE = Int64Impl.MAX_VALUE;

  /// The minimum positive value attainable by an [Int64], namely
  /// -9,223,372,036,854,775,808.
  static const Int64 MIN_VALUE = Int64Impl.MIN_VALUE;

  /// An [Int64] constant equal to 0.
  static const Int64 ZERO = Int64Impl.ZERO;

  /// An [Int64] constant equal to 1.
  static const Int64 ONE = Int64Impl.ONE;

  /// An [Int64] constant equal to 2.
  static const Int64 TWO = Int64Impl.TWO;

  factory Int64([int value = 0]) => Int64Impl(value);

  /// Constructs an [Int64] from a pair of 32-bit integers having the value
  /// [:((high & 0xffffffff) << 32) | (low & 0xffffffff):].
  factory Int64.fromInts(int high, int low) => Int64Impl.fromInts(high, low);

  factory Int64.fromBytes(List<int> bytes) => Int64Impl.fromBytes(bytes);

  factory Int64.fromBytesBigEndian(List<int> bytes) =>
      Int64Impl.fromBytesBigEndian(bytes);

  /// Parses [source] as a decimal numeral.
  ///
  /// Returns an [Int64] with the numerical value of [source]. If the numerical
  /// value of [source] does not fit in a signed 64 bit integer, the numerical
  /// value is truncated to the lowest 64 bits of the value's binary
  /// representation, interpreted as a 64-bit two's complement integer.
  ///
  /// The [source] string must contain a sequence of digits (`0`-`9`), possibly
  /// prefixed by a `-` sign.
  ///
  /// Throws a [FormatException] if the input is not a valid decimal integer
  /// numeral.
  static Int64 parseInt(String source) =>
      Int64Impl.parseRadix(source, 10, true)!;

  /// Parses [source] as a decimal numeral.
  ///
  /// Returns an [Int64] with the numerical value of [source]. If the numerical
  /// value of [source] does not fit in a signed 64 bit integer, the numerical
  /// value is truncated to the lowest 64 bits of the value's binary
  /// representation, interpreted as a 64-bit two's complement integer.
  ///
  /// The [source] string must contain a sequence of digits (`0`-`9`), possibly
  /// prefixed by a `-` sign.
  ///
  /// Returns `null` if the input is not a valid decimal integer numeral.
  static Int64? tryParseInt(String source) =>
      Int64Impl.parseRadix(source, 10, false);

  /// Parses [source] in a given [radix] between 2 and 36.
  ///
  /// Returns an [Int64] with the numerical value of [source]. If the numerical
  /// value of [source] does not fit in a signed 64 bit integer, the numerical
  /// value is truncated to the lowest 64 bits of the value's binary
  /// representation, interpreted as a 64-bit two's complement integer.
  ///
  /// The [source] string must contain a sequence of base-[radix] digits (using
  /// letters from `a` to `z` as digits with values 10 through 25 for radixes
  /// above 10), possibly prefixed by a `-` sign.
  ///
  /// Throws a [FormatException] if the input is not recognized as a valid
  /// integer numeral.
  static Int64 parseRadix(String source, int radix) =>
      Int64Impl.parseRadix(source, u.validateRadix(radix), true)!;

  /// Parses [source] in a given [radix] between 2 and 36.
  ///
  /// Returns an [Int64] with the numerical value of [source]. If the numerical
  /// value of [source] does not fit in a signed 64 bit integer, the numerical
  /// value is truncated to the lowest 64 bits of the value's binary
  /// representation, interpreted as a 64-bit two's complement integer.
  ///
  /// The [source] string must contain a sequence of base-[radix] digits (using
  /// letters from `a` to `z` as digits with values 10 through 25 for radixes
  /// above 10), possibly prefixed by a `-` sign.
  ///
  /// Returns `null` if the input is not recognized as a valid integer numeral.
  static Int64? tryParseRadix(String source, int radix) =>
      Int64Impl.parseRadix(source, u.validateRadix(radix), false);

  /// Parses [source] as a hexadecimal numeral.
  ///
  /// Returns an [Int64] with the numerical value of [source]. If the numerical
  /// value of [source] does not fit in a signed 64 bit integer, the numerical
  /// value is truncated to the lowest 64 bits of the value's binary
  /// representation, interpreted as a 64-bit two's complement integer.
  ///
  /// The [source] string must contain a sequence of hexadecimal digits
  /// (`0`-`9`, `a`-`f` or `A`-`F`), possibly prefixed by a `-` sign.
  ///
  /// Throws a [FormatException] if the input is not a valid hexadecimal
  /// integer numeral.
  static Int64 parseHex(String source) =>
      Int64Impl.parseRadix(source, 16, true)!;

  /// Parses [source] as a hexadecimal numeral.
  ///
  /// Returns an [Int64] with the numerical value of [source]. If the numerical
  /// value of [source] does not fit in a signed 64 bit integer, the numerical
  /// value is truncated to the lowest 64 bits of the value's binary
  /// representation, interpreted as a 64-bit two's complement integer.
  ///
  /// The [source] string must contain a sequence of hexadecimal digits
  /// (`0`-`9`, `a`-`f` or `A`-`F`), possibly prefixed by a `-` sign.
  ///
  /// Returns `null` if the input is not a valid hexadecimal integer numeral.
  static Int64? tryParseHex(String source) =>
      Int64Impl.parseRadix(source, 16, false);

  String toRadixStringUnsigned(int radix);

  /// Returns the digits of `this` when interpreted as an unsigned 64-bit value.
  String toStringUnsigned();

  @override
  Int64 operator +(Object other);

  @override
  Int64 operator -(Object other);

  @override
  Int64 operator -();

  @override
  Int64 operator *(Object other);

  @override
  Int64 operator %(Object other);

  @override
  Int64 operator ~/(Object other);

  @override
  Int64 remainder(Object other);

  @override
  Int64 operator &(Object other);

  @override
  Int64 operator |(Object other);

  @override
  Int64 operator ^(Object other);

  @override
  Int64 operator ~();

  @override
  Int64 operator <<(int shiftAmount);

  @override
  Int64 operator >>(int shiftAmount);

  @override
  Int64 shiftRightUnsigned(int shiftAmount);

  @override
  Int64 abs();

  @override
  Int64 clamp(Object lowerLimit, Object upperLimit);

  @override
  Int64 toSigned(int width);
}
