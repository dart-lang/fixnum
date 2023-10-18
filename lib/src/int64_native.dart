// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: constant_identifier_names

import 'int32.dart';
import 'int64.dart';
import 'utilities.dart' as u;

class Int64Impl implements Int64 {
  final int _i;

  static const Int64Impl MAX_VALUE = Int64Impl(9223372036854775807);

  static const Int64Impl MIN_VALUE = Int64Impl(-9223372036854775808);

  static const Int64Impl ZERO = Int64Impl(0);

  static const Int64Impl ONE = Int64Impl(1);

  static const Int64Impl TWO = Int64Impl(2);

  const Int64Impl([int value = 0]) : _i = value;

  factory Int64Impl.fromInts(int top, int bottom) =>
      Int64Impl((top << 32) | (bottom & 0xFFFFFFFF));

  factory Int64Impl.fromBytes(List<int> bytes) =>
      Int64Impl(((bytes[7] & 0xFF) << 56) |
          ((bytes[6] & 0xFF) << 48) |
          ((bytes[5] & 0xFF) << 40) |
          ((bytes[4] & 0xFF) << 32) |
          ((bytes[3] & 0xFF) << 24) |
          ((bytes[2] & 0xFF) << 16) |
          ((bytes[1] & 0xFF) << 8) |
          (bytes[0] & 0xFF));

  factory Int64Impl.fromBytesBigEndian(List<int> bytes) =>
      Int64Impl(((bytes[0] & 0xFF) << 56) |
          ((bytes[1] & 0xFF) << 48) |
          ((bytes[2] & 0xFF) << 40) |
          ((bytes[3] & 0xFF) << 32) |
          ((bytes[4] & 0xFF) << 24) |
          ((bytes[5] & 0xFF) << 16) |
          ((bytes[6] & 0xFF) << 8) |
          (bytes[7] & 0xFF));

  static Int64Impl? parseRadix(String s, int radix, bool throwOnError) {
    int charIdx = 0;
    bool negative = false;
    if (s.startsWith('-')) {
      negative = true;
      charIdx++;
    }

    if (charIdx >= s.length) {
      if (!throwOnError) return null;
      throw FormatException('No digits', s, charIdx);
    }

    int i = 0;
    for (; charIdx < s.length; charIdx++) {
      int c = s.codeUnitAt(charIdx);
      int digit = u.decodeDigit(c);
      if (digit < radix) {
        i = (i * radix) + digit;
      } else {
        if (!throwOnError) return null;
        throw FormatException('Not radix digit', s, charIdx);
      }
    }

    if (negative) {
      return Int64Impl(-i);
    }

    return Int64Impl(i);
  }

  static int _promote(Object value) {
    if (value is Int64Impl) {
      return value._i;
    } else if (value is int) {
      return value;
    } else if (value is Int32) {
      return value.toInt();
    }
    throw ArgumentError.value(value, 'other', 'not an int, Int32 or Int64');
  }

  @override
  Int64Impl operator +(Object other) => Int64Impl(_i + _promote(other));

  @override
  Int64Impl operator -(Object other) => Int64Impl(_i - _promote(other));

  @override
  Int64Impl operator -() => Int64Impl(-_i);

  @override
  Int64Impl operator *(Object other) => Int64Impl(_i * _promote(other));

  @override
  Int64Impl operator %(Object other) => Int64Impl(_i % _promote(other));

  @override
  Int64Impl operator ~/(Object other) => Int64Impl(_i ~/ _promote(other));

  @override
  Int64Impl remainder(Object other) => Int64Impl(_i.remainder(_promote(other)));

  @override
  Int64Impl operator &(Object other) => Int64Impl(_i & _promote(other));

  @override
  Int64Impl operator |(Object other) => Int64Impl(_i | _promote(other));

  @override
  Int64Impl operator ^(Object other) => Int64Impl(_i ^ _promote(other));

  @override
  Int64Impl operator ~() => Int64Impl(~_i);

  @override
  Int64Impl operator <<(int shiftAmount) => Int64Impl(_i << shiftAmount);

  @override
  Int64Impl operator >>(int shiftAmount) => Int64Impl(_i >> shiftAmount);

  @override
  Int64Impl shiftRightUnsigned(int shiftAmount) =>
      Int64Impl(_i >>> shiftAmount);

  @override
  int compareTo(Object other) => _i.compareTo(_promote(other));

  @override
  bool operator <(Object other) => _i < _promote(other);

  @override
  bool operator <=(Object other) => _i <= _promote(other);

  @override
  bool operator >(Object other) => _i > _promote(other);

  @override
  bool operator >=(Object other) => _i >= _promote(other);

  @override
  bool get isEven => _i.isEven;

  @override
  bool get isMaxValue => this == MAX_VALUE;

  @override
  bool get isMinValue => this == MIN_VALUE;

  @override
  bool get isNegative => _i < 0;

  @override
  bool get isOdd => _i.isOdd;

  @override
  bool get isZero => _i == 0;

  @override
  int get bitLength => _i.bitLength;

  @override
  int get hashCode => _i.hashCode;

  @override
  bool operator ==(Object other) => _i == _promote(other);

  @override
  Int64 abs() => Int64(_i.abs());

  @override
  Int64 clamp(Object lowerLimit, Object upperLimit) =>
      Int64(_i.clamp(_promote(lowerLimit), _promote(upperLimit)));

  @override
  int numberOfLeadingZeros() => _i < 0 ? 0 : (64 - _i.bitLength);

  @override
  int numberOfTrailingZeros() {
    if (_i == 0) return 64;
    var lsb = _i & (_i ^ (_i - 1));
    if (lsb < 0) return 63;
    return lsb.bitLength - 1;
  }

  @override
  Int64 toSigned(int width) {
    if (width < 1 || width > 64) {
      throw RangeError.range(width, 1, 64);
    }
    return Int64(_i.toSigned(width));
  }

  @override
  Int64 toUnsigned(int width) {
    if (width < 0 || width > 64) {
      throw RangeError.range(width, 0, 64);
    }
    return Int64(_i.toUnsigned(width));
  }

  @override
  List<int> toBytes() {
    final result = List<int>.filled(8, 0);
    result[0] = _i & 0xff;
    result[1] = (_i >> 8) & 0xff;
    result[2] = (_i >> 16) & 0xff;
    result[3] = (_i >> 24) & 0xff;
    result[4] = (_i >> 32) & 0xff;
    result[5] = (_i >> 40) & 0xff;
    result[6] = (_i >> 48) & 0xff;
    result[7] = (_i >> 56) & 0xff;
    return result;
  }

  @override
  double toDouble() => _i.toDouble();

  @override
  int toInt() => _i;

  @override
  Int32 toInt32() => Int32(_i);

  @override
  Int64 toInt64() => this;

  @override
  String toString() => _i.toString();

  @override
  String toHexString() => toRadixStringUnsigned(16).toUpperCase();

  @override
  String toRadixString(int radix) => _i.toRadixString(radix);

  @override
  String toRadixStringUnsigned(int radix) => _toRadixStringUnsigned(_i, radix);

  @override
  String toStringUnsigned() => _toRadixStringUnsigned(_i, 10);

  static String _toRadixStringUnsigned(int value, int radix) =>
      // low 22 bits, mid 22 bits, high 20 bits
      u.toRadixStringUnsigned(
          radix, value & 4194303, (value >> 22) & 4194303, value >>> 44, '');
}
