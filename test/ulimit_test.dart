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
import 'package:zxbase_vault/src/common/ulimit.dart';

void main() {
  group('Count tests', () {
    test('Undefined limit', () {
      ULimit limit = ULimit();
      expect(limit.value, equals(ULimit.undefined));
      expect(limit.ok(-1), equals(true));
      expect(limit.ok(1), equals(true));

      limit.set(-255);
      expect(limit.value, equals(ULimit.undefined));
    });

    test('Defined limit', () {
      ULimit limit = ULimit(value: 5);
      expect(limit.value, equals(5));
      expect(limit.ok(-1), equals(true));
      expect(limit.ok(1), equals(true));
      expect(limit.ok(10), equals(false));

      limit.set(85);
      expect(limit.value, equals(85));
    });
  });
}
