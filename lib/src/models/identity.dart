import 'dart:typed_data';

import 'package:dart_esr/src/models/authorization.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:eosdart/eosdart.dart' as ser;

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

  Uint8List toBinary(ser.Type type) {
    var buffer = ser.SerialBuffer(Uint8List(0));
    type.serialize(type, buffer, this.toJson());
    return buffer.asUint8List();
  }
}
