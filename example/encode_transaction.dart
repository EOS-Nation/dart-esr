import 'package:dart_esr/dart_esr.dart';

Future<void> main(List<String> arguments) async {
  var esr = EOSIOSigningrequest('https://jungle2.cryptolions.io', 'v1',
      chainName: ChainName.EOS_JUNGLE2);

  var auth = <Authorization>[
    Authorization()
      ..actor = 'testName1111'
      ..permission = 'active'
  ];

  var data = <String, String>{'name': 'data'};

  var actions = <Action>[
    Action()
      ..account = 'eosnpingpong'
      ..name = 'ping'
      ..authorization = auth
      ..data = data,
  ];

  var transaction = Transaction()..actions = actions;

  var encoded = await esr.encodeTransaction(transaction);
  print('transaction : ' + encoded);

  var decoded = esr.deserialize(encoded);
  print(decoded);
}
