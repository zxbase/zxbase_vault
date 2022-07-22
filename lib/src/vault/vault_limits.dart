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

import 'package:zxbase_vault/src/common/ulimit.dart';

class VaultLimits {
  VaultLimits() {
    size = ULimit();
    keyCount = ULimit();
    docCount = ULimit();
  }

  VaultLimits.fromJson(Map<String, dynamic> js) {
    size = ULimit(value: js['size']);
    keyCount = ULimit(value: js['keyCount']);
    docCount = ULimit(value: js['docCount']);
  }

  late ULimit size;
  late ULimit keyCount;
  late ULimit docCount;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'size': size.value,
      'keyCount': keyCount.value,
      'docCount': docCount.value,
    };
  }
}
