# dart-esr

dart-esr is used to generate an EOSIO signing request (ESR) for a transaction/action/actions[]/identity request to be send, sign and broadcast to a node by a wallet (Greymass' Anchor Wallet or other supporting ESR)

Greymass' ESR protocol documentation -> https://github.com/eosio-eps/EEPs/blob/master/EEPS/eep-7.md#ESR---The--EOSIO-Signing-Request--protocol 

dart-esr is based on the javascript library eosio-signing-request -> https://github.com/greymass/eosio-signing-request

Request format -> https://github.com/eosio-eps/EEPs/blob/master/EEPS/eep-7.md#payload

## Examples

https://github.com/EOS-Nation/dart-esr/tree/master/example

## Usage

#### Import
```dart
import 'package:dart_esr/dart_esr.dart';
```

#### Encode an action

```dart
  var auth = <Authorization>[ESRConstants.PlaceholderAuth];

  var data = <String, dynamic>{
    'voter': ESRConstants.PlaceholderName,
    'proxy': 'eosnationftw',
    'producers': [],
  };

  var action = Action()
    ..account = 'eosio'
    ..name = 'voteproducer'
    ..authorization = auth
    ..data = data;

  var args = SigningRequestCreateArguments(
    action: action,
    chainId: ESRConstants.ChainIdLookup[ChainName.EOS],
  );

  SigningRequestEncodingOptions options =
      defaultSigningRequestEncodingOptions(nodeUrl: 'https://eos.eosn.io');

  var request = await SigningRequestManager.create(args, options: options);

  var uri = request.encode();
  print('action\n' + uri);
```

#### Encode a transaction 
```dart
 var auth = <Authorization>[ESRConstants.PlaceholderAuth];

  var data = <String, dynamic>{
    'voter': ESRConstants.PlaceholderName,
    'proxy': 'eosnationftw',
    'producers': [],
  };

  var action = Action()
    ..account = 'eosio'
    ..name = 'voteproducer'
    ..authorization = auth
    ..data = data;

  var transaction = Transaction()..actions = [action];

  var args = SigningRequestCreateArguments(
    transaction: transaction,
    chainId: ESRConstants.ChainIdLookup[ChainName.EOS],
  );
  SigningRequestEncodingOptions options =
      defaultSigningRequestEncodingOptions(nodeUrl: 'https://eos.eosn.io');

  var request = await SigningRequestManager.create(args, options: options);

  var uri = request.encode();
  print('transaction\n' + uri);
```

#### Encode an identity request
```dart
  var callback = CallbackType('http://callback.com', true);
  var args = SigningRequestCreateIdentityArguments(callback,
      chainId: ESRConstants.ChainIdLookup[ChainName.EOS],
      account: ESRConstants.PlaceholderName,
      permission: ESRConstants.PlaceholderPermission);

  SigningRequestEncodingOptions options = defaultSigningRequestEncodingOptions(
      nodeUrl: 'https://eos.eosn.io');

    var idReq = await SigningRequestManager.identity(args, options: options);

    var uri = idReq.encode();
    print('identity\n' + uri);
```

#### Encode a list of actions 
```dart
  var auth = <Authorization>[ESRConstants.PlaceholderAuth];

  var data1 = <String, String>{'name': 'data1'};
  var data2 = <String, String>{'name': 'data2'};
  var data3 = <String, String>{'name': 'data3'};

  var action = Action()
    ..account = 'eosnpingpong'
    ..name = 'ping'
    ..authorization = auth
    ..data = data1;

  var action2 = Action()
    ..account = 'eosnpingpong'
    ..name = 'ping'
    ..authorization = auth
    ..data = data2;

  var action3 = Action()
    ..account = 'eosnpingpong'
    ..name = 'ping'
    ..authorization = auth
    ..data = data3;

  var args = SigningRequestCreateArguments(
    actions: [action, action2, action3],
    chainId: ESRConstants.ChainIdLookup[ChainName.EOS],
  );
  SigningRequestEncodingOptions options = defaultSigningRequestEncodingOptions(
      nodeUrl: 'https://jungle.greymass.com');

  var request = await SigningRequestManager.create(args, options: options);
  
  var uri = request.encode();
  print('actions\n' + uri);
```

#### Decode a signing request 
```dart
  var esr =
      'esr://gmNcs7jsE9uOP6rL3rrcvpMWUmN27LCdleD836_eTzFz-vCSjQEMXhmEFohe6ry3yuguIyNEiIEJSgvCBA58nnUl1dgwlAEoAAA';
  var request = SigningRequestManager.from(esr,
      options:
          defaultSigningRequestEncodingOptions(nodeUrl: 'https://eos.eosn.io'));

  print('decode\n' + request?.data?.toString());
```

## Installing
The package is available in pub dev repository => https://pub.dev/packages/dart_esr
or in github => https://github.com/EOS-Nation/dart-esr

1 - Resolve dependencies
```console
pub get
```
2 - Execute examples
```console
pub run example/example.dart
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/EOS-Nation/dart-esr/issues
