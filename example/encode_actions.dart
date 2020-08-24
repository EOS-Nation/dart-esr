import 'package:dart_esr/dart_esr.dart';

main(List<String> args) => actionsExample();

Future<void> actionsExample() async {
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
}
