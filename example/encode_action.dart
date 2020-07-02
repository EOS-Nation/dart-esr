import 'package:dart_esr/dart_esr.dart';

Future<void> main(List<String> arguments) async {
  var esr = EOSIOSigningrequest('https://jungle2.cryptolions.io', 'v1',
      chainName: ChainName.EOS_JUNGLE2);

  var auth = <Authorization>[
    Authorization.fromJson(ESRConstants.PlaceholderAuth)
  ];

  var data = <String, String>{'name': 'data'};

  var action = Action()
    ..account = 'eosnpingpong'
    ..name = 'ping'
    ..authorization = auth
    ..data = data;

  var encoded = await esr.encodeAction(action);
  print('action : ' + encoded);

  var decoded = esr.deserialize(encoded);
  print(decoded);
}
