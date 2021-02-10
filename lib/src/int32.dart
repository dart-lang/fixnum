// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of fixnum;

/// An immutable 32-bit signed integer, in the range [-2^31, 2^31 - 1].
/// Arithmetic operations may overflow in order to maintain this range.
class Int32 implements IntX {
  /// The maximum positive value attainable by an [Int32], namely
  /// 2147483647.
  @Deprecated('Use [maxValue] instead.')
  // ignore: constant_identifier_names
  static const Int32 MAX_VALUE = maxValue;

  /// The maximum positive value attainable by an [Int32], namely
  /// 2147483647.
  static const Int32 maxValue = Int32._internal(0x7FFFFFFF);

  /// The minimum positive value attainable by an [Int32], namely
  /// -2147483648.
  @Deprecated('Use [minValue] instead.')
  // ignore: constant_identifier_names
  static const Int32 MIN_VALUE = minValue;

  /// The minimum positive value attainable by an [Int32], namely
  /// -2147483648.
  static const Int32 minValue = Int32._internal(-0x80000000);

  /// An [Int32] constant equal to 0.
  @Deprecated('Use [zero] instead.')
  // ignore: constant_identifier_names
  static const Int32 ZERO = zero;

  /// An [Int32] constant equal to 0.
  static const Int32 zero = Int32._internal(0);

  /// An [Int32] constant equal to 1.
  @Deprecated('Use [one] instead.')
  // ignore: constant_identifier_names
  static const Int32 ONE = one;

  /// An [Int32] constant equal to 1.
  static const Int32 one = Int32._internal(1);

  /// An [Int32] constant equal to 2.
  @Deprecated('Use [two] instead.')
  // ignore: constant_identifier_names
  static const Int32 TWO = Int32._internal(2);

  /// An [Int32] constant equal to 2.
  static const Int32 two = Int32._internal(2);

  // Hex digit char codes
  static const int _charCode0 = 48; // '0'.codeUnitAt(0)
  static const int _charCode9 = 57; // '9'.codeUnitAt(0)
  static const int _charCodeLowercaseA = 97; // 'a'.codeUnitAt(0)
  static const int _charCodeLowercaseZ = 122; // 'z'.codeUnitAt(0)
  static const int _charCodeUppercaseA = 65; // 'A'.codeUnitAt(0)
  static const int _charCodeUppercaseZ = 90; // 'Z'.codeUnitAt(0)

  static int _decodeDigit(int charCode) {
    if (charCode >= _charCode0 && charCode <= _charCode9) {
      return charCode - _charCode0;
    } else if (charCode >= _charCodeLowercaseA &&
        charCode <= _charCodeLowercaseZ) {
      return charCode - _charCodeLowercaseA + 10;
    } else if (charCode >= _charCodeUppercaseA &&
        charCode <= _charCodeUppercaseZ) {
      return charCode - _charCodeUppercaseA + 10;
    } else {
      return -1; // bad char code
    }
  }

  static int _validateRadix(int radix) {
    if (2 <= radix && radix <= 36) return radix;
    throw RangeError.range(radix, 2, 36, 'radix');
  }

  /// Parses a [String] in a given [radix] between 2 and 16 and returns an
  /// [Int32].
  // TODO(rice) - Make this faster by converting several digits at once.
  static Int32 parseRadix(String string, int radix) {
    _validateRadix(radix);
    var parsedRadix = zero;
    for (var i = 0; i < string.length; i++) {
      var charCode = string.codeUnitAt(i);
      var digit = _decodeDigit(charCode);
      if (digit < 0 || digit >= radix) {
        throw FormatException('Non-radix code unit: $charCode');
      }
      parsedRadix = ((parsedRadix * radix) + digit) as Int32;
    }
    return parsedRadix;
  }

  /// Parses a decimal [String] and returns an [Int32].
  static Int32 parseInt(String string) => Int32(int.parse(string));

  /// Parses a hexadecimal [String] and returns an [Int32].
  static Int32 parseHex(String string) => parseRadix(string, 16);

  // Assumes i is <= 32-bit.
  static int _bitCount(int integer) {
    // See "Hacker's Delight", section 5-1, "Counting 1-Bits".

    // The basic strategy is to use "divide and conquer" to
    // add pairs (then quads, etc.) of bits together to obtain
    // sub-counts.
    //
    // A straightforward approach would look like:
    //
    // i = (i & 0x55555555) + ((i >>  1) & 0x55555555);
    // i = (i & 0x33333333) + ((i >>  2) & 0x33333333);
    // i = (i & 0x0F0F0F0F) + ((i >>  4) & 0x0F0F0F0F);
    // i = (i & 0x00FF00FF) + ((i >>  8) & 0x00FF00FF);
    // i = (i & 0x0000FFFF) + ((i >> 16) & 0x0000FFFF);
    //
    // The code below removes unnecessary &'s and uses a
    // trick to remove one instruction in the first line.

    integer -= ((integer >> 1) & 0x55555555);
    integer = (integer & 0x33333333) + ((integer >> 2) & 0x33333333);
    integer = ((integer + (integer >> 4)) & 0x0F0F0F0F);
    integer += (integer >> 8);
    integer += (integer >> 16);
    return (integer & 0x0000003F);
  }

  // Assumes i is <= 32-bit
  static int _numberOfLeadingZeros(int integer) {
    integer |= integer >> 1;
    integer |= integer >> 2;
    integer |= integer >> 4;
    integer |= integer >> 8;
    integer |= integer >> 16;
    return _bitCount(~integer);
  }

  static int _numberOfTrailingZeros(int integer) =>
      _bitCount((integer & -integer) - 1);

  // The internal value, kept in the range [MIN_VALUE, MAX_VALUE].
  final int _integer;

  const Int32._internal(int integer) : _integer = integer;

  /// Constructs an [Int32] from an [int].  Only the low 32 bits of the input
  /// are used.
  Int32([int integer = 0])
      : _integer = (integer & 0x7fffffff) - (integer & 0x80000000);

  // Returns the [int] representation of the specified value. Throws
  // [ArgumentError] for non-integer arguments.
  int _toInt(Object value) {
    if (value is Int32) {
      return value._integer;
    } else if (value is int) {
      return value;
    }
    throw ArgumentError(value);
  }

  // The +, -, * , &, |, and ^ operaters deal with types as follows:
  //
  // Int32 + int => Int32
  // Int32 + Int32 => Int32
  // Int32 + Int64 => Int64
  //
  // The %, ~/ and remainder operators return an Int32 even with an Int64
  // argument, since the result cannot be greater than the value on the
  // left-hand side:
  //
  // Int32 % int => Int32
  // Int32 % Int32 => Int32
  // Int32 % Int64 => Int32

  @override
  IntX operator +(Object other) {
    if (other is Int64) {
      return toInt64() + other;
    }
    return Int32(_integer + _toInt(other));
  }

  @override
  IntX operator -(Object other) {
    if (other is Int64) {
      return toInt64() - other;
    }
    return Int32(_integer - _toInt(other));
  }

  @override
  Int32 operator -() => Int32(-_integer);

  @override
  IntX operator *(Object other) {
    if (other is Int64) {
      return toInt64() * other;
    }
    // TODO(rice) - optimize
    return (toInt64() * other).toInt32();
  }

  @override
  Int32 operator %(Object other) {
    if (other is Int64) {
      // Result will be Int32
      return (toInt64() % other).toInt32();
    }
    return Int32(_integer % _toInt(other));
  }

  @override
  Int32 operator ~/(Object other) {
    if (other is Int64) {
      return (toInt64() ~/ other).toInt32();
    }
    return Int32(_integer ~/ _toInt(other));
  }

  @override
  Int32 remainder(Object other) {
    if (other is Int64) {
      var t = toInt64();
      return (t - (t ~/ other) * other).toInt32();
    }
    return (this - (this ~/ other) * other) as Int32;
  }

  @override
  Int32 operator &(Object other) {
    if (other is Int64) {
      return (toInt64() & other).toInt32();
    }
    return Int32(_integer & _toInt(other));
  }

  @override
  Int32 operator |(Object other) {
    if (other is Int64) {
      return (toInt64() | other).toInt32();
    }
    return Int32(_integer | _toInt(other));
  }

  @override
  Int32 operator ^(Object other) {
    if (other is Int64) {
      return (toInt64() ^ other).toInt32();
    }
    return Int32(_integer ^ _toInt(other));
  }

  @override
  Int32 operator ~() => Int32(~_integer);

  @override
  Int32 operator <<(int number) {
    if (number < 0) {
      throw ArgumentError(number);
    }
    if (number >= 32) {
      return zero;
    }
    return Int32(_integer << number);
  }

  @override
  Int32 operator >>(int number) {
    if (number < 0) {
      throw ArgumentError(number);
    }
    if (number >= 32) {
      return isNegative ? const Int32._internal(-1) : zero;
    }
    int value;
    if (_integer >= 0) {
      value = _integer >> number;
    } else {
      value = (_integer >> number) | (0xffffffff << (32 - number));
    }
    return Int32(value);
  }

  @override
  Int32 shiftRightUnsigned(int number) {
    if (number < 0) {
      throw ArgumentError(number);
    }
    if (number >= 32) {
      return zero;
    }
    int value;
    if (_integer >= 0) {
      value = _integer >> number;
    } else {
      value = (_integer >> number) & ((1 << (32 - number)) - 1);
    }
    return Int32(value);
  }

  /// Returns [:true:] if this [Int32] has the same numeric value as the
  /// given object.  The argument may be an [int] or an [IntX].
  @override
  bool operator ==(Object other) {
    if (other is Int32) {
      return _integer == other._integer;
    } else if (other is Int64) {
      return toInt64() == other;
    } else if (other is int) {
      return _integer == other;
    }
    return false;
  }

  @override
  int compareTo(Object other) {
    if (other is Int64) {
      return toInt64().compareTo(other);
    }
    return _integer.compareTo(_toInt(other));
  }

  @override
  bool operator <(Object other) {
    if (other is Int64) {
      return toInt64() < other;
    }
    return _integer < _toInt(other);
  }

  @override
  bool operator <=(Object other) {
    if (other is Int64) {
      return toInt64() <= other;
    }
    return _integer <= _toInt(other);
  }

  @override
  bool operator >(Object other) {
    if (other is Int64) {
      return toInt64() > other;
    }
    return _integer > _toInt(other);
  }

  @override
  bool operator >=(Object other) {
    if (other is Int64) {
      return toInt64() >= other;
    }
    return _integer >= _toInt(other);
  }

  @override
  bool get isEven => (_integer & 0x1) == 0;

  @override
  bool get isMaxValue => _integer == 2147483647;

  @override
  bool get isMinValue => _integer == -2147483648;

  @override
  bool get isNegative => _integer < 0;

  @override
  bool get isOdd => (_integer & 0x1) == 1;

  @override
  bool get isZero => _integer == 0;

  @override
  int get bitLength => _integer.bitLength;

  @override
  int get hashCode => _integer;

  @override
  Int32 abs() => _integer < 0 ? Int32(-_integer) : this;

  @override
  Int32 clamp(Object lowerLimit, Object upperLimit) {
    if (this < lowerLimit) {
      if (lowerLimit is IntX) return lowerLimit.toInt32();
      if (lowerLimit is int) return Int32(lowerLimit);
      throw ArgumentError(lowerLimit);
    } else if (this > upperLimit) {
      if (upperLimit is IntX) return upperLimit.toInt32();
      if (upperLimit is int) return Int32(upperLimit);
      throw ArgumentError(upperLimit);
    }
    return this;
  }

  @override
  int numberOfLeadingZeros() => _numberOfLeadingZeros(_integer);

  @override
  int numberOfTrailingZeros() => _numberOfTrailingZeros(_integer);

  @override
  Int32 toSigned(int width) {
    if (width < 1 || width > 32) throw RangeError.range(width, 1, 32);
    return Int32(_integer.toSigned(width));
  }

  @override
  Int32 toUnsigned(int width) {
    if (width < 0 || width > 32) throw RangeError.range(width, 0, 32);
    return Int32(_integer.toUnsigned(width));
  }

  @override
  List<int> toBytes() {
    var result = List<int>.filled(4, 0);
    result[0] = _integer & 0xff;
    result[1] = (_integer >> 8) & 0xff;
    result[2] = (_integer >> 16) & 0xff;
    result[3] = (_integer >> 24) & 0xff;
    return result;
  }

  @override
  double toDouble() => _integer.toDouble();

  @override
  int toInt() => _integer;

  @override
  Int32 toInt32() => this;

  @override
  Int64 toInt64() => Int64(_integer);

  @override
  String toString() => _integer.toString();

  @override
  String toHexString() => _integer.toRadixString(16);

  @override
  String toRadixString(int radix) => _integer.toRadixString(radix);
}
