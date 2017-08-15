// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

abstract class UuidErrorHandler {
  Null inValidUuidError(Object uuid);
}

class InvalidUuidError extends Error {
  Object uuid;

  InvalidUuidError(this.uuid);

  String toString() => message(uuid);

  static String message(Object uuid) {
    var s = (uuid is String) ? '"$uuid"' : '$uuid';
    return 'InvalidUuidError: $s';
  }
}
