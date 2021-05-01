// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Many locals are declared as `int` or `double`. We keep local variable types
// because the types are critical to the efficiency of many operations.
//
// ignore_for_file: omit_local_variable_types

part of fixnum;

/// An immutable 64-bit signed integer, in the range [-2^63, 2^63 - 1].
///
/// Arithmetic operations may overflow in order to maintain this range.
class Int64 implements IntX {
  // A 64-bit integer is represented internally as three non-negative integers
  // storing the 22 low, 22 middle, and 20 high bits of the 64-bit value. _low
  // and _middle are in the range [0, 2^22 - 1] and _high is in the range
  // [0, 2^20 - 1].
  //
  // The values being assigned to _low, _middle and _high in initialization are
  // masked to force them into the above ranges.  Sometimes we know that the
  // value is a small non-negative integer but the dart2js compiler can't infer
  // that, so a few of the masking operations are not needed for correctness but
  // are helpful for dart2js code quality.

  final int _low, _middle, _high;

  // Note: several functions require _bitCount == 22 -- do not change this value.
  static const int _lowBitCount = 22;
  static const int _middleBitCount = 22;
  static const int _lowAndMiddleBitCount = _lowBitCount + _middleBitCount; // 44
  static const int _highBitCount = 64 - _lowAndMiddleBitCount; // 20
  static const int _mask = (1 << _lowBitCount) - 1; // 4194303
  static const int _maskHigh = (1 << _highBitCount) - 1; // 1048575
  static const int _signBit = _highBitCount - 1; // 19
  static const int _signBitMask = 1 << _signBit;

  /// The maximum positive value attainable by an [Int64], namely
  /// 9,223,372,036,854,775,807.
  @Deprecated('Use [minValue] instead.')
  // ignore: constant_identifier_names
  static const Int64 MAX_VALUE = maxValue;

  /// The maximum positive value attainable by an [Int64], namely
  /// 9,223,372,036,854,775,807.
  static const Int64 maxValue = Int64._bits(_mask, _mask, _maskHigh >> 1);

  /// The minimum positive value attainable by an [Int64], namely
  /// -9,223,372,036,854,775,808.
  @Deprecated('Use [minValue] instead.')
  // ignore: constant_identifier_names
  static const Int64 MIN_VALUE = minValue;

  /// The minimum positive value attainable by an [Int64], namely
  /// -9,223,372,036,854,775,808.
  static const Int64 minValue = Int64._bits(0, 0, _signBitMask);

  /// An [Int64] constant equal to 0.
  @Deprecated('Use [zero] instead.')
  // ignore: constant_identifier_names
  static const Int64 ZERO = zero;

  /// An [Int64] constant equal to 0.
  static const Int64 zero = Int64._bits(0, 0, 0);

  /// An [Int64] constant equal to 1.
  @Deprecated('Use [one] instead.')
  // ignore: constant_identifier_names
  static const Int64 ONE = one;

  /// An [Int64] constant equal to 1.
  static const Int64 one = Int64._bits(1, 0, 0);

  /// An [Int64] constant equal to 2.
  @Deprecated('Use [two] instead.')
  // ignore: constant_identifier_names
  static const Int64 TWO = two;

  /// An [Int64] constant equal to 2.
  static const Int64 two = Int64._bits(2, 0, 0);

  /// Constructs an [Int64] with a given bitwise representation.  No validation
  /// is performed.
  const Int64._bits(this._low, this._middle, this._high);

  /// Parses a [String] in a given [radix] between 2 and 36 and returns an
  /// [Int64].
  static Int64 parseRadix(String string, int radix) {
    return _parseRadix(string, Int32._validateRadix(radix));
  }

  static Int64 _parseRadix(String string, int radix) {
    int index = 0;
    bool negative = false;
    if (index < string.length && string[0] == '-') {
      negative = true;
      index++;
    }

    // TODO(https://github.com/dart-lang/sdk/issues/38728). Replace with
    // "if (index >= string.length)".
    if (!(index < string.length)) {
      throw FormatException("No digits in '$string'");
    }

    int low = 0, middle = 0, high = 0; //  low, middle, high components.
    for (; index < string.length; index++) {
      int char = string.codeUnitAt(index);
      int digit = Int32._decodeDigit(char);
      if (digit < 0 || digit >= radix) {
        throw FormatException('Non-radix char code: $char');
      }

      // [radix] and [digit] are at most 6 bits, component is 22, so we can
      // multiply and add within 30 bit temporary values.
      low = low * radix + digit;
      int carry = low >> _lowBitCount;
      low = _mask & low;

      middle = middle * radix + carry;
      carry = middle >> _lowBitCount;
      middle = _mask & middle;

      high = high * radix + carry;
      high = _maskHigh & high;
    }

    if (negative) return _negate(low, middle, high);

    return Int64._masked(low, middle, high);
  }

  /// Parses a decimal [String] and returns an [Int64].
  static Int64 parseInt(String string) => _parseRadix(string, 10);

  /// Parses a hexadecimal [String] and returns an [Int64].
  static Int64 parseHex(String string) => _parseRadix(string, 16);

  //
  // Public constructors
  //

  /// Constructs an [Int64] with a given [int] value; zero by default.
  factory Int64([int value = 0]) {
    int valueLow = 0, valueMiddle = 0, valueHigh = 0;
    bool negative = false;
    if (value < 0) {
      negative = true;
      value = -value;
    }
    // Avoid using bitwise operations that in JavaScript coerce their input to
    // 32 bits.
    valueHigh = value ~/ 17592186044416; // 2^44
    value -= valueHigh * 17592186044416;
    valueMiddle = value ~/ 4194304; // 2^22
    value -= valueMiddle * 4194304;
    valueLow = value;

    return negative
        ? Int64._negate(
            _mask & valueLow, _mask & valueMiddle, _maskHigh & valueHigh)
        : Int64._masked(valueLow, valueMiddle, valueHigh);
  }

  factory Int64.fromBytes(List<int> bytes) {
    int top = bytes[7] & 0xff;
    top <<= 8;
    top |= bytes[6] & 0xff;
    top <<= 8;
    top |= bytes[5] & 0xff;
    top <<= 8;
    top |= bytes[4] & 0xff;

    int bottom = bytes[3] & 0xff;
    bottom <<= 8;
    bottom |= bytes[2] & 0xff;
    bottom <<= 8;
    bottom |= bytes[1] & 0xff;
    bottom <<= 8;
    bottom |= bytes[0] & 0xff;

    return Int64.fromInts(top, bottom);
  }

  factory Int64.fromBytesBigEndian(List<int> bytes) {
    int top = bytes[0] & 0xff;
    top <<= 8;
    top |= bytes[1] & 0xff;
    top <<= 8;
    top |= bytes[2] & 0xff;
    top <<= 8;
    top |= bytes[3] & 0xff;

    int bottom = bytes[4] & 0xff;
    bottom <<= 8;
    bottom |= bytes[5] & 0xff;
    bottom <<= 8;
    bottom |= bytes[6] & 0xff;
    bottom <<= 8;
    bottom |= bytes[7] & 0xff;

    return Int64.fromInts(top, bottom);
  }

  /// Constructs an [Int64] from a pair of 32-bit integers having the value
  /// [:((top & 0xffffffff) << 32) | (bottom & 0xffffffff):].
  factory Int64.fromInts(int top, int bottom) {
    top &= 0xffffffff;
    bottom &= 0xffffffff;
    int low = _mask & bottom;
    int middle = ((0xfff & top) << 10) | (0x3ff & (bottom >> _lowBitCount));
    int high = _maskHigh & (top >> 12);
    return Int64._masked(low, middle, high);
  }

  // Returns the [Int64] representation of the specified value. Throws
  // [ArgumentError] for non-integer arguments.
  static Int64 _promote(value) {
    if (value is Int64) {
      return value;
    } else if (value is int) {
      return Int64(value);
    } else if (value is Int32) {
      return value.toInt64();
    }
    throw ArgumentError.value(value);
  }

  @override
  Int64 operator +(Object other) {
    Int64 addend = _promote(other);
    int sumLow = _low + addend._low;
    int sumMiddle = _middle + addend._middle + (sumLow >> _lowBitCount);
    int sumHigh = _high + addend._high + (sumMiddle >> _lowBitCount);
    return Int64._masked(sumLow, sumMiddle, sumHigh);
  }

  @override
  Int64 operator -(Object other) {
    Int64 minuend = _promote(other);
    return _subtract(
        _low, _middle, _high, minuend._low, minuend._middle, minuend._high);
  }

  @override
  Int64 operator -() => _negate(_low, _middle, _high);

  @override
  Int64 operator *(Object other) {
    Int64 multiplicand = _promote(other);

    // Grab 13-bit chunks.
    int lowest = _low & 0x1fff;
    int low = (_low >> 13) | ((_middle & 0xf) << 9);
    int middle = (_middle >> 4) & 0x1fff;
    int high = (_middle >> 17) | ((_high & 0xff) << 5);
    int highest = (_high & 0xfff00) >> 8;

    int operandLowest = multiplicand._low & 0x1fff;
    int operandLow =
        (multiplicand._low >> 13) | ((multiplicand._middle & 0xf) << 9);
    int operandMiddle = (multiplicand._middle >> 4) & 0x1fff;
    int operandHigh =
        (multiplicand._middle >> 17) | ((multiplicand._high & 0xff) << 5);
    int operandHighest = (multiplicand._high & 0xfff00) >> 8;

    // Compute partial products.
    // Optimization: if b is small, avoid multiplying by parts that are 0.
    int partialLowest = lowest * operandLowest; // << 0
    int partialLow = low * operandLowest; // << 13
    int partialMiddle = middle * operandLowest; // << 26
    int partialHigh = high * operandLowest; // << 39
    int partialHighest = highest * operandLowest; // << 52

    if (operandLow != 0) {
      partialLow += lowest * operandLow;
      partialMiddle += low * operandLow;
      partialHigh += middle * operandLow;
      partialHighest += high * operandLow;
    }
    if (operandMiddle != 0) {
      partialMiddle += lowest * operandMiddle;
      partialHigh += low * operandMiddle;
      partialHighest += middle * operandMiddle;
    }
    if (operandHigh != 0) {
      partialHigh += lowest * operandHigh;
      partialHighest += low * operandHigh;
    }
    if (operandHighest != 0) {
      partialHighest += lowest * operandHighest;
    }

    // Accumulate into 22-bit chunks:
    // ........................................cLPH|..................cLPL|
    // |....................|..................xxxx|xxxxxxxxxxxxxxxxxxxxxx| partialLowest
    // |....................|......................|......................|
    // |....................|.................cMPML|.....cMPL.............|
    // |....................|....xxxxxxxxxxxxxxxxxx|xxxxxxxxx.............| partialLow
    // |....................|......................|......................|
    // |................cHPL|.............cMPMH....|......................|
    // |..........xxxxxxxxxx|xxxxxxxxxxxxxxxxxx....|......................| partialMiddle
    // |....................|......................|......................|
    // |................cHPM|.cMPH.................|......................|
    // |xxxxxxxxxxxxxxxxxxxx|xxxxx.................|......................| partialHigh
    // |....................|......................|......................|
    // |........CHPH........|......................|......................|
    // |xxxxxxxxxxxx........|......................|......................| partialHighest

    int cLowPartialLow = partialLowest & 0x3fffff;
    int cLowPartialHigh = (partialLow & 0x1ff) << 13;
    int cLow = cLowPartialLow + cLowPartialHigh;

    int cMiddlePartialLowest = partialLowest >> 22;
    int cMiddlePartialMiddleLow = partialLow >> 9;
    int cMiddlePartialHigh = (partialMiddle & 0x3ffff) << 4;
    int cMiddlePartialHighest = (partialHigh & 0x1f) << 17;
    int cMiddle = cMiddlePartialLowest +
        cMiddlePartialMiddleLow +
        cMiddlePartialHigh +
        cMiddlePartialHighest;

    int cHighPartialLow = partialMiddle >> 18;
    int cHighPartialMiddle = partialHigh >> 5;
    int cHighPartialHigh = (partialHighest & 0xfff) << 8;
    int cHigh = cHighPartialLow + cHighPartialMiddle + cHighPartialHigh;

    // Propagate high bits from c0 -> c1, c1 -> c2.
    cMiddle += cLow >> _lowBitCount;
    cHigh += cMiddle >> _lowBitCount;

    return Int64._masked(cLow, cMiddle, cHigh);
  }

  @override
  Int64 operator %(Object other) =>
      _divide(this, other, _DivisionReturnType.modulo);

  @override
  Int64 operator ~/(Object other) =>
      _divide(this, other, _DivisionReturnType.quotient);

  @override
  Int64 remainder(Object other) =>
      _divide(this, other, _DivisionReturnType.remainder);

  @override
  Int64 operator &(Object other) {
    Int64 operand = _promote(other);
    int low = _low & operand._low;
    int middle = _middle & operand._middle;
    int high = _high & operand._high;
    return Int64._masked(low, middle, high);
  }

  @override
  Int64 operator |(Object other) {
    Int64 operand = _promote(other);
    int low = _low | operand._low;
    int middle = _middle | operand._middle;
    int high = _high | operand._high;
    return Int64._masked(low, middle, high);
  }

  @override
  Int64 operator ^(Object other) {
    Int64 operand = _promote(other);
    int low = _low ^ operand._low;
    int middle = _middle ^ operand._middle;
    int high = _high ^ operand._high;
    return Int64._masked(low, middle, high);
  }

  @override
  Int64 operator ~() {
    return Int64._masked(~_low, ~_middle, ~_high);
  }

  @override
  Int64 operator <<(int number) {
    if (number < 0) {
      throw ArgumentError.value(number);
    }
    if (number >= 64) {
      return zero;
    }

    int resultLow, resultMiddle, resultHigh;
    if (number < _lowBitCount) {
      resultLow = _low << number;
      resultMiddle = (_middle << number) | (_low >> (_lowBitCount - number));
      resultHigh = (_high << number) | (_middle >> (_lowBitCount - number));
    } else if (number < _lowAndMiddleBitCount) {
      resultLow = 0;
      resultMiddle = _low << (number - _lowBitCount);
      resultHigh = (_middle << (number - _lowBitCount)) |
          (_low >> (_lowAndMiddleBitCount - number));
    } else {
      resultLow = 0;
      resultMiddle = 0;
      resultHigh = _low << (number - _lowAndMiddleBitCount);
    }

    return Int64._masked(resultLow, resultMiddle, resultHigh);
  }

  @override
  Int64 operator >>(int number) {
    if (number < 0) {
      throw ArgumentError.value(number);
    }
    if (number >= 64) {
      return isNegative ? const Int64._bits(_mask, _mask, _maskHigh) : zero;
    }

    int resultLow, resultMiddle, resultHigh;

    // Sign extend h(a).
    int aHigh = _high;
    bool negative = (aHigh & _signBitMask) != 0;
    if (negative && _mask > _maskHigh) {
      // Add extra one bits on the left so the sign gets shifted into the wider
      // lower words.
      aHigh += (_mask - _maskHigh);
    }

    if (number < _lowBitCount) {
      resultHigh = _shiftRight(aHigh, number);
      if (negative) {
        resultHigh |= _maskHigh & ~(_maskHigh >> number);
      }
      resultMiddle =
          _shiftRight(_middle, number) | (aHigh << (_lowBitCount - number));
      resultLow =
          _shiftRight(_low, number) | (_middle << (_lowBitCount - number));
    } else if (number < _lowAndMiddleBitCount) {
      resultHigh = negative ? _maskHigh : 0;
      resultMiddle = _shiftRight(aHigh, number - _lowBitCount);
      if (negative) {
        resultMiddle |= _mask & ~(_mask >> (number - _lowBitCount));
      }
      resultLow = _shiftRight(_middle, number - _lowBitCount) |
          (aHigh << (_lowAndMiddleBitCount - number));
    } else {
      resultHigh = negative ? _maskHigh : 0;
      resultMiddle = negative ? _mask : 0;
      resultLow = _shiftRight(aHigh, number - _lowAndMiddleBitCount);
      if (negative) {
        resultLow |= _mask & ~(_mask >> (number - _lowAndMiddleBitCount));
      }
    }

    return Int64._masked(resultLow, resultMiddle, resultHigh);
  }

  @override
  Int64 shiftRightUnsigned(int number) {
    if (number < 0) {
      throw ArgumentError.value(number);
    }
    if (number >= 64) {
      return zero;
    }

    int resultLow, resultMiddle, resultHigh;
    int aHigh = _maskHigh & _high; // Ensure aHigh is positive.
    if (number < _lowBitCount) {
      resultHigh = aHigh >> number;
      resultMiddle = (_middle >> number) | (aHigh << (_lowBitCount - number));
      resultLow = (_low >> number) | (_middle << (_lowBitCount - number));
    } else if (number < _lowAndMiddleBitCount) {
      resultHigh = 0;
      resultMiddle = aHigh >> (number - _lowBitCount);
      resultLow = (_middle >> (number - _lowBitCount)) |
          (_high << (_lowAndMiddleBitCount - number));
    } else {
      resultHigh = 0;
      resultMiddle = 0;
      resultLow = aHigh >> (number - _lowAndMiddleBitCount);
    }

    return Int64._masked(resultLow, resultMiddle, resultHigh);
  }

  /// Returns [:true:] if this [Int64] has the same numeric value as the
  /// given object.  The argument may be an [int] or an [IntX].
  @override
  bool operator ==(Object other) {
    Int64? operand;
    if (other is Int64) {
      operand = other;
    } else if (other is int) {
      if (_high == 0 && _middle == 0) return _low == other;
      // Since we know one of [_h] or [_m] is non-zero, if [other] fits in the
      // low word then it can't be numerically equal.
      if ((_mask & other) == other) return false;
      operand = Int64(other);
    } else if (other is Int32) {
      operand = other.toInt64();
    }
    if (operand != null) {
      return _low == operand._low &&
          _middle == operand._middle &&
          _high == operand._high;
    }
    return false;
  }

  @override
  int compareTo(Object other) => _compareTo(other);

  int _compareTo(Object other) {
    Int64 operand = _promote(other);
    int sign = _high >> (_highBitCount - 1);
    int operandSign = operand._high >> (_highBitCount - 1);
    if (sign != operandSign) {
      return sign == 0 ? 1 : -1;
    }
    if (_high > operand._high) {
      return 1;
    } else if (_high < operand._high) {
      return -1;
    }
    if (_middle > operand._middle) {
      return 1;
    } else if (_middle < operand._middle) {
      return -1;
    }
    if (_low > operand._low) {
      return 1;
    } else if (_low < operand._low) {
      return -1;
    }
    return 0;
  }

  @override
  bool operator <(Object other) => _compareTo(other) < 0;

  @override
  bool operator <=(Object other) => _compareTo(other) <= 0;

  @override
  bool operator >(Object other) => _compareTo(other) > 0;

  @override
  bool operator >=(Object other) => _compareTo(other) >= 0;

  @override
  bool get isEven => (_low & 0x1) == 0;

  @override
  bool get isMaxValue =>
      (_high == _maskHigh >> 1) && _middle == _mask && _low == _mask;

  @override
  bool get isMinValue => _high == _signBitMask && _middle == 0 && _low == 0;

  @override
  bool get isNegative => (_high & _signBitMask) != 0;

  @override
  bool get isOdd => (_low & 0x1) == 1;

  @override
  bool get isZero => _high == 0 && _middle == 0 && _low == 0;

  @override
  int get bitLength {
    if (isZero) return 0;
    int low = _low, middle = _middle, high = _high;
    if (isNegative) {
      low = _mask & ~low;
      middle = _mask & ~middle;
      high = _maskHigh & ~high;
    }
    if (high != 0) return _lowAndMiddleBitCount + high.bitLength;
    if (middle != 0) return _lowBitCount + middle.bitLength;
    return low.bitLength;
  }

  /// Returns a hash code based on all the bits of this [Int64].
  @override
  int get hashCode {
    // TODO(sra): Should we ensure that hashCode values match corresponding int?
    // i.e. should `new Int64(x).hashCode == x.hashCode`?
    int bottom = ((_middle & 0x3ff) << _lowBitCount) | _low;
    int top = (_high << 12) | ((_middle >> 10) & 0xfff);
    return bottom ^ top;
  }

  @override
  Int64 abs() {
    return isNegative ? -this : this;
  }

  @override
  Int64 clamp(Object lowerLimit, Object upperLimit) {
    Int64 lower = _promote(lowerLimit);
    Int64 upper = _promote(upperLimit);
    if (this < lower) return lower;
    if (this > upper) return upper;
    return this;
  }

  /// Returns the number of leading zeros in this [Int64] as an [int]
  /// between 0 and 64.
  @override
  int numberOfLeadingZeros() {
    int high = Int32._numberOfLeadingZeros(_high);
    if (high == 32) {
      int middle = Int32._numberOfLeadingZeros(_middle);
      if (middle == 32) {
        return Int32._numberOfLeadingZeros(_low) + 32;
      } else {
        return middle + _highBitCount - (32 - _lowBitCount);
      }
    } else {
      return high - (32 - _highBitCount);
    }
  }

  /// Returns the number of trailing zeros in this [Int64] as an [int]
  /// between 0 and 64.
  @override
  int numberOfTrailingZeros() {
    int zeros = Int32._numberOfTrailingZeros(_low);
    if (zeros < 32) {
      return zeros;
    }

    zeros = Int32._numberOfTrailingZeros(_middle);
    if (zeros < 32) {
      return _lowBitCount + zeros;
    }

    zeros = Int32._numberOfTrailingZeros(_high);
    if (zeros < 32) {
      return _lowAndMiddleBitCount + zeros;
    }
    // All zeros
    return 64;
  }

  @override
  Int64 toSigned(int width) {
    if (width < 1 || width > 64) throw RangeError.range(width, 1, 64);
    if (width > _lowAndMiddleBitCount) {
      return Int64._masked(
          _low, _middle, _high.toSigned(width - _lowAndMiddleBitCount));
    } else if (width > _lowBitCount) {
      int middle = _middle.toSigned(width - _lowBitCount);
      return middle.isNegative
          ? Int64._masked(_low, middle, _maskHigh)
          : Int64._masked(_low, middle, 0); // Masking for type inferrer.
    } else {
      int low = _low.toSigned(width);
      return low.isNegative
          ? Int64._masked(low, _mask, _maskHigh)
          : Int64._masked(low, 0, 0); // Masking for type inferrer.
    }
  }

  @override
  Int64 toUnsigned(int width) {
    if (width < 0 || width > 64) throw RangeError.range(width, 0, 64);
    if (width > _lowAndMiddleBitCount) {
      int high = _high.toUnsigned(width - _lowAndMiddleBitCount);
      return Int64._masked(_low, _middle, high);
    } else if (width > _lowBitCount) {
      int middle = _middle.toUnsigned(width - _lowBitCount);
      return Int64._masked(_low, middle, 0);
    } else {
      int low = _low.toUnsigned(width);
      return Int64._masked(low, 0, 0);
    }
  }

  @override
  List<int> toBytes() {
    var result = List<int>.filled(8, 0);
    result[0] = _low & 0xff;
    result[1] = (_low >> 8) & 0xff;
    result[2] = ((_middle << 6) & 0xfc) | ((_low >> 16) & 0x3f);
    result[3] = (_middle >> 2) & 0xff;
    result[4] = (_middle >> 10) & 0xff;
    result[5] = ((_high << 4) & 0xf0) | ((_middle >> 18) & 0xf);
    result[6] = (_high >> 4) & 0xff;
    result[7] = (_high >> 12) & 0xff;
    return result;
  }

  @override
  double toDouble() => toInt().toDouble();

  @override
  int toInt() {
    int low = _low;
    int middle = _middle;
    int high = _high;
    // In the sum we add least significant to most significant so that in
    // JavaScript double arithmetic rounding occurs on only the last addition.
    if ((_high & _signBitMask) != 0) {
      low = _mask & ~_low;
      middle = _mask & ~_middle;
      high = _maskHigh & ~_high;
      return -((1 + low) + (4194304 * middle) + (17592186044416 * high));
    } else {
      return low + (4194304 * middle) + (17592186044416 * high);
    }
  }

  /// Returns an [Int32] containing the low 32 bits of this [Int64].
  @override
  Int32 toInt32() {
    return Int32(((_middle & 0x3ff) << _lowBitCount) | _low);
  }

  /// Returns `this`.
  @override
  Int64 toInt64() => this;

  /// Returns the value of this [Int64] as a decimal [String].
  @override
  String toString() => _toRadixString(10);

  // TODO(rice) - Make this faster by avoiding arithmetic.
  @override
  String toHexString() {
    if (isZero) return '0';
    Int64 value = this;
    String hexString = '';
    while (!value.isZero) {
      int digit = value._low & 0xf;
      hexString = '${_hexDigit(digit)}$hexString';
      value = value.shiftRightUnsigned(4);
    }
    return hexString;
  }

  /// Returns the digits of `this` when interpreted as an unsigned 64-bit value.
  @pragma('dart2js:noInline')
  String toStringUnsigned() {
    return _toRadixStringUnsigned(10, _low, _middle, _high, '');
  }

  @pragma('dart2js:noInline')
  String toRadixStringUnsigned(int radix) {
    return _toRadixStringUnsigned(
        Int32._validateRadix(radix), _low, _middle, _high, '');
  }

  @override
  String toRadixString(int radix) {
    return _toRadixString(Int32._validateRadix(radix));
  }

  String _toRadixString(int radix) {
    int low = _low;
    int middle = _middle;
    int high = _high;

    String sign = '';
    if ((high & _signBitMask) != 0) {
      sign = '-';

      // Negate in-place.
      low = 0 - low;
      int borrow = (low >> _lowBitCount) & 1;
      low &= _mask;
      middle = 0 - middle - borrow;
      borrow = (middle >> _lowBitCount) & 1;
      middle &= _mask;
      high = 0 - high - borrow;
      high &= _maskHigh;
      // high, middle, low now are an unsigned 64 bit integer for MIN_VALUE and
      // an unsigned 63 bit integer for other values.
    }
    return _toRadixStringUnsigned(radix, low, middle, high, sign);
  }

  static String _toRadixStringUnsigned(
      int radix, int lowest, int low, int middle, String sign) {
    if (lowest == 0 && low == 0 && middle == 0) return '0';

    // Rearrange components into five components where all but the most
    // significant are 10 bits wide.
    //
    //     d4, d3, d4, d1, d0:  24 + 10 + 10 + 10 + 10 bits
    //
    // The choice of 10 bits allows a remainder of 20 bits to be scaled by 10
    // bits and added during division while keeping all intermediate values
    // within 30 bits (unsigned small integer range for 32 bit implementations
    // of Dart VM and V8).
    //
    //     6  6         5         4         3         2         1
    //     3210987654321098765432109876543210987654321098765432109876543210
    //     [-------high-------][-------middle-------][---------low--------]
    //  -->
    //     [--------highest-------][--high--][-middle-][---low--][-lowest-]

    int highest = (middle << 4) | (low >> 18);
    int high = (low >> 8) & 0x3ff;
    middle = ((low << 2) | (lowest >> 20)) & 0x3ff;
    low = (lowest >> 10) & 0x3ff;
    lowest = lowest & 0x3ff;

    int fatRadix = _fatRadixTable[radix];

    // Generate chunks of digits.  In radix 10, generate 6 digits per chunk.
    //
    // This loop generates at most 3 chunks, so we store the chunks in locals
    // rather than a list.  We are trying to generate digits 20 bits at a time
    // until we have only 30 bits left.  20 + 20 + 30 > 64 would imply that we
    // need only two chunks, but radix values 17-19 and 33-36 generate only 15
    // or 16 bits per iteration, so sometimes the third chunk is needed.

    String chunkHigh = '', chunkMiddle = '', chunkLow = '';

    while (!(highest == 0 && high == 0)) {
      int quotient = highest ~/ fatRadix;
      int remainder = highest - quotient * fatRadix;
      highest = quotient;
      high += remainder << 10;

      quotient = high ~/ fatRadix;
      remainder = high - quotient * fatRadix;
      high = quotient;
      middle += remainder << 10;

      quotient = middle ~/ fatRadix;
      remainder = middle - quotient * fatRadix;
      middle = quotient;
      low += remainder << 10;

      quotient = low ~/ fatRadix;
      remainder = low - quotient * fatRadix;
      low = quotient;
      lowest += remainder << 10;

      quotient = lowest ~/ fatRadix;
      remainder = lowest - quotient * fatRadix;
      lowest = quotient;

      assert(chunkLow == '');
      chunkLow = chunkMiddle;
      chunkMiddle = chunkHigh;
      // Adding [fatRadix] Forces an extra digit which we discard to get a fixed
      // width.  E.g.  (1000000 + 123) -> "1000123" -> "000123".  An alternative
      // would be to pad to the left with zeroes.
      chunkHigh = (fatRadix + remainder).toRadixString(radix).substring(1);
    }
    int residue = (middle << 20) + (low << 10) + lowest;
    String leadingDigits = residue == 0 ? '' : residue.toRadixString(radix);
    return '$sign$leadingDigits$chunkHigh$chunkMiddle$chunkLow';
  }

  // Table of 'fat' radix values.  Each entry for index `i` is the largest power
  // of `i` whose remainder fits in 20 bits.
  static const _fatRadixTable = <int>[
    0,
    0,
    2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2,
    3 * 3 * 3 * 3 * 3 * 3 * 3 * 3 * 3 * 3 * 3 * 3,
    4 * 4 * 4 * 4 * 4 * 4 * 4 * 4 * 4 * 4,
    5 * 5 * 5 * 5 * 5 * 5 * 5 * 5,
    6 * 6 * 6 * 6 * 6 * 6 * 6,
    7 * 7 * 7 * 7 * 7 * 7 * 7,
    8 * 8 * 8 * 8 * 8 * 8,
    9 * 9 * 9 * 9 * 9 * 9,
    10 * 10 * 10 * 10 * 10 * 10,
    11 * 11 * 11 * 11 * 11,
    12 * 12 * 12 * 12 * 12,
    13 * 13 * 13 * 13 * 13,
    14 * 14 * 14 * 14 * 14,
    15 * 15 * 15 * 15 * 15,
    16 * 16 * 16 * 16 * 16,
    17 * 17 * 17 * 17,
    18 * 18 * 18 * 18,
    19 * 19 * 19 * 19,
    20 * 20 * 20 * 20,
    21 * 21 * 21 * 21,
    22 * 22 * 22 * 22,
    23 * 23 * 23 * 23,
    24 * 24 * 24 * 24,
    25 * 25 * 25 * 25,
    26 * 26 * 26 * 26,
    27 * 27 * 27 * 27,
    28 * 28 * 28 * 28,
    29 * 29 * 29 * 29,
    30 * 30 * 30 * 30,
    31 * 31 * 31 * 31,
    32 * 32 * 32 * 32,
    33 * 33 * 33,
    34 * 34 * 34,
    35 * 35 * 35,
    36 * 36 * 36
  ];

  String toDebugString() {
    return 'Int64[_l=$_low, _m=$_middle, _h=$_high]';
  }

  static Int64 _masked(int low, int middle, int high) =>
      Int64._bits(_mask & low, _mask & middle, _maskHigh & high);

  static Int64 _subtract(
      int firstMinuendLow,
      int firstMinuendMiddle,
      int firstMinuendHigh,
      int secondMinuendLow,
      int secondMinuendMiddle,
      int secondMinuendHigh) {
    int diffLow = firstMinuendLow - secondMinuendLow;
    int diffMiddle = firstMinuendMiddle -
        secondMinuendMiddle -
        ((diffLow >> _lowBitCount) & 1);
    int diffHigh = firstMinuendHigh -
        secondMinuendHigh -
        ((diffMiddle >> _lowBitCount) & 1);
    return _masked(diffLow, diffMiddle, diffHigh);
  }

  static Int64 _negate(int low, int middle, int high) {
    return _subtract(0, 0, 0, low, middle, high);
  }

  String _hexDigit(int digit) => '0123456789ABCDEF'[digit];

  // Work around dart2js bugs with negative arguments to '>>' operator.
  static int _shiftRight(int value, int bitShiftCount) {
    if (value >= 0) {
      return value >> bitShiftCount;
    } else {
      int shifted = value >> bitShiftCount;
      if (shifted >= 0x80000000) {
        shifted -= 4294967296;
      }
      return shifted;
    }
  }

  // Implementation of '~/', '%' and 'remainder'.

  static Int64 _divide(Int64 a, other, _DivisionReturnType returnType) {
    Int64 b = _promote(other);
    if (b.isZero) {
      throw const IntegerDivisionByZeroException();
    }
    if (a.isZero) return zero;

    bool isANegative = a.isNegative;
    bool isBNegative = b.isNegative;

    a = a.abs();
    b = b.abs();

    return _divideHelper(a._low, a._middle, a._high, isANegative, b._low,
        b._middle, b._high, isBNegative, returnType);
  }

  static Int64 _divideHelper(
      // up to 64 bits unsigned in dividendHigh/dividendMiddle/dividendLow and
      // divisorHigh/divisorMiddle/divisorLow
      int dividendLow,
      int dividendMiddle,
      int dividendHigh,
      bool isDividendNegative,
      int divisorLow,
      int divisorMiddle,
      int divisorHigh,
      bool isDivisorNegative, // input B.
      _DivisionReturnType returnType) {
    int quotientLow = 0, quotientMiddle = 0, quotientHigh = 0;
    int remainderLow = 0, remainderMiddle = 0, remainderHigh = 0;

    if (divisorHigh == 0 &&
        divisorMiddle == 0 &&
        divisorLow < (1 << (30 - _lowBitCount))) {
      // Small divisor can be handled by single-digit division within Smi range.
      //
      // Handling small divisors here helps the estimate version below by
      // handling cases where the estimate is off by more than a small amount.

      quotientHigh = dividendHigh ~/ divisorLow;
      int carry = dividendHigh - quotientHigh * divisorLow;
      int smallDivisorMiddle = dividendMiddle + (carry << _lowBitCount);
      quotientMiddle = smallDivisorMiddle ~/ divisorLow;
      carry = smallDivisorMiddle - quotientMiddle * divisorLow;
      int smallDivisorLow = dividendLow + (carry << _lowBitCount);
      quotientLow = smallDivisorLow ~/ divisorLow;
      remainderLow = smallDivisorLow - quotientLow * divisorLow;
    } else {
      // Approximate Q = A ~/ B and R = A - Q * B using doubles.

      // The floating point approximation is very close to the correct value
      // when floor(A/B) fits in fewer that 53 bits.

      // We use double arithmetic for intermediate values.  Double arithmetic on
      // non-negative values is exact under the following conditions:
      //
      //   - The values are integer values that fit in 53 bits.
      //   - Dividing by powers of two (adjusts exponent only).
      //   - Floor (zeroes bits with fractional weight).

      const double highThreshold = 17592186044416.0; // 2^44
      const double middleThreshold = 4194304.0; // 2^22

      // Approximate double values for [a] and [b].
      double approximateA = dividendLow +
          middleThreshold * dividendMiddle +
          highThreshold * dividendHigh;
      double approximateB = divisorLow +
          middleThreshold * divisorMiddle +
          highThreshold * divisorHigh;
      // Approximate quotient.
      double approximateQuotient =
          (approximateA / approximateB).floorToDouble();

      // Extract components of [qd] using double arithmetic.
      double approximateQuotientHigh =
          (approximateQuotient / highThreshold).floorToDouble();
      approximateQuotient =
          approximateQuotient - highThreshold * approximateQuotientHigh;
      double approximateQuotientMiddle =
          (approximateQuotient / middleThreshold).floorToDouble();
      double approximateQuotientLow =
          approximateQuotient - middleThreshold * approximateQuotientMiddle;
      quotientHigh = approximateQuotientHigh.toInt();
      quotientMiddle = approximateQuotientMiddle.toInt();
      quotientLow = approximateQuotientLow.toInt();

      assert(quotientLow +
              middleThreshold * quotientMiddle +
              highThreshold * quotientHigh ==
          (approximateA / approximateB).floorToDouble());
      assert(quotientHigh == 0 ||
          divisorHigh == 0); // Q and B can't both be big since Q*B <= A.

      // P = Q * B, using doubles to hold intermediates.
      // We don't need all partial sums since Q*B <= A.
      double approximatePartialLow = approximateQuotientLow * divisorLow;
      double partialLowCarry =
          (approximatePartialLow / middleThreshold).floorToDouble();
      approximatePartialLow =
          approximatePartialLow - partialLowCarry * middleThreshold;
      double approximatePartialMiddle = approximateQuotientMiddle * divisorLow +
          approximateQuotientLow * divisorMiddle +
          partialLowCarry;
      double partialMiddleCarry =
          (approximatePartialMiddle / middleThreshold).floorToDouble();
      approximatePartialMiddle =
          approximatePartialMiddle - partialMiddleCarry * middleThreshold;
      double partialHighDouble = approximateQuotientHigh * divisorLow +
          approximateQuotientMiddle * divisorMiddle +
          approximateQuotientLow * divisorHigh +
          partialMiddleCarry;
      assert(partialHighDouble <= _maskHigh); // No partial sum overflow.

      // R = A - P
      int diffLow = dividendLow - approximatePartialLow.toInt();
      int diffMiddle = dividendMiddle -
          approximatePartialMiddle.toInt() -
          ((diffLow >> _lowBitCount) & 1);
      int diffHigh = dividendHigh -
          partialHighDouble.toInt() -
          ((diffMiddle >> _lowBitCount) & 1);
      remainderLow = _mask & diffLow;
      remainderMiddle = _mask & diffMiddle;
      remainderHigh = _maskHigh & diffHigh;

      // while (R < 0 || R >= B)
      //  adjust R towards [0, B)
      while (remainderHigh >= _signBitMask ||
          remainderHigh > divisorHigh ||
          (remainderHigh == divisorHigh &&
              (remainderMiddle > divisorMiddle ||
                  (remainderMiddle == divisorMiddle &&
                      remainderLow >= divisorLow)))) {
        // Direction multiplier for adjustment.
        int middle = (remainderHigh & _signBitMask) == 0 ? 1 : -1;
        // R = R - B  or  R = R + B
        int currentDivisorLow = remainderLow - middle * divisorLow;
        int currentDivisorMiddle = remainderMiddle -
            middle *
                (divisorMiddle + ((currentDivisorLow >> _lowBitCount) & 1));
        int currentDivisorHigh = remainderHigh -
            middle *
                (divisorHigh + ((currentDivisorMiddle >> _lowBitCount) & 1));
        remainderLow = _mask & currentDivisorLow;
        remainderMiddle = _mask & currentDivisorMiddle;
        remainderHigh = _maskHigh & currentDivisorHigh;

        // Q = Q + 1  or  Q = Q - 1
        currentDivisorLow = quotientLow + middle;
        currentDivisorMiddle =
            quotientMiddle + middle * ((currentDivisorLow >> _lowBitCount) & 1);
        currentDivisorHigh = quotientHigh +
            middle * ((currentDivisorMiddle >> _lowBitCount) & 1);
        quotientLow = _mask & currentDivisorLow;
        quotientMiddle = _mask & currentDivisorMiddle;
        quotientHigh = _maskHigh & currentDivisorHigh;
      }
    }

    // 0 <= R < B
    assert(Int64.zero <=
        Int64._bits(remainderLow, remainderMiddle, remainderHigh));
    assert(remainderHigh < divisorHigh || // Handles case where B = -(MIN_VALUE)
        Int64._bits(remainderLow, remainderMiddle, remainderHigh) <
            Int64._bits(divisorLow, divisorMiddle, divisorHigh));

    if (returnType != _DivisionReturnType.quotient && !isDividendNegative) {
      return Int64._masked(remainderLow, remainderMiddle,
          remainderHigh); // Masking for type inferrer.
    }

    switch (returnType) {
      case _DivisionReturnType.quotient:
        if (isDividendNegative != isDivisorNegative) {
          return _negate(quotientLow, quotientMiddle, quotientHigh);
        }
        return Int64._masked(quotientLow, quotientMiddle,
            quotientHigh); // Masking for type inferrer.
      case _DivisionReturnType.modulo:
        if (remainderLow == 0 && remainderMiddle == 0 && remainderHigh == 0) {
          return zero;
        } else {
          return _subtract(divisorLow, divisorMiddle, divisorHigh, remainderLow,
              remainderMiddle, remainderHigh);
        }
      case _DivisionReturnType.remainder:
        return _negate(remainderLow, remainderMiddle, remainderHigh);
    }
  }
}

enum _DivisionReturnType { quotient, remainder, modulo }
