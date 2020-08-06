import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';

import 'package:eosdart/eosdart.dart';

part 'request_signature.g.dart';

@JsonSerializable(explicitToJson: true)
class RequestSignature {
  @JsonKey(name: 'signer')
  String signer = '';

  @JsonKey(name: 'signature')
  String signature = '';

  RequestSignature();

  factory RequestSignature.fromJson(Map<String, dynamic> json) =>
      _$RequestSignatureFromJson(json);

  Map<String, dynamic> toJson() => _$RequestSignatureToJson(this);

  @override
  String toString() => this.toJson().toString();

  Uint8List toBinary(Type type) {
    var buffer = SerialBuffer(Uint8List(0));
    type.serialize(type, buffer, this.toJson());
    return buffer.asUint8List();
  }

  factory RequestSignature.fromBinary(Type type, dynamic data) {
    SerialBuffer buffer;
    if (buffer is SerialBuffer) {
      buffer = data;
    } else if (buffer is Uint8List) {
      buffer = SerialBuffer(data);
    } else {
      throw 'Data must be either Uint8List or SerialBuffer';
    }
    var deserializedData =
        Map<String, dynamic>.from(type.deserialize(type, buffer));
    return RequestSignature.fromJson(deserializedData);
  }

  static RequestSignature clone(String signer, String signature) {
    return RequestSignature()
      ..signer = signer
      ..signature = signature;
  }
}
