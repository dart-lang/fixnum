// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Export the emulated class when compiling to JS, `int` wrapper class on other
// targets (AOT, JIT, Wasm).
export 'int64_native.dart' if (dart.library.html) 'int64_emulated.dart';
