import 'dart:convert';
import 'dart:typed_data';

import 'package:bip32_defichain/bip32.dart';
import 'package:defichaindart/defichaindart.dart';
import 'package:hex/hex.dart';
import 'package:test/test.dart';
import 'package:defichaindart/src/models/networks.dart' as networks;

void main() {
  group('bitcoin', () {
    test('bitcoin sign test magic', () {
      var magic1 = HEX.encode(magicHash(''));
      expect(magic1, '80e795d4a4caadd7047af389d9f7f220562feb6196032e2131e10563352c4bcc');

      var m2 = HEX.encode(magicHash('Vires is Numeris'));
      expect(m2, 'f8a5affbef4a3241b19067aa694562f64f513310817297089a8929a930f4f933');
    });

    test('sign', () {
      final privateKey = ECPair.fromWIF('5KYZdUEo39z3FPrtuX2QbbwGnNP5zTd7yyr2SC1j299sBCnWjss', network: networks.bitcoin);
      var msg = 'vires is numeris';

      var signed = privateKey.signMessage(msg);

      print(signed);
    });
    test('sign mainnet DFI', () {
      var privateKey = ECPair.fromWIF('L1MYKXoYaKM2tf6iCiEXAv4J3cAK4GazAUePPVBpBXDqHVqyx2Ff', network: defichain);
      var msg =
          'By_signing_this_message,_you_confirm_that_you_are_the_sole_owner_of_the_provided_DeFiChain_address_and_are_in_possession_of_its_private_key._Your_ID:_8YBhdwtkkS1qPzwdXPX1pvm5wCersjBhV5';

      var signed = privateKey.signMessage(msg, networks.defichain, SegwitType.P2WPKH);
      expect('IDZaeRmB7HNNsmyUPNliSqnJQ8IfBi35JHi5e31zvCFtZN10VlV9cxhHUrYDUO7kEPVLweSGTtzuVK6KykcV4l4=', signed);
    });
    test('sign mainnet DFI P2SH', () {
      var privArra = Uint8List.fromList(
          [13, 255, 118, 1, 213, 120, 252, 189, 147, 183, 212, 129, 212, 200, 196, 203, 235, 133, 92, 90, 70, 96, 130, 185, 232, 102, 123, 118, 65, 28, 208, 167]);
      var privateKey = ECPair.fromPrivateKey(privArra, network: networks.defichain);
      var msg =
          'By_signing_this_message,_you_confirm_that_you_are_the_sole_owner_of_the_provided_DeFiChain_address_and_are_in_possession_of_its_private_key._Your_ID:_df1q395uhj7jy70atgtrtgc8nzp0kqnk7424fg2v2s';

      var signed = privateKey.signMessage(msg, networks.defichain);
      expect('H7tV5q32uRwtzzVSGcrfiHMKAlCCkHUwNK7iu+cZ5XctQCWXu552gNAliqGoZkh7/mi4Ps9AlXUzo4fgfRre9R0=', signed);
    });
  });
}
