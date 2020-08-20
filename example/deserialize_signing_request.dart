import 'package:dart_esr/dart_esr.dart';

main(List<String> args) => desezializeExample();

void desezializeExample() {
  var uri =
      "esr://gmN8zrVqx8w62T9P-_evaTi9u__Nm-qZ52doTXFRt9mTckSkmJmByTqjpKSg2EpfPzlJLzEvOSO_SC8nMy9b39zAzCIx2dJM18gs0VLXxNQwRTfRwtxA1zgpMdXM3MzQwtTQkpkFpFSLgYHB4aiWbzgDk1Zw_ObTlU85c7s4MpfmSx3-q3BJxkpY9A_f6Qv8f9b9b-AuTsxNjU9JLctMTmVk5C5KLSktyosvSCzJCE_LzEkFukI_Iz83Vb8gMTlf3yU_uTQ3Na-kWB-oQT-9KLUyN7G4WB_iSF2wI1MrEnMLclKL9XPy0zPz9DPzUlIr9DJKcnOUDXPTAnz9PfIA";
  var request = SigningRequestManager.from(uri,
      options: defaultSigningRequestEncodingOptions(
          nodeUrl: 'https://jungle.greymass.com'));

  print('desezialize\n' + request?.data?.toString());
}
