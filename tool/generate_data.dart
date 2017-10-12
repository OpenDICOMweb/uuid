// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:uuid/uuid.dart';

void main() {
  final data = generateData();
  print(data);
  final test = generateTest();
  print(test);
}

String generateData() {
  final sList = <String>[];
  final dList = <String>[];
  final rUuids = <Uuid>[];
  final sUuids = <String>[];
  final dUuids = <String>[];

  final sb = new StringBuffer(header);
  for (var i = 0; i < 10; i++) {
    final uuid = new Uuid();
    // Random Uuids
    rUuids.add(uuid);
    // List of Uuid Strings
    sList.add('"$uuid.asString"');
    // List of [Uuid] data
    dList.add('data$i');
    // List of [Uuid]s generated from a data list
    dUuids.add('uuidD$i');
    // List of [Uuid]s generated from Strings.
    sUuids.add('uuidS$i');
    final data = uuid.data;
    sb
      ..write('  // $i: data\n')
      ..write(dataToString('data$i', data))
      ..write('String s$i = "${uuid.asString}";\n')
      ..write('Uuid uuidD$i = new Uuid.fromList(data$i);\n')
      ..write('Uuid uuidS$i = Uuid.parse(s$i);\n\n');
  }
  sb
    ..write(stringListToString('sList', sList))
    ..write(dataListToString('dList', dList))
    ..write(uuidListToString('dUuids', dUuids))
    ..write(uuidListToString('sUuids', sUuids));
  return sb.toString();
}

String generateTest() {
  final sb = new StringBuffer('$header$program');
  for (var i = 0; i < 10; i++) {
    sb
      ..write('expect(uuidD$i == uuidS$i, true);\n')
      ..write('version = s$i[14];\n')
      ..write('log.debug("version: \$version");\n')
      ..write('expect(s$i[14] == "4", true);\n')
      ..write('type = s$i[19];\n')
      ..write('log.debug("type: \$type");\n')
      ..write('expect(typeChars.contains(s$i[19]), true);\n\n');
  }
  sb.write(trailer);
  return sb.toString();
}

String dataToString(String id, List<int> iList) => '''
List<int> $id = <int>[
    ${iList.sublist(0, 8).join(', ')}, // No reformat
    ${iList.sublist(8, 16).join(', ')}
  ];
''';

String header = '''
// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

/// The following data are generate with tools/generate_data.dart.import '

import 'package:uuid/uuid_w_seed.dart';
''';

String stringListToString(String id, List<String> sList) {
  final list = sList.join(',\n    ');
  return 'List<String> $id = <String>[\n    $list\n  ];\n\n';
}

String dataListToString(String id, List<String> dList) {
  final list = dList.join(', ');
  return 'List<List<int>>  $id = <List<int>>[\n    $list\n  ];\n\n';
}

String uuidListToString(String id, List<String> uList) {
  final list = uList.join(', ');
  return 'List<Uuid>  $id = <Uuid>[\n    $list  \n  ];\n\n';
}

String program = '''
/// Assert that the data above are valid.
void main() {
  const List<String> typeChars = const <String>['8', '9', 'a', 'b'];
  
  String version;
  String type;
  
''';

String trailer = '''
}

''';
