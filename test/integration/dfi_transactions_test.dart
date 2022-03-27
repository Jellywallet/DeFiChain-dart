import 'package:defichaindart/defichaindart.dart';
import 'package:defichaindart/src/payments/p2wpkh.dart';
import 'package:test/test.dart';

import 'package:defichaindart/src/ecpair.dart';
import 'package:defichaindart/src/transaction_builder.dart';
import 'package:defichaindart/src/models/networks.dart' as networks;

import 'package:bip32_defichain/bip32.dart' as bip32;

bip32.NetworkType getNetwork(NetworkType networkInstance) {
  final networkType = bip32.NetworkType(bip32: bip32.Bip32Type(private: networkInstance.bip32.private, public: networkInstance.bip32.public), wif: networkInstance.wif);
  return networkType;
}

void main() {
  group('defi transactions', () {
    test('can create a AnyAccountsToAccounts transaction', () {
      final alice = ECPair.fromWIF('cPx3xUD441mriaUkA7t3Q4jSen7rHX5Za3942QrBVyCasknqy7YK', network: networks.defichain_testnet);
      final txb = TransactionBuilder(network: networks.defichain_testnet);

      txb.setVersion(4);
      txb.addInput('ba03252dca756620b83db5efbea2650e5cd68be449de9c4faa659a2af7df37f3', 0);

      txb.addAnyAccountToAccountOutput(1, "teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs", 100000000, "tXmZ6X4xvZdUdXVhUKJbzkcN2MNuwVSEWv", 100000000);
      txb.addOutput('7LMorkhKTDjbES6DfRxX2RiNMbeemUkxmp', 99998614);

      txb.sign(vin: 0, keyPair: alice);

      var txHex = txb.build().toHex();
    });
    test('can create a AccountsToAccounts transaction', () {
      final alice = ECPair.fromWIF('cPx3xUD441mriaUkA7t3Q4jSen7rHX5Za3942QrBVyCasknqy7YK', network: networks.defichain_testnet);
      final p2wpkh = P2WPKH(data: PaymentData(pubkey: alice.publicKey)).data!;

      final txb = TransactionBuilder(network: networks.defichain_testnet);

      txb.setVersion(2);
      txb.addInput('ba03252dca756620b83db5efbea2650e5cd68be449de9c4faa659a2af7df37f3', 1);

      txb.addAccountToAccountOutput(1, "teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs", "tXmZ6X4xvZdUdXVhUKJbzkcN2MNuwVSEWv", 100000000);
      txb.addOutput('teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs', 999981140);

      txb.sign(vin: 0, keyPair: alice, witnessValue: 999991140, redeemScript: p2wpkh.output);

      var txHex = txb.build().toHex();
      expect(txHex,
          '02000000000101f337dff72a9a65aa4f9cde49e48bd65c0e65a2beefb53db8206675ca2d2503ba010000001716001400325935ec2f78004479fd2ff512dd94ff0adcdfffffffff020000000000000000456a43446654784217a9145c41c70349fd7ab79e2359bd0f0627d2d9bff8c2870117a9141084ef98bacfecbc9f140496b26516ae55d79bfa87010100000000e1f5050000000054809a3b0000000017a9145c41c70349fd7ab79e2359bd0f0627d2d9bff8c2870247304402203a2fcc7f1f675370a72f87575c27a62b82ae798bdf6dcfd02bd50b2b6d381e5e0220231f75d691a17830f9fb95f58f2ead90bdbb98c76d3f91437c3589f525f1899f0121032b2b28c7348d8d955b2c228e44b644a1a28b243f61eea826eee218ad97da843900000000');
    });

    test('can create a AccountsToAccounts transaction v4', () {
      final alice = ECPair.fromWIF('cPx3xUD441mriaUkA7t3Q4jSen7rHX5Za3942QrBVyCasknqy7YK', network: networks.defichain_testnet);
      final p2wpkh = P2WPKH(data: PaymentData(pubkey: alice.publicKey)).data!;

      final txb = TransactionBuilder(network: networks.defichain_testnet);

      txb.setVersion(4);
      txb.addInput('ba03252dca756620b83db5efbea2650e5cd68be449de9c4faa659a2af7df37f3', 1);

      txb.addAccountToAccountOutput(1, "teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs", "tXmZ6X4xvZdUdXVhUKJbzkcN2MNuwVSEWv", 100000000);
      txb.addOutput('teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs', 999981140);

      txb.sign(vin: 0, keyPair: alice, witnessValue: 999991140, redeemScript: p2wpkh.output);

      var txHex = txb.build().toHex();
      expect(txHex,
          '04000000000101f337dff72a9a65aa4f9cde49e48bd65c0e65a2beefb53db8206675ca2d2503ba010000001716001400325935ec2f78004479fd2ff512dd94ff0adcdfffffffff020000000000000000456a43446654784217a9145c41c70349fd7ab79e2359bd0f0627d2d9bff8c2870117a9141084ef98bacfecbc9f140496b26516ae55d79bfa87010100000000e1f505000000000054809a3b0000000017a9145c41c70349fd7ab79e2359bd0f0627d2d9bff8c2870002483045022100dea872004bb8f9a8bb325c66515412afbb695f6b290f5ba88dc4d3ecee99ad5d022060af047a75c368e6e1d72f7c5146fba558950fa78875d3c46dc78a4fbeb7b1050121032b2b28c7348d8d955b2c228e44b644a1a28b243f61eea826eee218ad97da843900000000');
    });

    test('can create a AccountToUtxo transaction', () {
      final alice = ECPair.fromWIF('cPx3xUD441mriaUkA7t3Q4jSen7rHX5Za3942QrBVyCasknqy7YK', network: networks.defichain_testnet);
      final p2wpkh = P2WPKH(data: PaymentData(pubkey: alice.publicKey)).data!;

      final txb = TransactionBuilder(network: networks.defichain_testnet);
      final fee = 500;
      txb.setVersion(2);
      txb.addInput('647a6218d98a93197416efad757bda007507ed1f9be5e7011f3815f801e5e433', 2);

      txb.addAccountToUtxoOutput(0, "teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs", 99900000, 2);

      txb.addOutput('teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs', 100000000 - fee);
      txb.addOutput("teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs", 99900000);
      txb.sign(vin: 0, keyPair: alice, witnessValue: 100000000, redeemScript: p2wpkh.output);

      var txHex = txb.build().toHex();
      expect(txHex,
          '0200000000010133e4e501f815381f01e7e59b1fed077500da7b75adef167419938ad918627a64020000001716001400325935ec2f78004479fd2ff512dd94ff0adcdfffffffff0300000000000000002d6a2b446654786217a9145c41c70349fd7ab79e2359bd0f0627d2d9bff8c2870100000000605af40500000000020cdff5050000000017a9145c41c70349fd7ab79e2359bd0f0627d2d9bff8c287605af4050000000017a9145c41c70349fd7ab79e2359bd0f0627d2d9bff8c2870247304402203c03b1f644b6362cee539180dd8ce8661bdf52f06977cfd73410209ae7130681022043761992c917b329448ecb0a65f5018cdf2075ba566db0d62be60ca34254f25b0121032b2b28c7348d8d955b2c228e44b644a1a28b243f61eea826eee218ad97da843900000000');
    });
    test('can create a UtxosToAccount transaction', () {
      final alice = ECPair.fromWIF('cPx3xUD441mriaUkA7t3Q4jSen7rHX5Za3942QrBVyCasknqy7YK', network: networks.defichain_testnet);
      final p2wpkh = P2WPKH(data: PaymentData(pubkey: alice.publicKey)).data!;

      final txb = TransactionBuilder(network: networks.defichain_testnet);
      final fee = 500;
      final dfiAmount = 99898500;

      txb.setVersion(2);
      txb.addInput('736b2098bfd9af8de4d6d86135ad5c18dd355df5cba3d0ebae57b1a57cfc7f4e', 1);

      txb.addUtxosToAccountOutput(0, "teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs", dfiAmount - fee, networks.defichain_testnet);

      // we use all funds from prev transaction here, so we do not need a return tx
      //txb.addOutput('teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs', dfiAmount - fee);
      txb.sign(vin: 0, keyPair: alice, witnessValue: dfiAmount, redeemScript: p2wpkh.output);

      var txHex = txb.build().toHex();
      expect(txHex,
          '020000000001014e7ffc7ca5b157aeebd0a3cbf55d35dd185cad3561d8d6e48dafd9bf98206b73010000001716001400325935ec2f78004479fd2ff512dd94ff0adcdfffffffff019052f405000000002d6a2b44665478550117a9145c41c70349fd7ab79e2359bd0f0627d2d9bff8c28701000000009052f4050000000002483045022100c990166d69524033a70de1d72faeef17d786e72addd8a5e32daf6f2d42b685f80220689f5d867762ade52c1078319767614809bc1937badf98087977fc71abca4c700121032b2b28c7348d8d955b2c228e44b644a1a28b243f61eea826eee218ad97da843900000000');
    });
    test('can create a SwapAccount transaction', () {
      final alice = ECPair.fromWIF('cNpueJjp8geQJut28fDyUD8e5zoyctHxj9GE8rTbQXwiEwLo1kq4', network: networks.defichain_testnet);
      final p2wpkh = P2WPKH(data: PaymentData(pubkey: alice.publicKey)).data!;

      final txb = TransactionBuilder(network: networks.defichain_testnet);
      final fee = 500;
      final dfiAmount = 100000000;

      txb.setVersion(2);
      txb.addInput('99abae71a3063cf73caa75df4647ecb73e8841916e664fd5ea197a70848bba89', 1);

      txb.addSwapOutput(0, "tXmZ6X4xvZdUdXVhUKJbzkcN2MNuwVSEWv", 100000000, 1, "toMR4jje52shBy5Mi5wEGWvAETLBCsZprw", 0, 12627393020);

      // we use all funds from prev transaction here, so we do not need a return tx
      txb.addOutput('tXmZ6X4xvZdUdXVhUKJbzkcN2MNuwVSEWv', dfiAmount - fee);
      txb.sign(vin: 0, keyPair: alice, witnessValue: dfiAmount, redeemScript: p2wpkh.output);

      var txHex = txb.build().toHex();
      expect(txHex,
          '0200000000010189ba8b84707a19ead54f666e9141883eb7ec4746df75aa3cf73c06a371aeab99010000001716001421cf7b9e2e17fa2879be2a442d8454219236bd3affffffff020000000000000000526a4c4f446654787317a9141084ef98bacfecbc9f140496b26516ae55d79bfa870000e1f5050000000017a914bb7642fd3a9945fd75aff551d9a740768ac7ca7b87010000000000000000fcb9a6f0020000000cdff5050000000017a9141084ef98bacfecbc9f140496b26516ae55d79bfa870248304502210099835a4638e4ff32df7234c1aad2b0321e252f7044f753aca20595a18fd966cc02201954cb8e286b9c83425427f7a5a4bfbe1d4ab5195ef040d4bb5f74e3aa31127f012103352705381be729d234e692a6ee4bf9e2800b9fc1ef0ebc96b6cf35c38658c93c00000000');
    });

    test('can create a v4 transaction', () {
      final alice = ECPair.fromWIF('cT6j7CUDF1JBoa3SUdTA4vJwvxRGXuq3ywzUPauzVGu3utBaWC7e', network: networks.defichain_testnet);
      final p2wpkh = P2WPKH(data: PaymentData(pubkey: alice.publicKey)).data!;

      final txb = TransactionBuilder(network: networks.defichain_testnet);
      final fee = 500;
      final dfiAmount = 2999963800;

      txb.setVersion(4);
      txb.addInput('5dd449ee12a978b6828993f5e25019b7a82cd1d1d4ba5f28791f324a31ae6ce3', 1);

      // we use all funds from prev transaction here, so we do not need a return tx
      txb.addOutput('tXmZ6X4xvZdUdXVhUKJbzkcN2MNuwVSEWv', dfiAmount - fee);
      txb.sign(vin: 0, keyPair: alice, witnessValue: dfiAmount, redeemScript: p2wpkh.output);

      var txHex = txb.build().toHex();
      expect(txHex,
          '04000000000101e36cae314a321f79285fbad4d1d12ca8b71950e2f5938982b678a912ee49d45d0100000017160014bb9c2f70d1514a06a443e559f32ff714cbf090e1ffffffff01a4cecfb20000000017a9141084ef98bacfecbc9f140496b26516ae55d79bfa870002483045022100c87f1955d1c407dc517e6a28bcc152672728c14499a009a9623954b72d92de7f022031b033f2d9416533d36c455f6306328b007153411ae2e9c6e23ee723ac58e47b012102d38083820bbb90384190c807ffd960bc584573ae3177b70eec14b8e200a6a81100000000');
    });

    test('can create a v4 transaction', () {
      final alice = ECPair.fromWIF('cT6j7CUDF1JBoa3SUdTA4vJwvxRGXuq3ywzUPauzVGu3utBaWC7e', network: networks.defichain_testnet);
      final p2wpkh = P2WPKH(data: PaymentData(pubkey: alice.publicKey)).data!;

      final txb = TransactionBuilder(network: networks.defichain_testnet);
      final fee = 500;
      final dfiAmount = 2999963800;

      txb.setVersion(4);
      txb.addInput('5dd449ee12a978b6828993f5e25019b7a82cd1d1d4ba5f28791f324a31ae6ce3', 1);

      // we use all funds from prev transaction here, so we do not need a return tx
      txb.addOutput('tf1q0sdhm4s642cw4cfj952ghpxykgs4grqcvc7amc', dfiAmount - fee);
      txb.sign(vin: 0, keyPair: alice, witnessValue: dfiAmount, redeemScript: p2wpkh.output);

      var txHex = txb.build().toHex();
      expect(txHex,
          '04000000000101e36cae314a321f79285fbad4d1d12ca8b71950e2f5938982b678a912ee49d45d0100000017160014bb9c2f70d1514a06a443e559f32ff714cbf090e1ffffffff01a4cecfb20000000017a9141084ef98bacfecbc9f140496b26516ae55d79bfa870002483045022100c87f1955d1c407dc517e6a28bcc152672728c14499a009a9623954b72d92de7f022031b033f2d9416533d36c455f6306328b007153411ae2e9c6e23ee723ac58e47b012102d38083820bbb90384190c807ffd960bc584573ae3177b70eec14b8e200a6a81100000000');
    });

    test('create transaction with P2WPKH input', () {
      var phrase = "rely denial exact surprise entire female lounge play put click charge finger leader true raven mobile inflict kitten lady topic caught input there apple";

      var seed = mnemonicToSeed(phrase);
      var wallet = bip32.BIP32.fromSeedWithCustomKey(seed, "@defichain/jellyfish-wallet-mnemonic", getNetwork(defichain_testnet));

      var key = wallet.derivePath("1129/0/0/0");
      final address = P2WPKH(data: PaymentData(pubkey: key.publicKey), network: defichain_testnet).data!.address;

      expect(address, "tf1q0sdhm4s642cw4cfj952ghpxykgs4grqcvc7amc");

      final p2wpkh = P2WPKH(data: PaymentData(pubkey: key.publicKey), network: networks.defichain_testnet).data!;
      final txb = TransactionBuilder(network: networks.defichain_testnet);
      txb.setVersion(4);
      txb.addInput('b923e15549819af41aebd09506d1b9515aa5739f3e778f70e74ec53aa7740563', 0, null, p2wpkh.output);
      txb.addInput('b923e15549819af41aebd09506d1b9515aa5739f3e778f70e74ec53aa7740563', 1, null, p2wpkh.output);
      txb.addInput('87aa5fae47f4b9bdc71edde7c11d33e753847d589240d3d02629351ae7b250f0', 0, null, p2wpkh.output);

      txb.addOutput("tf1qqmqp5efqfuf5tk06ty0qpzz3jkud9d6f0qxn0d", 1000000000);
      txb.addOutput("tf1q0sdhm4s642cw4cfj952ghpxykgs4grqcvc7amc", 7099995060);

      txb.sign(vin: 0, keyPair: ECPair.fromPrivateKey(key.privateKey!, network: networks.defichain_testnet), witnessValue: 100000000);
      txb.sign(vin: 1, keyPair: ECPair.fromPrivateKey(key.privateKey!, network: networks.defichain_testnet), witnessValue: 7899996450);
      txb.sign(vin: 2, keyPair: ECPair.fromPrivateKey(key.privateKey!, network: networks.defichain_testnet), witnessValue: 100000000);
      // // prepare for broadcast to the Bitcoin network, see 'can broadcast a Transaction' below

      final hexTx = txb.build().toHex();
      expect(hexTx,
          '04000000000103630574a73ac54ee7708f773e9f73a55a51b9d10695d0eb1af49a814955e123b90000000000ffffffff630574a73ac54ee7708f773e9f73a55a51b9d10695d0eb1af49a814955e123b90100000000fffffffff050b2e71a352926d0d34092587d8453e7331dc1e7dd1ec7bdb9f447ae5faa870000000000ffffffff0200ca9a3b0000000016001406c01a65204f1345d9fa591e00885195b8d2b74900b45331a7010000001600147c1b7dd61aaab0eae1322d148b84c4b221540c180002473044022043af0e425e6d6e4dbc70e0e081a5c236c9a7da3748aaf6b36a3c35acf1885b76022076f2716bf72966e93e524a79dee05b4457bc0f450447baaa50cf881274b05f8d0121023a4f64906e99902e7f44c3099bed77ea435b5e1b80559274a1d3b377f7cd747b02473044022067d27e4b27e01949c4a2fe16dd8cffce0fba87d9e308b551d0328779398be99702200416fc8a02a4f6352514784815afbb8c54118d9a3841f3ceea1031bb4db1458a0121023a4f64906e99902e7f44c3099bed77ea435b5e1b80559274a1d3b377f7cd747b0247304402203612f6105fdf87a216471059953c8570e9e2d7f76eec3f137ab55c1193799d13022017a8f65e3c6c8d2f1b18449966f571ef300a00a58bcd1cc47d8183a0168f5c070121023a4f64906e99902e7f44c3099bed77ea435b5e1b80559274a1d3b377f7cd747b00000000');
    });
  });
}
