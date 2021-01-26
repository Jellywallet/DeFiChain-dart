import 'dart:convert';

import 'package:bech32/bech32.dart';
import 'package:defichaindart/defichaindart.dart';
import 'package:defichaindart/src/payments/p2sh.dart';
import 'package:test/test.dart';
import 'package:defichaindart/src/address.dart' show Address;
import 'package:defichaindart/src/models/networks.dart' as networks;

List<int> rng(int number) {
  return utf8.encode('zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz');
}

void main() {
  group('DFI_Address', () {
    group('validateAddress', () {
      test('base58 addresses and valid network', () {
        expect(
            Address.validateAddress('tXmZ6X4xvZdUdXVhUKJbzkcN2MNuwVSEWv',
                networks.defichain_testnet),
            true);
        expect(
            Address.validateAddress('tp8k5cEcNjhQbiiPjJDg7ab7h8kzobsNfw',
                networks.defichain_testnet),
            true);
      });
      test('base58 addresses and invalid network', () {
        expect(
            Address.validateAddress('dZcHjYhKtEM88TtZLjp314H2xZjkztXtRc',
                networks.defichain_testnet),
            false);
        expect(
            Address.validateAddress(
                'tp8k5cEcNjhQbiiPjJDg7ab7h8kzobsNfw', networks.defichain),
            false);
      });

      test('invalid addresses', () {
        expect(Address.validateAddress('3333333casca'), false);
      });
      test('invalid addresses', () {
        expect(Address.validateAddress('asdfasdf'), false);
      });

      test('create addresses testnet', () {
        final network = networks.defichain_testnet;
        final keyPair = ECPair.makeRandom(network: network, rng: rng);
        final wif = keyPair.toWIF();
        final address = P2SH(
                data: PaymentData(
                    redeem: P2WPKH(
                            data: PaymentData(pubkey: keyPair.publicKey),
                            network: network)
                        .data),
                network: network)
            .data
            .address;

        expect(address, 'taNbqooKizHpDhxhRaunuoK1T6aKCX3TnF');
        expect(wif, 'cRgnQe9MUu1JznntrLaoQpB476M8PURvXVQB5R2eqms5tXnzNsrr');

        expect(Address.validateAddress('asdfasdf'), false);
      });
      test('create addresses mainnet', () {
        final network = networks.defichain;
        final keyPair = ECPair.makeRandom(network: network, rng: rng);
        final wif = keyPair.toWIF();
        final address = P2SH(
                data: PaymentData(
                    redeem: P2WPKH(
                            data: PaymentData(pubkey: keyPair.publicKey),
                            network: network)
                        .data),
                network: network)
            .data
            .address;

        expect(address, 'dHXgRgUNk8gX9EfQVeFgV2y7XvnUEoFNnn');
        expect(wif, 'L1Knwj9W3qK3qMKdTvmg3VfzUs3ij2LETTFhxza9LfD5dngnoLG1');

        expect(Address.validateAddress('asdfasdf'), false);
      });
    });
  });
}
