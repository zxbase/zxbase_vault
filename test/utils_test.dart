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

import 'package:test/test.dart';
import 'package:zxbase_vault/src/common/utils.dart';

void main() {
  test('sequence wrap around', () {
    int seq = 0x7fffffffffffffff;
    seq = Utils.incSeq(seq);
    expect(seq, equals(2));

    seq = 1;
    seq = Utils.incSeq(seq);
    expect(seq, equals(2));

    seq = 0x7ffffffffffffff;
    seq = Utils.incSeq(seq);
    expect(seq, equals(576460752303423488));
  });

  test('delete files', () {
    Utils.deleteIvData(path: 'path', name: 'name');
  });
}
