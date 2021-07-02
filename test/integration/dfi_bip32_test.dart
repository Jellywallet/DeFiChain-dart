import 'dart:typed_data';

import 'package:bs58check/bs58check.dart';
import 'package:defichaindart/defichaindart.dart';
import 'package:defichaindart/src/payments/index.dart' show PaymentData;
import 'package:defichaindart/src/payments/p2sh.dart';
import 'package:test/test.dart';
import 'package:hex/hex.dart';
import 'package:defichaindart/defichaindart.dart' as bip39;
import 'package:bip32_defichain/bip32.dart' as bip32;

import 'package:defichaindart/src/models/networks.dart' as networks;

final _DEFICHAIN = bip32.NetworkType(wif: 0xef, bip32: new bip32.Bip32Type(public: 0x043587cf, private: 0x04358394));

void main() {
  group('defichain-dart (BIP32)', () {
    test('can import a BIP32 testnet xpriv and export to WIF', () {
      const xpriv = 'tprv8ZgxMBicQKsPd9Gff9E9fvhL5SDCLdKbjPbaREPyjLk743Sry9nAmESmaWwijZuGqer1Q4rG1SaUhc7XHvFg6y44z6JaKmTeHyJgNQism1U';
      final node = bip32.BIP32.fromBase58(
          xpriv,
          bip32.NetworkType(
              wif: networks.defichain_testnet.wif, bip32: bip32.Bip32Type(public: networks.defichain_testnet.bip32.public, private: networks.defichain_testnet.bip32.private)));

      expect(node.toWIF(), 'cQiVtAhXBopRjuYaz1mU3PHgQxSzEwT4VigMmAEU1Cp63d7cC1Ls');
    });
    test('can export a BIP32 xpriv, then import it', () {
      const mnemonic = 'sample visa rain lab truly dwarf hospital uphold stereo ride combine arrest aspect exist oil just boy garment estate enable marriage coyote blue yellow';
      final seed = bip39.mnemonicToSeed(mnemonic);
      final node = bip32.BIP32.fromSeed(seed, _DEFICHAIN);
      final string = node.toBase58();
      final restored = bip32.BIP32.fromBase58(string, _DEFICHAIN);
      expect(getAddress(node, defichain), getAddress(restored, defichain)); // same public key
      expect(node.toWIF(), restored.toWIF()); // same private key
    });
    test('can export a BIP32 xpub', () {
      const mnemonic = 'sample visa rain lab truly dwarf hospital uphold stereo ride combine arrest aspect exist oil just boy garment estate enable marriage coyote blue yellow';
      final seed = bip39.mnemonicToSeed(mnemonic);
      final node = bip32.BIP32.fromSeed(seed, _DEFICHAIN);
      final string = node.neutered().toBase58();
      expect(string, 'tpubD6NzVbkrYhZ4WV2sbTAhjr6zNkkQiK8Pbp2efViWyoetrqiaeUkc3UU1RNH2c87Fxa7phogCr4ytu4fWGNusEBnvxuYKqRVNuPqadz1nwK6');
    });
    test('can create a BIP32, defichain, account 0, external address', () {
      const path = "m/0'/0/0";
      final root = bip32.BIP32.fromSeed(Uint8List.fromList(HEX.decode('dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd')), _DEFICHAIN);
      final child1 = root.derivePath(path);
      // option 2, manually
      final child1b = root.deriveHardened(0).derive(0).derive(0);
      expect(getAddress(child1, defichain), 'dY21P2WpFqkSN39szoXfVf7XYtNRR5fpeZ');
      expect(getAddress(child1b, defichain), 'dY21P2WpFqkSN39szoXfVf7XYtNRR5fpeZ');
    });
    test('can create a BIP44, defichain, account 0, external address', () {
      final root = bip32.BIP32.fromSeed(Uint8List.fromList(HEX.decode('dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd')), _DEFICHAIN);
      final child1 = root.derivePath("m/44'/0'/0'/0/0");
      // option 2, manually
      final child1b = root.deriveHardened(44).deriveHardened(0).deriveHardened(0).derive(0).derive(0);
      expect(getAddress(child1, defichain), 'dWvdKzPasSVwxHRjesUJWjCtThV7k1Xg6V');
      expect(getAddress(child1b, defichain), 'dWvdKzPasSVwxHRjesUJWjCtThV7k1Xg6V');
    });
    /* TODO Support BIP49
    test('can create a BIP49, bitcoin testnet, account 0, external address', () {
    }); */
    test('can use BIP39 to generate BIP32 addresses', () {
      final mnemonic = 'sample visa rain lab truly dwarf hospital uphold stereo ride combine arrest aspect exist oil just boy garment estate enable marriage coyote blue yellow';
      assert(bip39.validateMnemonic(mnemonic));
      final seed = bip39.mnemonicToSeed(mnemonic);

      final root = bip32.BIP32.fromSeed(seed, _DEFICHAIN);
      var rootWif = root.toWIF();

      final rootasdf = bip32.BIP32.fromSeed(
          seed,
          bip32.NetworkType(
              bip32: bip32.Bip32Type(private: networks.defichain_testnet.bip32.private, public: networks.defichain_testnet.bip32.public), wif: networks.defichain_testnet.wif));

      //cNpueJjp8geQJut28fDyUD8e5zoyctHxj9GE8rTbQXwiEwLo1kq4
      var rootEc = ECPair.fromWIF("cQiVtAhXBopRjuYaz1mU3PHgQxSzEwT4VigMmAEU1Cp63d7cC1Ls");

      var wallet = ECPair.fromWIF('cNpueJjp8geQJut28fDyUD8e5zoyctHxj9GE8rTbQXwiEwLo1kq4', network: networks.defichain_testnet);
      var walletAddr = getAddress(wallet, networks.defichain_testnet);

      var priv = rootasdf.derivePath("m/0'/0'/0'");
      var privWif = priv.toWIF();

      var add = getAddress(priv, networks.defichain_testnet);

      // receive addresses
      final address = getAddress(root.derivePath("m/0'/0'/0'"), networks.defichain_testnet);
      expect(getAddress(root.derivePath("m/0'/0/0"), networks.defichain_testnet), 'tirp7qAXviD6Bj65PG5dKdKaWhqqLd7ddB');
      expect(getAddress(root.derivePath("m/0'/0/1"), networks.defichain_testnet), 'tkQ47WkrStp4GLQN9bW8oEnxPUnjqvNmow');
      // change addresses
      expect(getAddress(root.derivePath("m/0'/1/0"), networks.defichain_testnet), 'tcaEQm2Gv2J6bpS7PgRgHqA88GgNiz5Yjh');
      expect(getAddress(root.derivePath("m/0'/1/1"), networks.defichain_testnet), 'tkQgvrNwcPKJmQYqE3VoC6VB4GeoCYbcRv');
    });

    test("test vectors", () {
      var mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";

      final entropy = mnemonicToEntropy(mnemonic);
      final seed = mnemonicToSeed(mnemonic, passphrase: "TREZOR");
      final xPriv = bip32.BIP32.fromSeed(seed);
      final xPriv0 = xPriv.derivePath("m/0'");
      var wif = xPriv.toBase58();
      var wif0 = xPriv0.toBase58();

      expect(wif, "xprv9s21ZrQH143K3h3fDYiay8mocZ3afhfULfb5GX8kCBdno77K4HiA15Tg23wpbeF1pLfs1c5SPmYHrEpTuuRhxMwvKDwqdKiGJS9XFKzUsAF");
    });

    test("can import recovery phrase", () {
      var mnemonic = 'sample visa rain lab truly dwarf hospital uphold stereo ride combine arrest aspect exist oil just boy garment estate enable marriage coyote blue yellow';

      final seed = mnemonicToSeed(mnemonic, passphrase: "");
      final xPriv = bip32.BIP32
          .fromSeed(seed, bip32.NetworkType(bip32: bip32.Bip32Type(private: defichain_testnet.bip32.private, public: defichain_testnet.bip32.public), wif: defichain_testnet.wif));
      var wif = xPriv.toBase58();
      //cMmT7Q7sy3y44zbHWvkQQRto4hMsnMHfPJNXCeaadNHjZXU5HQ88
      var hdSeed = xPriv.toWIF();
      final xPriv0 = xPriv.derivePath("m/0'");
      var wif0 = xPriv0.toBase58();

      var ecPair = ECPair.fromWIF(hdSeed);
      var privateKey = base58.encode(ecPair.privateKey!);

      expect(wif, "tprv8ZgxMBicQKsPd215hoW7LSSsojEUYywV2WRsNygDZXrW2MTp25w1ryr9FDZVrLT8FDDM5jB45inzG8K8A13v67C3zKz9e9ewFTfiGTp5nTe");
    });
  });
}

String? getAddress(node, [network]) {
  return P2SH(data: PaymentData(redeem: P2WPKH(data: PaymentData(pubkey: node.publicKey), network: network).data), network: network).data!.address;
}
