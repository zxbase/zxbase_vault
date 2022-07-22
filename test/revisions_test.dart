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

import 'dart:io';
import 'package:test/test.dart';
import 'package:zxbase_vault/zxbase_vault.dart';
import 'package:zxbase_vault/src/doc/revisions.dart';

void main() {
  const path = './test_vault/async';
  const pwd = '12345678cC%';
  const id = 'VaultId';

  try {
    Directory(path).deleteSync(recursive: true);
  } catch (_) {}

  try {
    Directory(path).createSync(recursive: true);
  } catch (_) {}

  test('Setup a vault', () async {
    Vault vault = Vault(path: path);
    expect(vault.state, equals(VaultStateEnum.unknown));
    VaultStateEnum state = await vault.init();
    expect(state, equals(VaultStateEnum.empty));
    expect(vault.state, equals(VaultStateEnum.empty));
    expect(await vault.setup(pwd: pwd, id: id), equals(VaultStateEnum.ready));
    expect(vault.state, equals(VaultStateEnum.ready));
  });

  test('Export import revisions', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));
    var testDoc = {'test': 'test2', 'newKey': 'newContent2'};
    var doc = await vault.updateDoc(
        name: 'test2',
        content: testDoc,
        annotation: {'author': 'John', 'date': 7});
    expect(
        doc!.meta.revs.current.hash,
        equals(
            'c8292a031d451397bc5b1b89a4b1588c6d4a75dc4b091167ef83a5b01ffcd0d1'));
    expect(doc.meta.revs.revisions.length, equals(1));
    expect(doc.meta.revs.current.seq, equals(1));
    expect(doc.meta.revs.current.author, equals('John'));
    expect(doc.meta.revs.current.date, equals(7));
    expect(doc.meta.stats.keyCount, equals(2));
    expect(doc.meta.stats.size, equals(39));

    expect(vault.meta.stats.docCount, equals(1));
    expect(vault.meta.stats.keyCount, equals(2));
    expect(vault.meta.stats.size, equals(39));

    var js = doc.meta.revs.export();
    Revisions rev = Revisions.import(js);
    expect(rev.current.seq, equals(1));
    expect(
        rev.current.hash,
        equals(
            'c8292a031d451397bc5b1b89a4b1588c6d4a75dc4b091167ef83a5b01ffcd0d1'));
    expect(rev.current.export()['seq'], equals(1));
  });
}
