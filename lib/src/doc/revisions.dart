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

/// Revisions (history).

import 'dart:convert';
import 'package:zxbase_vault/src/common/const.dart';
import 'package:zxbase_vault/src/common/utils.dart';
import 'package:zxbase_vault/src/doc/revision.dart';

class Revisions {
  Revisions(
      {required String firstHash, required Map<String, dynamic> annotation}) {
    revisions.add(Revision(seq: seq, hash: firstHash, annotation: annotation));
  }

  Revisions.fromJson(Map<String, dynamic> js) {
    limit = js['limit'];
    List parsedRevs = js['revisions'];
    for (Map<String, dynamic> v in parsedRevs) {
      revisions.add(Revision.fromJson(v));
    }
    seq = current.seq;
  }

  Revisions.import(Map<String, dynamic> js) {
    limit = js['limit'];
    List parsedRevs = json.decode(js['revisions']);
    for (Map<String, dynamic> v in parsedRevs) {
      revisions.add(Revision.fromJson(v));
    }
    seq = current.seq;
  }

  int seq = 1;
  int limit = revsLimit;
  List<Revision> revisions = [];

  Revision get current {
    return revisions.last;
  }

  /// Doesn't encode revisions, it is done by map encryption.
  Map<String, dynamic> toJson() {
    return {'seq': seq, 'limit': limit, 'revisions': revisions};
  }

  /// Use when sending over the network.
  Map<String, dynamic> export() {
    return {'seq': seq, 'limit': limit, 'revisions': json.encode(revisions)};
  }

  create({required String hash, required Map<String, dynamic> annotation}) {
    seq = Utils.incSeq(seq);
    revisions.add(Revision(seq: seq, hash: hash, annotation: annotation));
  }

  bool get needToPrune {
    return (revisions.length > limit);
  }

  prune() {
    revisions.removeAt(0);
  }
}
