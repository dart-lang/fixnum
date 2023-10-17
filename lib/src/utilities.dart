// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Shared functionality used by multiple classes and their implementations.

int validateRadix(int radix) =>
    RangeError.checkValueInInterval(radix, 2, 36, 'radix');

/// Converts radix digits into their numeric values.
///
/// Converts the characters `0`-`9` into the values 0 through 9,
/// and the letters `a`-`z` or `A`-`Z` into values 10 through 35,
/// and return that value.
/// Any other character returns a value above 35, which means it's
/// not a valid digit in any radix in the range 2 through 36.
int decodeDigit(int c) {
  // Hex digit char codes
  const int c0 = 48; // '0'.codeUnitAt(0)
  const int ca = 97; // 'a'.codeUnitAt(0)

  int digit = c ^ c0;
  if (digit < 10) return digit;
  int letter = (c | 0x20) - ca;
  if (letter >= 0) {
    // Returns values above 36 for invalid digits.
    // The value is checked against the actual radix where the return
    // value is used, so this is safe.
    return letter + 10;
  } else {
    return 255; // Never a valid radix.
  }
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

  i -= (i >> 1) & 0x55555555;
  i = (i & 0x33333333) + ((i >> 2) & 0x33333333);
  i = (i + (i >> 4)) & 0x0F0F0F0F;
  i += i >> 8;
  i += i >> 16;
  return i & 0x0000003F;
}

String toRadixStringUnsigned(int radix, int d0, int d1, int d2, String sign) {
  if (d0 == 0 && d1 == 0 && d2 == 0) return '0';

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
  //     [--------d2--------][---------d1---------][---------d0---------]
  //  -->
  //     [----------d4----------][---d3---][---d2---][---d1---][---d0---]

  int d4 = (d2 << 4) | (d1 >> 18);
  int d3 = (d1 >> 8) & 0x3ff;
  d2 = ((d1 << 2) | (d0 >> 20)) & 0x3ff;
  d1 = (d0 >> 10) & 0x3ff;
  d0 = d0 & 0x3ff;

  int fatRadix = _fatRadixTable[radix];

  // Generate chunks of digits.  In radix 10, generate 6 digits per chunk.
  //
  // This loop generates at most 3 chunks, so we store the chunks in locals
  // rather than a list.  We are trying to generate digits 20 bits at a time
  // until we have only 30 bits left.  20 + 20 + 30 > 64 would imply that we
  // need only two chunks, but radix values 17-19 and 33-36 generate only 15
  // or 16 bits per iteration, so sometimes the third chunk is needed.

  String chunk1 = '', chunk2 = '', chunk3 = '';

  while (!(d4 == 0 && d3 == 0)) {
    int q = d4 ~/ fatRadix;
    int r = d4 - q * fatRadix;
    d4 = q;
    d3 += r << 10;

    q = d3 ~/ fatRadix;
    r = d3 - q * fatRadix;
    d3 = q;
    d2 += r << 10;

    q = d2 ~/ fatRadix;
    r = d2 - q * fatRadix;
    d2 = q;
    d1 += r << 10;

    q = d1 ~/ fatRadix;
    r = d1 - q * fatRadix;
    d1 = q;
    d0 += r << 10;

    q = d0 ~/ fatRadix;
    r = d0 - q * fatRadix;
    d0 = q;

    assert(chunk3 == '');
    chunk3 = chunk2;
    chunk2 = chunk1;
    // Adding [fatRadix] Forces an extra digit which we discard to get a fixed
    // width.  E.g.  (1000000 + 123) -> "1000123" -> "000123".  An alternative
    // would be to pad to the left with zeroes.
    chunk1 = (fatRadix + r).toRadixString(radix).substring(1);
  }
  int residue = (d2 << 20) + (d1 << 10) + d0;
  String leadingDigits = residue == 0 ? '' : residue.toRadixString(radix);
  return '$sign$leadingDigits$chunk1$chunk2$chunk3';
}

// Table of 'fat' radix values.  Each entry for index `i` is the largest power
// of `i` whose remainder fits in 20 bits.
const _fatRadixTable = <int>[
  0,
  0,
  2 * 2 * 2 * 2 * 2 * 2 * 2 * 2 * 2 * 2 * 2 * 2 * 2 * 2 * 2 * 2 * 2 * 2 * 2 * 2,
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
