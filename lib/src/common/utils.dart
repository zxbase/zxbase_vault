// Copyright (C) 2022 Zxbase, LLC. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Miscellaneous utils.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:zxbase_crypto/zxbase_crypto.dart';

class Utils {
  /// Ensure sequence is always positive and equals 1 only
  /// for the first revision.
  static int incSeq(int seq) {
    return (seq == 0x7fffffffffffffff) ? 2 : seq + 1;
  }

  static IVData encryptMap(
      {required Map<String, dynamic> map, required Uint8List key}) {
    Uint8List data = Uint8List.fromList(utf8.encode(json.encode(map)));
    return SKCrypto.encryptSync(buffer: data, key: key);
  }

  static Map<String, dynamic> decryptMap(
      {required IVData ivData, required Uint8List key}) {
    Uint8List res =
        SKCrypto.decryptSync(iv: ivData.iv, buffer: ivData.data, key: key);
    return json.decode(utf8.decode(res));
  }

  static void writeIvData(
      {required String path, required String name, required IVData ivData}) {
    Directory(path).createSync();
    File('$path/$name.iv').writeAsBytesSync(ivData.iv, flush: true);
    File('$path/$name.dat').writeAsBytesSync(ivData.data, flush: true);
  }

  static IVData readIvData({required String path, required String name}) {
    final ivFile = File('$path/$name.iv');
    final datFile = File('$path/$name.dat');
    Uint8List iv = ivFile.readAsBytesSync();
    Uint8List data = datFile.readAsBytesSync();
    return IVData(iv: iv, data: data);
  }

  static void deleteIvData({required String path, required String name}) {
    File('$path/$name.iv').deleteSync();
    File('$path/$name.dat').deleteSync();
  }

  static checkDocName({required String docName}) {
    if (docName.length < 3 || docName.length > 32) {
      throw Exception('Invalid doc name length.');
    }

    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(docName)) {
      throw Exception('Invalid doc name format.');
    }
  }

  static checkPassword(String pwd) {
    if (pwd.length < 8 || pwd.length > 32) {
      throw Exception('Password length ${pwd.length}.');
    }
  }
}
