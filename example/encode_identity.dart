import 'package:dart_esr/dart_esr.dart';

Future<void> main(List<String> arguments) async {
  var esr = EOSIOSigningrequest('https://jungle2.cryptolions.io', 'v1',
      chainName: ChainName.EOS_JUNGLE2);

  var permission = IdentityPermission()
    ..actor = 'testname1111'
    ..permission = 'active';

  var identity = Identity()..identityPermission = permission;
  String callback = "https://cNallback.com";

  var encoded = await esr.encodeIdentity(identity, callback);
  var decoded = esr.deserialize(encoded);

  print('identity : ' + encoded);
  print(decoded);
}
