import 'package:dart_esr/dart_esr.dart';

main(List<String> args) => transactionExample();

Future<void> transactionExample() async {
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
}
