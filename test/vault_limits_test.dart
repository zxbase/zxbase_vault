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

// ignore_for_file: avoid_dynamic_calls

import 'dart:io';
import 'package:test/test.dart';
import 'package:zxbase_vault/src/common/ulimit.dart';
import 'package:zxbase_vault/src/vault/vault_meta.dart';
import 'package:zxbase_vault/zxbase_vault.dart';

// helper to dump meta file
void printMeta(VaultMeta meta) {
  // print(json.encode(meta.toJson()));
}

void main() {
  const path = './test_vault/limits';
  const pwd = '12345678cC%';
  const id = 'VaultId';

  try {
    Directory(path).deleteSync(recursive: true);
  } catch (_) {}

  try {
    Directory(path).createSync(recursive: true);
  } catch (_) {}

  test('Setup vault', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.setup(pwd: pwd, id: id), equals(VaultStateEnum.ready));
  });

  test('Update doc and check metadata', () async {
    Vault vault = Vault(path: path);
    await vault.init();

    expect(await vault.open(pwd: pwd), equals(true));

    var testDoc = {'test': 'test'};
    Doc? doc = await vault.updateDoc(
        name: 'test', content: testDoc, annotation: {'author': 'test'});
    expect(doc!.meta.stats.keyCount, equals(1));
    expect(doc.meta.stats.size, equals(15));

    expect(vault.meta.stats.docCount, equals(1));
    expect(vault.meta.stats.keyCount, equals(1));
    expect(vault.meta.stats.size, equals(15));

    printMeta(vault.meta);
  });

  test('Vault stats are still valid after restart', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));

    expect(vault.meta.stats.docCount, equals(1));
    expect(vault.meta.stats.keyCount, equals(1));
    expect(vault.meta.stats.size, equals(15));
  });

  test('Set doc size limit', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));

    var rv = await vault.setDocSizeLimit(name: 'test', limit: 20);
    expect(rv, equals(true));

    var testDoc = {'test': 'test123456'};
    var doc = await vault.updateDoc(
        name: 'test', content: testDoc, annotation: {'author': 'test'});
    expect(doc, equals(null));
  });

  test('Doc size limit still applies after restart', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));

    var testDoc = {'test': 'test123456'};
    expect(
        await vault.updateDoc(
            name: 'test', content: testDoc, annotation: {'author': 'test'}),
        equals(null));
  });

  test('Can not exceed global size limit', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));

    await vault.setSizeLimit(limit: 250);

    var testDoc = {
      'test':
          'We have to get the size of the doc bigger than 300 in order to exceed the limit',
      'test1':
          'We have to get the size of the doc bigger than 300 in order to exceed the limit',
      'test2':
          'We have to get the size of the doc bigger than 300 in order to exceed the limit'
    };
    expect(
        await vault.updateDoc(
            name: 'test1', content: testDoc, annotation: {'author': 'test'}),
        equals(null));
  });

  test('Global size limit still applied after restart', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));

    var testDoc = {
      'test':
          'We have to get the size of the doc bigger than 300 in order to exceed the limit',
      'test1':
          'We have to get the size of the doc bigger than 300 in order to exceed the limit',
      'test2':
          'We have to get the size of the doc bigger than 300 in order to exceed the limit'
    };
    expect(
        await vault.updateDoc(
            name: 'test1', content: testDoc, annotation: {'author': 'test'}),
        equals(null));
  });

  test('Set doc count limit', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));

    // dropping size imits
    await vault.setSizeLimit(limit: ULimit.undefined);
    // expect 1 doc to exist at this point
    expect(vault.meta.stats.docCount, equals(1));
    // set docs limit to 1
    await vault.setDocCountLimit(limit: 1);

    var testDoc = {'test': 'test'};
    expect(
        await vault.updateDoc(
            name: 'test2', content: testDoc, annotation: {'author': 'test'}),
        equals(null));
  });

  test('Doc count limit works after restart', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));
    var testDoc = {'test': 'test'};
    expect(
        await vault.updateDoc(
            name: 'test2', content: testDoc, annotation: {'author': 'test'}),
        equals(null));
  });

  test('Doc count limit allows to write the same doc', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));
    var testDoc = {'test': 'test'};
    Doc? doc = await vault.updateDoc(
        name: 'test', content: testDoc, annotation: {'author': 'test'});
    expect(doc!.name, equals('test'));
  });

  test('Set key count limit', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));

    await vault.setKeyCountLimit(limit: 1);
    bool rv = await vault.setDocKeyCountLimit(name: 'test', limit: 2);
    expect(rv, equals(true));
    rv = await vault.setDocSizeLimit(name: 'test', limit: ULimit.undefined);
    expect(rv, equals(true));

    var testDoc = {'test': 'test', 'test2': 'test2'};
    expect(
        await vault.updateDoc(
            name: 'test', content: testDoc, annotation: {'author': 'test'}),
        equals(null));
  });

  test('Doc key count limit survives restart', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));
    var testDoc = {'test': 'test', 'test2': 'test2', 'test3': 'test3'};
    expect(
        await vault.updateDoc(
            name: 'test', content: testDoc, annotation: {'author': 'test'}),
        equals(null));
  });

  test('Key count limit works for the new doc as well', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));
    var testDoc = {'test': 'test', 'test2': 'test2'};
    expect(
        await vault.updateDoc(
            name: 'test2', content: testDoc, annotation: {'author': 'test'}),
        equals(null));
  });
}
