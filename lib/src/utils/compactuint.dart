import 'check_types.dart';
import 'dart:typed_data';

Uint8List encode(int n) {
  var len = 0;
  var buffer = Uint8List(encodingLength(n));

  while (true) {
    var a = (n & 0x7F);
    var b = (len != 0 ? 0x80 : 0x00);
    buffer[len] = (a | b);
    if (n <= 0x7F) {
      break;
    }
    n = (n >> 7) - 1;
    len++;
  }

  return Uint8List.fromList(buffer.reversed.toList());
}

int encodingLength(int i) {
  return i > 0x7fffffff
      ? 5
      : i > 0x7fffff
          ? 4
          : i > 0x7fff
              ? 3
              : i > 0x7f
                  ? 2
                  : i >= 0x00
                      ? 1
                      : 0;
}
