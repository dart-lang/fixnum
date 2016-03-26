// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Hex digit char codes
const int _CC_0 = 48; // '0'.codeUnitAt(0)
const int _CC_9 = 57; // '9'.codeUnitAt(0)
const int _CC_a = 97; // 'a'.codeUnitAt(0)
const int _CC_z = 122; // 'z'.codeUnitAt(0)
const int _CC_A = 65; // 'A'.codeUnitAt(0)
const int _CC_Z = 90; // 'Z'.codeUnitAt(0)

int decodeDigit(int c) {
  if (c >= _CC_0 && c <= _CC_9) {
    return c - _CC_0;
  } else if (c >= _CC_a && c <= _CC_z) {
    return c - _CC_a + 10;
  } else if (c >= _CC_A && c <= _CC_Z) {
    return c - _CC_A + 10;
  } else {
    return -1; // bad char code
  }
}

int validateRadix(int radix) {
  if (2 <= radix && radix <= 36) return radix;
  throw new RangeError.range(radix, 2, 36, 'radix');
}

// Assumes i is <= 32-bit
int numberOfLeadingZeros(int i) {
  i |= i >> 1;
  i |= i >> 2;
  i |= i >> 4;
  i |= i >> 8;
  i |= i >> 16;
  return bitCount(~i);
}

int numberOfTrailingZeros(int i) => bitCount((i & -i) - 1);

// Assumes i is <= 32-bit.
int bitCount(int i) {
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

  i -= ((i >> 1) & 0x55555555);
  i = (i & 0x33333333) + ((i >> 2) & 0x33333333);
  i = ((i + (i >> 4)) & 0x0F0F0F0F);
  i += (i >> 8);
  i += (i >> 16);
  return (i & 0x0000003F);
}
