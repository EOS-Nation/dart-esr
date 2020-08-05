import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:dart_esr/src/models/request_signature.dart';

SigningRequestEncodingOptions defaultSigningRequestEncodingOptions =
    SigningRequestEncodingOptions(
        textEncoder: DefaultTextEncoder(),
        textDecoder: DefaultTextDecoder(),
        zlib: DefaultZlibProvider(),
        abiProvider: DefaultAbiProvider());

class DefaultZlibProvider implements ZlibProvider {
  @override
  Uint8List deflateRaw(Uint8List data) {
    return ZLibEncoder().encode(data, raw: true);
  }

  @override
  Uint8List inflateRaw(Uint8List data) {
    return ZLibDecoder().decodeBytes(data, raw: true);
  }
}

class DefaultAbiProvider implements AbiProvider {
  @override
  Future getAbi(String account) {
    // TODO: DefaultAbiProvider.getAbi 'not implemented yet'
    throw UnimplementedError();
  }
}

class DefaultTextEncoder implements TextEncoder {
  @override
  Uint8List encode(String input) {
    return utf8.encode(input);
  }
}

class DefaultTextDecoder implements TextDecoder {
  @override
  String decode(Uint8List input) {
    return utf8.decode(input);
  }
}

class SigningRequestEncodingOptions {
  /** UTF-8 text encoder, required when using node.js. */
  final TextEncoder textEncoder;
  /** UTF-8 text decoder, required when using node.js. */
  final TextDecoder textDecoder;
  /** Optional zlib, if provided the request will be compressed when encoding. */
  final ZlibProvider zlib;
  /** Abi provider, required if the arguments contain un-encoded actions. */
  final AbiProvider abiProvider;
  /** Optional signature provider, will be used to create a request signature if provided. */
  final SignatureProvider signatureProvider;
  const SigningRequestEncodingOptions(
      {this.textEncoder,
      this.textDecoder,
      this.zlib,
      this.abiProvider,
      this.signatureProvider});
}

abstract class TextEncoder {
  /**
     * Returns the result of running UTF-8's encoder.
     */
  Uint8List encode(String input);
}

/** A decoder for a specific method, that is a specific character encoding, like utf-8, iso-8859-2, koi8, cp1261, gbk, etc. A decoder takes a stream of bytes as input and emits a stream of code points. For a more scalable, non-native library, see StringView – a C-like representation of strings based on typed arrays. */
abstract class TextDecoder {
  /**
   * Returns the result of running encoding's decoder. The method can be invoked zero or more times with options's stream set to true, and then once without options's stream (or set to false), to process a fragmented stream. If the invocation without options's stream (or set to false) has no input, it's clearest to omit both arguments.
   */
  String decode(Uint8List input);
}

/** Interface that should be implemented by zlib implementations. */
abstract class ZlibProvider {
  /** Deflate data w/o adding zlib header. */
  Uint8List deflateRaw(Uint8List data);
  /** Inflate data w/o requiring zlib header. */
  Uint8List inflateRaw(Uint8List data);
}

/** Interface that should be implemented by abi providers. */
abstract class AbiProvider {
  /**
     * Return a promise that resolves to an abi object for the given account name,
     * e.g. the result of a rpc call to chain/get_abi.
     */
  Future<dynamic> getAbi(String account);
}

/** Interface that should be implemented by signature providers. */
abstract class SignatureProvider {
  /** Sign 32-byte hex-encoded message and return signer name and signature string. */
  RequestSignature sign(String message);
}
