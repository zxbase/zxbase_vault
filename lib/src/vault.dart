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

/// Minimalistic encrypted document store.
/// All operations are executed sequentially.

// ignore_for_file: avoid_dynamic_calls

library;

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:zxbase_crypto/zxbase_crypto.dart';
import 'package:zxbase_vault/src/common/const.dart';
import 'package:zxbase_vault/src/common/utils.dart';
import 'package:zxbase_vault/src/doc.dart';
import 'package:zxbase_vault/src/vault/vault_meta.dart';

enum VaultStateEnum { unknown, empty, seeded, ready }

class Vault {
  Vault({required this.path, this.encrypted = true}) {
    _orderedOpsController.stream
        .asyncMap((future) async => await future)
        .listen((_) {}, cancelOnError: false);
  }

  /// Queueing mechanisms. All ops are queued and executed sequentially.
  final _orderedOpsController = StreamController<Future>();
  Future _queueOp(Future op) {
    _orderedOpsController.add(op);
    return op;
  }

  static const _component = 'vault'; // logging _component
  final int _version = 4;
  bool encrypted = true;

  VaultStateEnum _state = VaultStateEnum.unknown;
  VaultStateEnum get state => _state;

  final String path;
  Uint8List _key = Uint8List.fromList([]); // vault encryption key

  late VaultMeta _meta;
  VaultMeta get meta => _meta;

  final Map<String, Doc> _docs = {};
  Map<String, Doc> get docs => _docs;

  VaultStateEnum _initSync() {
    if (!Directory(path).existsSync()) {
      log('Vault folder doesn\'t exist: $path', name: _component);
      return state;
    }
    _state = VaultStateEnum.empty;
    if (File('$path/$seed').existsSync()) {
      _state = VaultStateEnum.seeded;
    }
    return state;
  }

  VaultStateEnum _setupSync({required String pwd, required String id}) {
    if (state != VaultStateEnum.empty) {
      throw Exception('Incorrect vault state for setup.');
    }

    Map seedDoc;
    if (encrypted) {
      Utils.checkPassword(pwd);

      Uint8List salt = Password.generateSalt();
      Uint8List derivedKey = Password.derive256BitKey(pwd: pwd, salt: salt);
      _key = SKCrypto.generate256BitKey();
      IVData encryptedKey = SKCrypto.encryptSync(buffer: _key, key: derivedKey);

      seedDoc = {
        'version': _version,
        'id': id,
        'salt': base64Url.encode(salt),
        'iv': base64Url.encode(encryptedKey.iv),
        'data': base64Url.encode(encryptedKey.data)
      };
    } else {
      seedDoc = {'version': _version, 'id': id};
    }

    File('$path/$seed').writeAsStringSync(json.encode(seedDoc));

    _meta = VaultMeta(path: path, key: _key, encrypted: encrypted);
    _meta.save();

    _state = VaultStateEnum.ready;
    return _state;
  }

  bool _openSync({required String pwd}) {
    final seedFile = File('$path/$seed');
    if (!seedFile.existsSync()) {
      log('No seed doc', name: _component);
      return false;
    }

    try {
      Map<String, dynamic> seedDoc = json.decode(seedFile.readAsStringSync());

      if (encrypted) {
        Uint8List salt =
            Uint8List.fromList(base64Url.decode(seedDoc['salt']).cast<int>());
        Uint8List iv =
            Uint8List.fromList(base64Url.decode(seedDoc['iv']).cast<int>());
        Uint8List data =
            Uint8List.fromList(base64Url.decode(seedDoc['data']).cast<int>());

        var derivedKey = Password.derive256BitKey(pwd: pwd, salt: salt);
        _key = SKCrypto.decryptSync(iv: iv, buffer: data, key: derivedKey);
      }
    } catch (e) {
      log('Can not open $e', name: _component);
      return false;
    }

    _meta = VaultMeta.load(path: path, key: _key, encrypted: encrypted);
    for (String docName in meta.docs.keys) {
      docs[docName] =
          Doc(path: path, name: docName, key: _key, encrypted: encrypted);
    }
    _state = VaultStateEnum.ready;
    return true;
  }

  /// Check before any operation on a document.
  void _check(String docName) {
    if (state != VaultStateEnum.ready) {
      throw Exception('Vault is not ready.');
    }
    Utils.checkDocName(docName: docName);
  }

  Doc? _updateDocSync(
      {required String name,
      required Map<String, dynamic> content,
      required Map<String, dynamic> annotation}) {
    String contentString = json.encode(content);
    if (!docs.containsKey(name)) {
      // new doc - check vault limits
      if (!meta.limits.docCount.ok(docs.length + 1)) {
        return null;
      }
      if (!meta.limits.size.ok(contentString.length)) {
        return null;
      }
      if (!meta.limits.keyCount.ok(content.keys.length)) {
        return null;
      }
      docs[name] = Doc.firstRevision(
          content: content,
          path: path,
          name: name,
          key: _key,
          annotation: annotation,
          encrypted: encrypted);
      meta.addDoc(doc: docs[name]!);
    } else {
      // existing doc - check vault and doc limits
      if (!docs[name]!.meta.limits.size.ok(contentString.length)) {
        return null;
      }
      if (!docs[name]!.meta.limits.keyCount.ok(content.keys.length)) {
        return null;
      }
      int sizeDiff = contentString.length - _docs[name]!.meta.stats.size;
      if (!meta.limits.size.ok(meta.stats.size + sizeDiff)) {
        return null;
      }
      int keyCountDiff = content.keys.length - _docs[name]!.meta.stats.keyCount;
      if (!meta.limits.keyCount.ok(meta.stats.keyCount + keyCountDiff)) {
        return null;
      }
      docs[name]!.createNewRevision(content: content, annotation: annotation);
      meta.updateStats(vaultDocs: docs);
    }
    meta.save();
    return docs[name]!;
  }

  /// Limits //////////////////////////////////////////////////////////
  bool _setDocSizeLimitSync({required String name, required int limit}) {
    if (!docs.containsKey(name)) {
      return false;
    }
    log('Update key count limit for $name to $limit', name: _component);
    docs[name]!.setSizeLimit(limit: limit);
    return true;
  }

  bool _setDocKeyCountLimitSync({required String name, required int limit}) {
    if (!docs.containsKey(name)) {
      return false;
    }
    log('Update key count limit for $name to $limit', name: _component);
    docs[name]!.setKeyCountLimit(limit: limit);
    return true;
  }

  void _setSizeLimitSync({required int limit}) {
    meta.limits.size.set(limit);
    meta.save();
  }

  void _setKeyCountLimitSync({required int limit}) {
    meta.limits.keyCount.set(limit);
    meta.save();
  }

  void _setDocCountLimitSync({required int limit}) {
    meta.limits.docCount.set(limit);
    meta.save();
  }

  /// Async layer to create separate zone. ////////////////////////////
  /// Don't use async function in the body to avoid preemption.
  Future<VaultStateEnum> _init() async {
    return _initSync();
  }

  Future<VaultStateEnum> _setup(
      {required String pwd, required String id}) async {
    return _setupSync(pwd: pwd, id: id);
  }

  Future<bool> _open({required String pwd}) async {
    return _openSync(pwd: pwd);
  }

  Future<Doc?> _getDoc({required String name}) async {
    _check(name);
    return docs[name];
  }

  Future<Doc?> _updateDoc(
      {required String name,
      required Map<String, dynamic> content,
      required Map<String, dynamic> annotation}) async {
    _check(name);
    return _updateDocSync(name: name, content: content, annotation: annotation);
  }

  Future<bool> _setDocKeyCountLimit(
      {required String name, required int limit}) async {
    return _setDocKeyCountLimitSync(name: name, limit: limit);
  }

  Future<bool> _setDocSizeLimit(
      {required String name, required int limit}) async {
    return _setDocSizeLimitSync(name: name, limit: limit);
  }

  Future<void> _setKeyCountLimit({required int limit}) async {
    return _setKeyCountLimitSync(limit: limit);
  }

  Future<void> _setSizeLimit({required int limit}) async {
    return _setSizeLimitSync(limit: limit);
  }

  Future<void> _setDocCountLimit({required int limit}) async {
    return _setDocCountLimitSync(limit: limit);
  }

  /// API /////////////////////////////////////////////////////////////
  Future<VaultStateEnum> init() async {
    return await _queueOp(_init());
  }

  Future<VaultStateEnum> setup(
      {required String pwd, required String id}) async {
    return await _queueOp(_setup(pwd: pwd, id: id));
  }

  Future<bool> open({required String pwd}) async {
    return await _queueOp(_open(pwd: pwd));
  }

  Future<Doc?> getDoc({required String name}) async {
    return await _queueOp(_getDoc(name: name));
  }

  Future<Doc?> updateDoc(
      {required String name,
      required Map<String, dynamic> content,
      required Map<String, dynamic> annotation}) async {
    return await _queueOp(
        _updateDoc(name: name, content: content, annotation: annotation));
  }

  Future<bool> setDocKeyCountLimit(
      {required String name, required int limit}) async {
    return await _queueOp(_setDocKeyCountLimit(name: name, limit: limit));
  }

  Future<bool> setDocSizeLimit(
      {required String name, required int limit}) async {
    return await _queueOp(_setDocSizeLimit(name: name, limit: limit));
  }

  Future<void> setKeyCountLimit({required int limit}) async {
    return await _queueOp(_setKeyCountLimit(limit: limit));
  }

  Future<void> setSizeLimit({required int limit}) async {
    return await _queueOp(_setSizeLimit(limit: limit));
  }

  Future<void> setDocCountLimit({required int limit}) async {
    return await _queueOp(_setDocCountLimit(limit: limit));
  }
}
