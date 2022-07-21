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

/// Doc metadata.

import 'dart:developer';
import 'dart:typed_data';
import 'package:zxbase_crypto/zxbase_crypto.dart';
import 'package:zxbase_vault/src/common/const.dart';
import 'package:zxbase_vault/src/common/utils.dart';
import 'package:zxbase_vault/src/doc/doc_limits.dart';
import 'package:zxbase_vault/src/doc/doc_stats.dart';
import 'package:zxbase_vault/src/doc/revisions.dart';

class DocMeta {
  DocMeta({required this.path, required this.key}) {
    limits = DocLimits();
  }

  DocMeta.load({required this.path, required this.key}) {
    log('Loading', name: _component);
    IVData ivData = Utils.readIvData(path: path, name: meta);
    Map js = Utils.decryptMap(ivData: ivData, key: key);
    limits = DocLimits.fromJson(js['limits']);
    revs = Revisions.fromJson(js['rev']);
    stats = DocStats.fromJson(js['stats']);
  }

  static const _component = 'docMeta'; // logging component
  late DocLimits limits;
  late DocStats stats;
  late Revisions revs;
  late String path;
  late Uint8List key;

  Map<String, dynamic> toJson() {
    return {'limits': limits, 'rev': revs, 'stats': stats};
  }

  save() {
    log('Saving', name: _component);
    IVData ivData = Utils.encryptMap(key: key, map: toJson());
    Utils.writeIvData(path: path, name: meta, ivData: ivData);
  }
}
