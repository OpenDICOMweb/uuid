// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'src/uuid_base.dart';
import 'src/v4generator.dart';

/// The primary class for generating secure [Uuid]s package.
/// This class uses the secure random Uuid generator.

class Uuid extends UuidBase {
  // The random number generator
  static final V4Generator generator = new V4Generator.secure();

  Uuid() : super();

  Uuid.fromList(List<int> bytes) : super.fromList(bytes);

  String get type => 'Secure';

  static int get isSecure => v4Generator.isSecure;
  static int get seed => v4generator.seed;
  static bool get useUppercase => UuidBase.useUppercase;

  static bool isValidString(String s, [int type]) =>
      UuidBase.isValidString(s, type);

  static Uuid parse(String s, {Null Function(String) onError}) =>
      UuidBase.parse(s, onError: onError);
}
