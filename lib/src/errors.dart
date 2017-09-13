// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:system/system.dart';

class InvalidUuidListError extends Error {
	List<int> bytes;
	String msg;


	InvalidUuidListError(this.bytes, this.msg);

	String toString() => message(msg, bytes);

	static String message(String msg, List<int> bytes) =>
			'InvalidUuidListError: $msg: $bytes';
}

Uint8List invalidUuidListError(List<int> iList, msg) {
	log.error(msg);
	if (throwOnError) throw new InvalidUuidListError(iList, msg);
	return null;
}

class InvalidUuidParseError extends Error {
	String msg;

	InvalidUuidParseError(this.msg);

	String toString() => message(msg);

	static String message(String msg) => 'InvalidUuidParseError: $msg';
}

Uint8List invalidUuidParseError(String msg) {
	log.error(msg);
	if (throwOnError) throw new InvalidUuidParseError(msg);
	return null;
}

Uint8List invalidUuidStringLengthError(String s, int targetLength) {
	var msg = 'Invalid String length(${s.length} should be $targetLength';
	return invalidUuidParseError(msg);
}

Uint8List invalidUuidNullStringError() {
	var msg = 'Invalid null string';
	return invalidUuidParseError(msg);
}

Uint8List invalidUuidCharacterError(String s, [String char]) {
	var msg = 'Invalid character in String';
	if (char != null) msg += ': "$char"';
	return invalidUuidParseError(msg);
}

Uint8List invalidUuidParseToBytesError(String s, int targetLength) {
	if (s == null) return invalidUuidNullStringError();
	if (s.length != targetLength) return invalidUuidStringLengthError(s, targetLength);
	return invalidUuidParseError(s);
}





