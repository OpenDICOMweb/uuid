// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:system/core.dart';

class UuidError extends Error {

	String msg;

	UuidError(this.msg);

	@override
	String toString() => 'InvalidUuidListError: $msg';
}

class InvalidUuidListError extends Error {
  List<int> bytes;
  String msg;

  InvalidUuidListError(this.bytes, this.msg);

  @override
  String toString() => message(msg, bytes);

  static String message(String msg, List<int> bytes) =>
      'InvalidUuidListError: $msg: $bytes';
}

Uint8List invalidUuidListError(List<int> iList, String msg) {
  log.error(msg);
  if (throwOnError) throw new InvalidUuidListError(iList, msg);
  return null;
}

class UuidParseError extends Error {
  String msg;

  UuidParseError(this.msg);

  @override
  String toString() => message(msg);

  static String message(String msg) => 'InvalidUuidParseError: $msg';
}

Uint8List invalidUuidParseError(String msg) {
  log.error(msg);
  if (throwOnError) throw new UuidParseError(msg);
  return null;
}

Uint8List invalidUuidStringLengthError(String s, int targetLength) {
  final msg = 'Invalid String length(${s.length} should be $targetLength';
  return invalidUuidParseError(msg);
}

Uint8List invalidUuidNullStringError() {
  final msg = 'Invalid null string';
  return invalidUuidParseError(msg);
}

Uint8List invalidUuidCharacterError(String s, [String char]) =>
    invalidUuidParseError('Invalid character in String: "$char"');

Uint8List invalidUuidParseToBytesError(String s, int targetLength) {
  if (s == null) return invalidUuidNullStringError();
  if (s.length != targetLength) return invalidUuidStringLengthError(s, targetLength);
  return invalidUuidParseError(s);
}
