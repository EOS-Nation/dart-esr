import 'package:dart_esr/dart_esr.dart';

main(List<String> args) => decodeExample();

void decodeExample() async {

  var esr =
      'esr://gmN0S9_Eeqy57zv_9xn9eU3hL_bxCbUs-jptJqsXY3-JtawgA0NBEFfzSoWzDAwM4bo2Z88yMjJAABOUVoQJGKw8nWa1MrnkhZQgmM8S7OrqEgxkABUAAA';

  var request = SigningRequestManager.from(esr,
      options: defaultSigningRequestEncodingOptions(
          nodeUrl: 'https://api.eos.miami'));

  var abis = await request.fetchAbis();

  var auth = Authorization();
  auth.actor = 'illumination';
  auth.permission = 'active';

  var actions = request.resolveActions(abis, auth);
  print(" actions: " + actions?.toString());
}

void decodeExample2() async {
  var esr =
      'esr://gmNcs7jsE9uOP6rL3rrcvpMWUmN27LCdleD836_eTzFz-vCSjQEMXhmEFohe6ry3yuguIyNEiIEJSgvCBA58nnUl1dgwlAEoAAA';

  var request = SigningRequestManager.from(esr,
      options: defaultSigningRequestEncodingOptions(
          nodeUrl: 'https://api.eos.miami'));

  var abis = await request.fetchAbis();

  var auth = Authorization();
  auth.actor = 'illumination';
  auth.permission = 'active';

  var actions = request.resolveActions(abis, auth);
  print(" actions: " + actions?.toString());
}

