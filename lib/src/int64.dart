// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'int64_native.dart' if (dart.library.js) 'int64_web.dart';

// Use export below instead while working on the web implementation.
// export 'int64_web.dart' if (dart.library.io) 'int64_native.dart';
