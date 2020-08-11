import 'dart:typed_data';

import 'package:dart_esr/src/models/authorization.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:eosdart/eosdart.dart' as eosDart;

part 'identity.g.dart';

@JsonSerializable(explicitToJson: true)
class Identity {
  @JsonKey(name: 'permission')
  Authorization authorization;

  Identity();

  factory Identity.fromJson(Map<String, dynamic> json) =>
      _$IdentityFromJson(json);

  Map<String, dynamic> toJson() => _$IdentityToJson(this);

  @override
  String toString() => this.toJson().toString();

  Uint8List toBinary(eosDart.Type type) {
    var buffer = eosDart.SerialBuffer(Uint8List(0));
    type.serialize(type, buffer, this.toJson());
    return buffer.asUint8List();
  }

  factory Identity.fromBinary(eosDart.Type type, dynamic data) {
    eosDart.SerialBuffer buffer;
    if (data is eosDart.SerialBuffer) {
      buffer = data;
    } else if (data is Uint8List) {
      buffer = eosDart.SerialBuffer(data);
    } else {
      throw 'Data must be either Uint8List or SerialBuffer';
    }
    var deserializedData =
        Map<String, dynamic>.from(type.deserialize(type, buffer));
    return Identity.fromJson(deserializedData);
  }
}
