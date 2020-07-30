import 'package:dart_esr/src/encoding_options.dart';
import 'package:dart_esr/src/models/action.dart';
import 'package:dart_esr/src/models/authorization.dart';
import 'package:dart_esr/src/models/transaction.dart';
import 'package:dart_esr/src/serializeUtils.dart';
import 'package:dart_esr/src/signing_request.dart';
import 'package:dart_esr/src/signing_request_interface.dart';
import 'package:dart_esr/src/utils/esr_constant.dart';

main(List<String> args) async {
  // transactionTest();
  identityTest();
}

Future<void> actionTest() async {
  var esr = EOSSerializeUtils('https://jungle2.cryptolions.io', 'v1');
  var auth = <Authorization>[ESRConstants.PlaceholderAuth];

  var data = <String, String>{'name': 'data'};

  var action = Action()
    ..account = 'eosnpingpong'
    ..name = 'ping'
    ..authorization = auth
    ..data = data;

  var args = SigningRequestCreateArguments(
    action: action,
    chainId: 'e70aaab8997e1dfce58fbfac80cbbb8fecec7b99cf982a9444273cbc64c41473',
  );
  SigningRequestEncodingOptions options = defaultSigningRequestEncodingOptions;

  var request =
      await SigningRequest.create(args, options: options, serializeUtils: esr);

  var uri = request.encode();
  print(uri);
}

Future<void> actionsTest() async {
  var esr = EOSSerializeUtils('https://jungle2.cryptolions.io', 'v1');
  var auth = <Authorization>[ESRConstants.PlaceholderAuth];

  var data = <String, String>{'name': 'data'};

  var action = Action()
    ..account = 'eosnpingpong'
    ..name = 'ping'
    ..authorization = auth
    ..data = data;

  var action2 = Action()
    ..account = 'eosnpingpong'
    ..name = 'ping'
    ..authorization = auth
    ..data = data;

  var action3 = Action()
    ..account = 'eosnpingpong'
    ..name = 'ping'
    ..authorization = auth
    ..data = data;

  var args = SigningRequestCreateArguments(
    actions: [action, action2, action3],
    chainId: 'e70aaab8997e1dfce58fbfac80cbbb8fecec7b99cf982a9444273cbc64c41473',
  );
  SigningRequestEncodingOptions options = defaultSigningRequestEncodingOptions;

  var request =
      await SigningRequest.create(args, options: options, serializeUtils: esr);

  var uri = request.encode();
  print(uri);
}

Future<void> identityTest() async {
  var esr = EOSSerializeUtils('https://jungle2.cryptolions.io', 'v1');

  var callback = CallbackType('asdf', true);
  var args = SigningRequestCreateIdentityArguments(callback,
      chainId:
          'e70aaab8997e1dfce58fbfac80cbbb8fecec7b99cf982a9444273cbc64c41473',
      account: 'pacoeosnatio',
      permission: 'active');

  SigningRequestEncodingOptions options = defaultSigningRequestEncodingOptions;

  var idReq = await SigningRequest.identity(args,
      options: options, serializeUtils: esr);

  // encode signing request as URI string
  var uri = idReq.encode();
  print(uri);
}

Future<void> transactionTest() async {
  var esr = EOSSerializeUtils('https://jungle2.cryptolions.io', 'v1');
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
  SigningRequestEncodingOptions options = defaultSigningRequestEncodingOptions;

  var request =
      await SigningRequest.create(args, options: options, serializeUtils: esr);

  var uri = request.encode();
  print(uri);
}
