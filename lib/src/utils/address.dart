import 'dart:typed_data';

class AddressUtils {
  static Uint8List compressPubkey({required Uint8List pubkey}) {
    if (pubkey.length == 65) {
      var parity = pubkey[64] & 1;
      var newKey = pubkey.getRange(0, 33).toList();
      newKey[0] = 2 | parity;
      return Uint8List.fromList(newKey);
    }
    return pubkey;
  }
}
