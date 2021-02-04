import 'package:defichaindart/defichaindart.dart';
import 'package:defichaindart/src/defi.dart';
import 'package:defichaindart/src/payments/p2wpkh.dart';
import 'package:test/test.dart';

import 'package:defichaindart/src/ecpair.dart';
import 'package:defichaindart/src/transaction_builder.dart';
import 'package:defichaindart/src/models/networks.dart' as networks;

void main() {
  group('defi transactions', () {
    test('can create a AnyAccountsToAccounts transaction', () {
      final alice = ECPair.fromWIF(
          'cPx3xUD441mriaUkA7t3Q4jSen7rHX5Za3942QrBVyCasknqy7YK',
          network: networks.defichain_testnet);
      final txb = TransactionBuilder(network: networks.defichain_testnet);

      txb.setVersion(4);
      txb.addInput(
          'ba03252dca756620b83db5efbea2650e5cd68be449de9c4faa659a2af7df37f3',
          0);

      txb.addAnyAccountToAccountOutput(
          1,
          "teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs",
          100000000,
          "tXmZ6X4xvZdUdXVhUKJbzkcN2MNuwVSEWv",
          100000000,
          networks.defichain_testnet);
      txb.addOutput('teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs', 99998614);

      txb.sign(vin: 0, keyPair: alice);

      var txHex = txb.build().toHex();
    });
    test('can create a AnyAccountsToAccounts transaction', () {
      final alice = ECPair.fromWIF(
          'cPx3xUD441mriaUkA7t3Q4jSen7rHX5Za3942QrBVyCasknqy7YK',
          network: networks.defichain_testnet);
      final p2wpkh = P2WPKH(data: PaymentData(pubkey: alice.publicKey)).data;

      final txb = TransactionBuilder(network: networks.defichain_testnet);

      txb.setVersion(2);
      txb.addInput(
          'ba03252dca756620b83db5efbea2650e5cd68be449de9c4faa659a2af7df37f3',
          1);

      txb.addAccountToAccountOutput(
          1,
          "teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs",
          "tXmZ6X4xvZdUdXVhUKJbzkcN2MNuwVSEWv",
          100000000,
          networks.defichain_testnet);
      txb.addOutput('teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs', 999981140);

      txb.sign(vin: 0, keyPair: alice, witnessValue: 999991140, redeemScript: p2wpkh.output);

      var txHex = txb.build().toHex();
      expect(txHex,
          '02000000000101f337dff72a9a65aa4f9cde49e48bd65c0e65a2beefb53db8206675ca2d2503ba010000001716001400325935ec2f78004479fd2ff512dd94ff0adcdfffffffff020000000000000000456a43446654784217a9145c41c70349fd7ab79e2359bd0f0627d2d9bff8c2870117a9141084ef98bacfecbc9f140496b26516ae55d79bfa87010100000000e1f5050000000054809a3b0000000017a9145c41c70349fd7ab79e2359bd0f0627d2d9bff8c2870247304402203a2fcc7f1f675370a72f87575c27a62b82ae798bdf6dcfd02bd50b2b6d381e5e0220231f75d691a17830f9fb95f58f2ead90bdbb98c76d3f91437c3589f525f1899f0121032b2b28c7348d8d955b2c228e44b644a1a28b243f61eea826eee218ad97da843900000000');
    });
  });
}
