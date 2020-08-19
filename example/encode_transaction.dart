import 'package:dart_esr/dart_esr.dart';

main(List<String> args) => transactionExample();

Future<void> transactionExample() async {
  var auth = <Authorization>[ESRConstants.PlaceholderAuth];

  var data = <String, String>{'name': 'data'};

  var actions = <Action>[
    Action()
      ..account = 'eosnpingpong'
      ..name = 'ping'
      ..authorization = auth
      ..data = data,
  ];

  var transaction = Transaction()..actions = actions;

  var args = SigningRequestCreateArguments(
    transaction: transaction,
    chainId: 'e70aaab8997e1dfce58fbfac80cbbb8fecec7b99cf982a9444273cbc64c41473',
  );
  SigningRequestEncodingOptions options = defaultSigningRequestEncodingOptions(
      nodeUrl: 'https://jungle.greymass.com');

  try {
    var request = await SigningRequestManager.create(args, options: options);

    var uri = request.encode();
    print('transaction\n' + uri);
  } catch (e) {
    print(e.toString());
  }
}
