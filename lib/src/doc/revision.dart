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

/// Document revision.

import 'package:uuid/uuid.dart';

class Revision {
  Revision({
    required this.seq,
    required this.hash,
    required Map<String, dynamic> annotation,
  }) {
    fileId = const Uuid().v4();
    author = annotation['author'] ?? '';
    authorHash = annotation['authorHash'] ?? hash;
    authorVersion = annotation['authorVersion'] ?? '';
    date = annotation['date'] ?? DateTime.now().toUtc().millisecondsSinceEpoch;
  }

  Revision.fromJson(Map<String, dynamic> js) {
    seq = js['seq'] ?? -1;
    hash = js['hash'];
    fileId = js['fileId'] ?? '';
    date = js['date'];
    author = js['author'] ?? '';
    authorHash = js['authorHash'] ?? '';
    authorVersion = js['authorVersion'] ?? '';
  }

  int seq = 1;
  String hash = '';
  String fileId = '';
  int date = 0;

  // original metadata of the revision
  String author = '';
  String authorHash = '';
  String authorVersion = '';

  String get name {
    return '$seq-$hash';
  }

  Map<String, dynamic> toJson() {
    return {
      'seq': seq,
      'hash': hash,
      'fileId': fileId,
      'date': date,
      'author': author,
      'authorHash': authorHash,
      'authorVersion': authorVersion
    };
  }

  // Export properties relevant to remote peers.
  // Excludes file Id.
  Map<String, dynamic> export() {
    return {
      'seq': seq,
      'hash': hash,
      'date': date,
      'author': author,
      'authorHash': authorHash,
      'authorVersion': authorVersion
    };
  }
}
