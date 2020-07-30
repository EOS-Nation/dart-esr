import 'package:dart_esr/src/encoding_options.dart';
import 'package:dart_esr/src/models/action.dart';
import 'package:dart_esr/src/models/authorization.dart';
import 'package:dart_esr/src/serializeUtils.dart';
import 'package:dart_esr/src/signing_request.dart';
import 'package:dart_esr/src/signing_request_interface.dart';
import 'package:dart_esr/src/utils/esr_constant.dart';

main(List<String> args) async {
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
  print(request.toString());

  // encode signing request as URI string
  var uri = request.encode();
  print(uri);
}
