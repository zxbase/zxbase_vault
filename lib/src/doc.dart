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

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:zxbase_crypto/zxbase_crypto.dart';
import 'package:zxbase_vault/src/common/utils.dart';
import 'package:zxbase_vault/src/doc/doc_meta.dart';
import 'package:zxbase_vault/src/doc/doc_stats.dart';
import 'package:zxbase_vault/src/doc/revisions.dart';

class Doc {
  /// Load document from storage.
  Doc({required this.path, required this.name, required this.key}) {
    docPath = '$path/$name';
    meta = DocMeta.load(path: docPath, key: key);
    content = Utils.decryptMap(
        ivData: Utils.readIvData(path: docPath, name: meta.revs.current.fileId),
        key: key);
  }

  /// Create first revision of the document.
  Doc.firstRevision(
      {required this.content,
      required this.path,
      required this.name,
      required this.key,
      required Map<String, dynamic> annotation}) {
    docPath = '$path/$name';
    meta = DocMeta(path: docPath, key: key);

    String contentString = json.encode(content);
    meta.stats =
        DocStats(size: contentString.length, keyCount: content.keys.length);
    String hash = Hash.hash3_256(contentString);
    meta.revs = Revisions(firstHash: hash, annotation: annotation);
    encryptedContent = Utils.encryptMap(key: key, map: content);
    log('Saving first revision $name', name: _component);
    save();
  }

  createNewRevision(
      {required Map<String, dynamic> content,
      required Map<String, dynamic> annotation}) {
    String contentString = json.encode(content);
    String hash = Hash.hash3_256(contentString);
    meta.revs.create(hash: hash, annotation: annotation);

    this.content = content;
    encryptedContent = Utils.encryptMap(key: key, map: content);
    saveContent();

    meta.stats.size = contentString.length;
    meta.stats.keyCount = content.keys.length;

    if (meta.revs.needToPrune) {
      Utils.deleteIvData(path: docPath, name: meta.revs.revisions.first.fileId);
      meta.revs.prune();
    }
    meta.save();
  }

  setSizeLimit({required int limit}) {
    meta.limits.size.set(limit);
    meta.save();
  }

  setKeyCountLimit({required int limit}) {
    meta.limits.keyCount.set(limit);
    meta.save();
  }

  saveContent() {
    Utils.writeIvData(
        path: docPath,
        name: meta.revs.current.fileId,
        ivData: encryptedContent);
  }

  save() {
    Directory(docPath).createSync();
    saveContent();
    meta.save();
  }

  static const _component = 'doc'; // logging _component

  String path;
  String name;
  Uint8List key;
  late DocMeta meta;

  late String docPath;
  late Map<String, dynamic> content;
  late IVData encryptedContent;
}
