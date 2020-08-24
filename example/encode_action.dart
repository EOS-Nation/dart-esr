import 'package:dart_esr/dart_esr.dart';

main(List<String> args) => actionExample();

Future<void> actionExample() async {
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
}
