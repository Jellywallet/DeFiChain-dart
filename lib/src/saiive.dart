import 'dart:typed_data';

import 'package:defichaindart/defichaindart.dart';

class SaiiveTxTypes {
  static var ExportData = 'E';
}

class SaiiveTransactionHelper {
  static var SaiiveTxHeader = const [0x73, 0x61, 0x69, 0x69, 0x76, 0x65];

  static OutputBase createExportOutput() {
    var script = List<int>.empty(growable: true);

    script.addAll(SaiiveTxHeader);
    script.add(SaiiveTxTypes.ExportData[0].codeUnitAt(0));

    var saiiveScript = Uint8List.fromList(script);
    return OutputBase(script: saiiveScript, value: 0);
  }
}
