import 'package:dart_esr/src/encoding_options.dart';
import 'package:dart_esr/src/signing_request_interface.dart';
import 'package:dart_esr/src/signing_request_manager.dart';
import 'package:dart_esr/src/utils/esr_constant.dart';

void main(List<String> arguments) => identityExample();

Future<void> identityExample() async {
  // options
  var callback = CallbackType('https://mycallback.com', true);
  var args = SigningRequestCreateIdentityArguments( callback,
      chainId: 'aca376f206b8fc25a6ed44dbdc66547c36c6c33e3a119ffbeaef943642f0e906',
      account: ESRConstants.PlaceholderName,
      permission: ESRConstants.PlaceholderPermission
  );
  SigningRequestEncodingOptions options = defaultSigningRequestEncodingOptions(nodeUrl: 'https://eos.eosn.io');

  // request identity
  var request = await SigningRequestManager.identity(args, options: options);
  var uri = request.encode();

  print(uri);
}
