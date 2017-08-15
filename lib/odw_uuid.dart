// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'src/errors.dart';
import 'package:system/system.dart';

export 'src/errors.dart';
export 'src/uuid.dart';
export 'src/v4generator.dart';

Null invalidUuidError(Object uuid) {
  log.error(InvalidUuidError.message(uuid));
  if (throwOnError) throw new InvalidUuidError(uuid);
  return null;
}


