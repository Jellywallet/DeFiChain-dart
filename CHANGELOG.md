## 3.1.0+1
- Fix

## 3.1.0
- Fix all unit tests
- Fix mix of segwit and non-segwit outputs

## 3.0.1
- Fix to add "RemoveLiqiudity" inside tx builder

## 3.0.0+2
- Downgrade meta to 1.3.0

## 3.0.0+1
- Downgrade test so 1.0

## 3.0.0
- Add null safety

## 2.3.1+1
- Update reference

## 2.3.0
- Add Remove Liquidity

## 2.2.1+5
- Update packages

## 2.2.1+4
- Update packages

## 2.2.1+1
- Add DeFiChain specific txs
- Update packages

## 2.2.1
- Fix analyze warning

## 2.2.0
- Support P2SH(P2WPKH)

## 2.1.0
- Release bitcoindart package
## 2.0.2
- Add support for optional 'noStrict' parameter in Transaction.fromBuffer

## 2.0.1
- Add payments/index.dart to lib exports

## 2.0.0 **Backwards Incompatibility**
- Please update your sign function if you use this version. sign now [required parameter name](https://github.com/anicdh/bitcoin_flutter/blob/master/lib/src/transaction_builder.dart#L121)
- Support  building a Transaction with a SegWit P2WPKH input
- Add Address.validateAddress to validate address

## 1.1.0

- Add PaymentData, P2PKHData to be deprecated, will remove next version
- Support p2wpkh

## 1.0.7

- Try catch getter privKey, base58Priv, wif
- Possible to create a neutered HD Wallet

## 1.0.6

- Accept non-standard payment

## 1.0.5

- Add ECPair to index

## 1.0.4

- Add transaction to index

## 1.0.3

- Fix bug testnet BIP32

## 1.0.2

- Add sign and verify for HD Wallet and Wallet

## 1.0.1

- Add derive and derive path for HD Wallet

## 1.0.0

- Transaction implementation

## 0.1.1

- HDWallet from Seed implementation
- Wallet from WIF implementation
