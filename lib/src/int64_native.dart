// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: constant_identifier_names

// Many locals are declared as `int` or `double`. We keep local variable types
// because the types are critical to the efficiency of many operations.
//
// ignore_for_file: omit_local_variable_types

import 'dart:typed_data';

import 'int32.dart';
import 'intx.dart';
import 'utilities.dart' as u;

/// An immutable 64-bit signed integer, in the range [-2^63, 2^63 - 1].
///
/// Arithmetic operations may overflow in order to maintain this range.
class Int64 implements IntX {
  /// The 64-bit value.
  final int _value;

  // Minimal 64-bit value, -2^63.
  static const int _minValue = -9223372036854775808;
  // Maximal 64-bit value, 2^63 - 1.
  static const int _maxValue = 9223372036854775807;

  /// The maximum positive value attainable by an [Int64], namely
  /// 9,223,372,036,854,775,807.
  static const Int64 MAX_VALUE = Int64._(_maxValue);

  /// The minimum positive value attainable by an [Int64], namely
  /// -9,223,372,036,854,775,808.
  static const Int64 MIN_VALUE = Int64._(_minValue);

  /// An [Int64] constant equal to 0.
  static const Int64 ZERO = Int64._(0);

  /// An [Int64] constant equal to 1.
  static const Int64 ONE = Int64._(1);

  /// An [Int64] constant equal to 2.
  static const Int64 TWO = Int64._(2);

  /// Constructs an [Int64] with a given value.
  const Int64._(this._value);

  /// Parses [source] in a given [radix] between 2 and 36.
  ///
  /// Returns an [Int64] with the numerical value of [source].
  /// If the numerical value of [source] does not fit
  /// in a signed 64 bit integer,
  /// the numerical value is truncated to the lowest 64 bits
  /// of the value's binary representation,
  /// interpreted as a 64-bit two's complement integer.
  ///
  /// The [source] string must contain a sequence of base-[radix]
  /// digits (using letters from `a` to `z` as digits with values 10 through
  /// 25 for radixes above 10), possibly prefixed by a `-` sign.
  ///
  /// Throws a [FormatException] if the input is not recognized as a valid
  /// integer numeral.
  static Int64 parseRadix(String source, int radix) =>
      Int64._(_parse(source, u.validateRadix(radix), true)!);

  /// Parses [source] in a given [radix] between 2 and 36.
  ///
  /// Returns an [Int64] with the numerical value of [source].
  /// If the numerical value of [source] does not fit
  /// in a signed 64 bit integer,
  /// the numerical value is truncated to the lowest 64 bits
  /// of the value's binary representation,
  /// interpreted as a 64-bit two's complement integer.
  ///
  /// The [source] string must contain a sequence of base-[radix]
  /// digits (using letters from `a` to `z` as digits with values 10 through
  /// 25 for radixes above 10), possibly prefixed by a `-` sign.
  ///
  /// Returns `null` if the input is not recognized as a valid
  /// integer numeral.
  static Int64? tryParseRadix(String source, int radix) {
    var value = _parse(source, u.validateRadix(radix), false);
    return value == null ? null : Int64._(value);
  }

  /// Parses [source] as a decimal numeral.
  ///
  /// Returns an [Int64] with the numerical value of [source].
  /// If the numerical value of [source] does not fit
  /// in a signed 64 bit integer,
  /// the numerical value is truncated to the lowest 64 bits
  /// of the value's binary representation,
  /// interpreted as a 64-bit two's complement integer.
  ///
  /// The [source] string must contain a sequence of digits (`0`-`9`),
  /// possibly prefixed by a `-` sign.
  ///
  /// Throws a [FormatException] if the input is not a valid
  /// decimal integer numeral.
  static Int64 parseInt(String source) => Int64._(_parse(source, 10, true)!);

  /// Parses [source] as a decimal numeral.
  ///
  /// Returns an [Int64] with the numerical value of [source].
  /// If the numerical value of [source] does not fit
  /// in a signed 64 bit integer,
  /// the numerical value is truncated to the lowest 64 bits
  /// of the value's binary representation,
  /// interpreted as a 64-bit two's complement integer.
  ///
  /// The [source] string must contain a sequence of digits (`0`-`9`),
  /// possibly prefixed by a `-` sign.
  ///
  /// Returns `null` if the input is not a valid
  /// decimal integer numeral.
  static Int64? tryParseInt(String source) {
    var value = _parse(source, 10, false);
    return value == null ? null : Int64._(value);
  }

  /// Parses [source] as a hexadecimal numeral.
  ///
  /// Returns an [Int64] with the numerical value of [source].
  /// If the numerical value of [source] does not fit
  /// in a signed 64 bit integer,
  /// the numerical value is truncated to the lowest 64 bits
  /// of the value's binary representation,
  /// interpreted as a 64-bit two's complement integer.
  ///
  /// The [source] string must contain a sequence of hexadecimal
  /// digits (`0`-`9`, `a`-`f` or `A`-`F`), possibly prefixed by a `-` sign.
  ///
  /// Throws a [FormatException] if the input is not a valid
  /// hexadecimal integer numeral.
  static Int64 parseHex(String source) => Int64._(_parse(source, 16, true)!);

  /// Parses [source] as a hexadecimal numeral.
  ///
  /// Returns an [Int64] with the numerical value of [source].
  /// If the numerical value of [source] does not fit
  /// in a signed 64 bit integer,
  /// the numerical value is truncated to the lowest 64 bits
  /// of the value's binary representation,
  /// interpreted as a 64-bit two's complement integer.
  ///
  /// The [source] string must contain a sequence of hexadecimal
  /// digits (`0`-`9`, `a`-`f` or `A`-`F`), possibly prefixed by a `-` sign.
  ///
  /// Returns `null` if the input is not a valid
  /// hexadecimal integer numeral.
  static Int64? tryParseHex(String source) {
    var value = _parse(source, 16, false);
    return value == null ? null : Int64._(value);
  }

  /// Parses [source] as a base [radix] number.
  ///
  /// Unlike `int.parse`, it allows over-long numerals, and truncates
  /// the result.
  static int? _parse(String source, int radix, bool throwOnError) {
    // Try using `int.parse` first. If it works, we're set.
    var fastResult = int.tryParse(source, radix: radix);
    if (fastResult != null) return fastResult;
    // If not, the input is either invalid, or too long for `int.parse`,
    // and we need to truncate the value.
    var negative = false;
    var index = 0;
    if (source.startsWith('-')) {
      negative = true;
      index = 1;
    }
    if (index == source.length) {
      if (throwOnError) {
        throw FormatException("No digits", source, index);
      }
      return null;
    }
    var result = 0;
    while (index < source.length) {
      var char = source.codeUnitAt(index);
      var digit = u.decodeDigit(char);
      if (digit < radix) {
        result = result * radix + digit;
        index++;
      } else {
        if (throwOnError) {
          throw FormatException("Not a radix $radix digit", source, index);
        }
        return null;
      }
    }
    return negative ? -result : result;
  }

  //
  // Public constructors
  //

  /// Constructs an [Int64] with a given [int] value; zero by default.
  factory Int64([int value = 0]) => Int64._(value);

  factory Int64.fromBytes(List<int> bytes) {
    var result = 0;
    for (var i = 7; i >= 0; i--) {
      result = (result << 8) | (bytes[i] & 0xFF);
    }
    return Int64._(result);
  }

  factory Int64.fromBytesBigEndian(List<int> bytes) {
    var result = 0;
    for (var i = 0; i < 8; i++) {
      result = (result << 8) | (bytes[i] & 0xFF);
    }
    return Int64._(result);
  }

  /// Constructs an [Int64] from a pair of 32-bit integers having the value
  /// [:((top & 0xffffffff) << 32) | (bottom & 0xffffffff):].
  factory Int64.fromInts(int top, int bottom) => Int64._(top << 32 | bottom);

  // Returns the [Int64] representation of the specified value. Throws
  // [ArgumentError] for non-integer arguments.
  static int _promote(value) {
    if (value is Int64) {
      return value._value;
    } else if (value is int) {
      return value;
    } else if (value is Int32) {
      return value.toInt();
    }
    throw ArgumentError.value(value, 'other', 'not an int, Int32 or Int64');
  }

  @override
  Int64 operator +(Object other) {
    int o = _promote(other);
    return Int64._(_value + o);
  }

  @override
  Int64 operator -(Object other) {
    int o = _promote(other);
    return Int64._(_value - o);
  }

  @override
  Int64 operator -() => Int64._(-_value);

  @override
  Int64 operator *(Object other) {
    int o = _promote(other);
    return Int64._(_value * o);
  }

  @override
  Int64 operator %(Object other) {
    int o = _promote(other);
    return Int64._(_value % o);
  }

  @override
  Int64 operator ~/(Object other) {
    int o = _promote(other);
    return Int64._(_value ~/ o);
  }

  @override
  Int64 remainder(Object other) {
    int o = _promote(other);
    return Int64._(_value.remainder(o));
  }

  @override
  Int64 operator &(Object other) {
    int o = _promote(other);
    return Int64._(_value & o);
  }

  @override
  Int64 operator |(Object other) {
    int o = _promote(other);
    return Int64._(_value | o);
  }

  @override
  Int64 operator ^(Object other) {
    int o = _promote(other);
    return Int64._(_value ^ o);
  }

  @override
  Int64 operator ~() => Int64._(~_value);

  @override
  Int64 operator <<(int n) => Int64._(_value << n);

  @override
  Int64 operator >>(int n) => Int64._(_value >> n);

  @override
  Int64 shiftRightUnsigned(int n) => Int64._(_value >>> n);

  /// Returns [:true:] if this [Int64] has the same numeric value as the
  /// given object.  The argument may be an [int] or an [IntX].
  @override
  bool operator ==(Object other) {
    if (other is Int64) {
      return _value == other._value;
    } else if (other is int) {
      return _value == other;
    } else if (other is Int32) {
      return _value == other.toInt();
    }
    return false;
  }

  @override
  int compareTo(Object other) => _value.compareTo(_promote(other));

  @override
  bool operator <(Object other) => _value < _promote(other);

  @override
  bool operator <=(Object other) => _value <= _promote(other);

  @override
  bool operator >(Object other) => _value > _promote(other);

  @override
  bool operator >=(Object other) => _value >= _promote(other);

  @override
  bool get isEven => _value.isEven;

  @override
  bool get isMaxValue => _value == _maxValue;

  @override
  bool get isMinValue => _value == _minValue;

  @override
  bool get isNegative => _value < 0;

  @override
  bool get isOdd => _value.isOdd;

  @override
  bool get isZero => _value == 0;

  @override
  int get bitLength => _value.bitLength;

  /// Returns a hash code based on all the bits of this [Int64].
  @override
  int get hashCode => _value.hashCode;

  @override
  Int64 abs() => _value < 0 ? Int64._(-_value) : this;

  @override
  Int64 clamp(Object lowerLimit, Object upperLimit) {
    if (lowerLimit is Int64) {
      if (_value < lowerLimit._value) return lowerLimit;
    } else {
      int lower = _promote(lowerLimit);
      if (_value < lower) return Int64._(lower);
    }
    if (upperLimit is Int64) {
      if (_value > upperLimit._value) return upperLimit;
    } else {
      int upper = _promote(upperLimit);
      if (_value > upper) return Int64._(upper);
    }
    return this;
  }

  /// Returns the number of leading zeros in this [Int64] as an [int]
  /// between 0 and 64.
  @override
  int numberOfLeadingZeros() => _value < 0 ? 0 : 64 - _value.bitLength;

  /// Returns the number of trailing zeros in this [Int64] as an [int]
  /// between 0 and 64.
  @override
  int numberOfTrailingZeros() {
    var value = _value;
    if (value == 0) return 64;
    // Set every bit up to and including the lowest set bit, clear the rest.
    value ^= value - 1;
    // Count of bits is number of trailing zeros plus one.
    if (value >= 0 && value < 0x100000000) {
      // u.bitCount only works up to 32-bit values.
      return u.bitCount(value) - 1;
    }
    return 31 + u.bitCount(value >>> 32);
  }

  @override
  Int64 toSigned(int width) {
    if (width < 1 || width > 64) throw RangeError.range(width, 1, 64);
    return Int64._(_value.toSigned(width));
  }

  @override
  Int64 toUnsigned(int width) {
    if (width < 0 || width > 64) throw RangeError.range(width, 0, 64);
    return Int64._(_value.toUnsigned(width));
  }

  @override
  List<int> toBytes() {
    var result = List<int>.filled(8, 0);
    var value = _value;
    for (var i = 0; i < 8 && value != 0; i++) {
      result[i] = value & 0xFF;
      value >>= 8;
    }
    return result;
  }

  @override
  double toDouble() => _value.toDouble();

  @override
  int toInt() => _value;

  /// Returns an [Int32] containing the low 32 bits of this [Int64].
  @override
  Int32 toInt32() => Int32(_value & 0xFFFFFFFF);

  /// Returns `this`.
  @override
  Int64 toInt64() => this;

  /// Returns the value of this [Int64] as a decimal [String].
  @override
  String toString() => _value.toString();

  @override
  String toHexString() {
    if (_value >= 0) return _value.toRadixString(16).toUpperCase();
    return _toRadixStringUnsignedPow2(16, _value);
  }

  /// Returns the digits of `this` when interpreted as an unsigned 64-bit value.
  String toStringUnsigned() {
    if (_value >= 0) return _value.toString();
    return _toRadixStringUnsigned(10, _value);
  }

  String toRadixStringUnsigned(int radix) {
    if (_value >= 0) {
      var result = _value.toRadixString(radix);
      if (radix > 10) result = result.toUpperCase();
      return result;
    }
    return _toRadixStringUnsigned(u.validateRadix(radix), _value);
  }

  @override
  String toRadixString(int radix) =>
      _value.toRadixString(u.validateRadix(radix));

  // Reusable buffer.
  static final Uint8List _buffer = Uint8List(64);

  static String _toRadixStringUnsignedPow2(int radix, int value) {
    var buffer = _buffer;
    assert(value < 0);
    var bits = u.bitCount(radix - 1);
    var mask = radix - 1;
    var index = 64;
    while (value != 0) {
      buffer[--index] = u.radixDigits.codeUnitAt(value & mask);
      value >>>= bits;
    }
    return String.fromCharCodes(Uint8List.sublistView(buffer, index));
  }

  static String _toRadixStringUnsigned(int radix, int value) {
    if (u.isPowerOf2(radix)) {
      // 16 is likely to be the most common radix for unsigned,
      // so use a faster approach, which works for all powers of 2.
      return _toRadixStringUnsignedPow2(radix, value);
    }
    // Consider adding a special case for radix 10, if it's commonly used.

    assert(value < 0);
    // Remove sign bit, since it affects numerical value.
    // Correct for missing 2^63 after first division.
    value &= 0x7FFFFFFFFFFFFFFF;

    var buffer = _buffer;
    var index = 64;

    var digit = value.remainder(radix);
    value ~/= radix;
    // Correct for missing 2^63.
    // Table is (2^63 ~/ radix, 2^63 % radix) pairs, starting from radix 3.
    value += _toUnsignedTable[radix * 2 - 6];
    digit += _toUnsignedTable[radix * 2 - 5];
    if (digit >= radix) {
      digit -= radix;
      value += 1;
    }
    buffer[--index] = u.radixDigits.codeUnitAt(digit);

    do {
      var digit = value.remainder(radix);
      value ~/= radix;
      buffer[--index] = u.radixDigits.codeUnitAt(digit);
    } while (value != 0);

    return String.fromCharCodes(Uint8List.sublistView(buffer, index));
  }

  /// Table of 2^63 ~/ radix and 2^63 % radix for radix 3-36.
  ///
  /// Omits powers of two, since they use a simpler algorthm.
  static const List<int> _toUnsignedTable = [
    3074457345618258602, 2, // 3
    0, 0, // 4
    1844674407370955161, 3, // 5
    1537228672809129301, 2, // 6
    1317624576693539401, 1, // 7
    0, 0, // 8
    1024819115206086200, 8, // 9
    922337203685477580, 8, // 10
    838488366986797800, 8, // 11
    768614336404564650, 8, // 12
    709490156681136600, 8, // 13
    658812288346769700, 8, // 14
    614891469123651720, 8, // 15
    0, 0, // 16
    542551296285575047, 9, // 17
    512409557603043100, 8, // 18
    485440633518672410, 18, // 19
    461168601842738790, 8, // 20
    439208192231179800, 8, // 21
    419244183493398900, 8, // 22
    401016175515425035, 3, // 23
    384307168202282325, 8, // 24
    368934881474191032, 8, // 25
    354745078340568300, 8, // 26
    341606371735362066, 26, // 27
    329406144173384850, 8, // 28
    318047311615681924, 12, // 29
    307445734561825860, 8, // 30
    297528130221121800, 8, // 31
    0, 0, // 32
    279496122328932600, 8, // 33
    271275648142787523, 26, // 34
    263524915338707880, 8, // 35
    256204778801521550, 8, // 36
  ];

  String toDebugString() => 'Int64[$_value]';
}
