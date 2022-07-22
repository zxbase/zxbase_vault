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

/// Vault metadata.

import 'dart:developer';
import 'dart:typed_data';
import 'package:zxbase_crypto/zxbase_crypto.dart';
import 'package:zxbase_vault/src/common/const.dart';
import 'package:zxbase_vault/src/common/utils.dart';
import 'package:zxbase_vault/src/doc.dart';
import 'package:zxbase_vault/src/vault/vault_limits.dart';
import 'package:zxbase_vault/src/vault/vault_stats.dart';

class VaultMeta {
  VaultMeta({required this.path, required this.key}) {
    docs = {};
    limits = VaultLimits();
    stats = VaultStats();
  }

  VaultMeta.load({required this.path, required this.key}) {
    log('Loading', name: _component);
    docs = {};
    IVData ivData = Utils.readIvData(path: path, name: meta);
    Map js = Utils.decryptMap(ivData: ivData, key: key);
    Map parsedDocs = js['docs'];
    parsedDocs.forEach((k, v) {
      docs[k] = true;
    });
    limits = VaultLimits.fromJson(js['limits']);
    stats = VaultStats.fromJson(js['stats']);
  }

  static const _component = 'vaultMeta'; // logging component
  late Map<String, bool> docs;
  late VaultLimits limits;
  late VaultStats stats;
  late String path;
  late Uint8List key;

  Map<String, dynamic> toJson() {
    return {'docs': docs, 'limits': limits, 'stats': stats};
  }

  addDoc({required Doc doc}) {
    docs[doc.name] = true;
    stats.docCount++;
    stats.keyCount += doc.meta.stats.keyCount;
    stats.size += doc.meta.stats.size;
  }

  // Recalculate stats from scratch.
  updateStats({required Map<String, Doc> vaultDocs}) {
    stats.docCount = vaultDocs.keys.length;
    stats.size = 0;
    stats.keyCount = 0;
    for (Doc doc in vaultDocs.values) {
      stats.size += doc.meta.stats.size;
      stats.keyCount += doc.meta.stats.keyCount;
    }
  }

  save() {
    log('Saving', name: _component);
    IVData ivData = Utils.encryptMap(key: key, map: toJson());
    Utils.writeIvData(path: path, name: meta, ivData: ivData);
  }
}
