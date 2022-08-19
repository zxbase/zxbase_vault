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

import 'dart:async';
import 'dart:io';
import 'package:test/test.dart';
import 'package:zxbase_vault/zxbase_vault.dart';

void main() {
  const path = './test_vault/async';
  const pwd = '12345678cC%';
  const id = 'VaultId';
  const testDoc = {'test': 'test'};
  const testDoc1 = {'test': 'test1'};

  try {
    Directory(path).deleteSync(recursive: true);
  } catch (_) {}

  try {
    Directory(path).createSync(recursive: true);
  } catch (_) {}

  test('State of non existing vault', () async {
    Vault vault = Vault(path: 'bla');
    await vault.init();
    expect(vault.state, equals(VaultStateEnum.unknown));
  });

  test('Can not open empty vault', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(false));
  });

  test('Can not load the doc if vault is not ready', () async {
    Vault vault = Vault(path: path);
    runZonedGuarded(() {
      vault.getDoc(name: 'test');
    }, (e, s) {
      expect(e, isA<Exception>());
    });
  });

  test('Can not setup a vault with short password', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    runZonedGuarded(() {
      vault.setup(pwd: 'pwd', id: id);
    }, (e, s) {
      expect(e, isA<Exception>());
    });
  });

  test('Setup a vault', () async {
    Vault vault = Vault(path: path);
    expect(vault.state, equals(VaultStateEnum.unknown));
    VaultStateEnum state = await vault.init();
    expect(state, equals(VaultStateEnum.empty));
    expect(vault.state, equals(VaultStateEnum.empty));
    expect(await vault.setup(pwd: pwd, id: id), equals(VaultStateEnum.ready));
    expect(vault.state, equals(VaultStateEnum.ready));
  });

  test('Fail second setup', () async {
    Vault vault = Vault(path: path);
    expect(vault.state, equals(VaultStateEnum.unknown));
    await vault.init();
    runZonedGuarded(() {
      vault.setup(pwd: pwd, id: id);
    }, (e, s) {
      expect(e, isA<Exception>());
    });
  });

  test('Open vault', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));
    expect(vault.state, equals(VaultStateEnum.ready));
  });

  test('Can not open the vault with a wrong password', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: '87654321'), equals(false));
  });

  test('Update doc', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));
    final doc = await vault.updateDoc(
        name: 'test', content: testDoc, annotation: {'author': 'test'});
    expect(doc!.content, equals(testDoc));
    expect(doc.meta.stats.size, equals(15));
    expect(doc.meta.stats.keyCount, equals(1));
    expect(vault.meta.stats.docCount, equals(1));
    expect(vault.meta.stats.keyCount, equals(1));
    expect(vault.meta.stats.size, equals(15));
  });

  test('Get doc', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));
    final doc = await vault.getDoc(name: 'test');
    expect(doc!.content, equals({'test': 'test'}));
    expect(vault.meta.stats.docCount, equals(1));
    expect(vault.meta.stats.keyCount, equals(1));
    expect(vault.meta.stats.size, equals(15));
  });

  test('Can not load non existing doc', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));
    runZonedGuarded(() {
      vault.getDoc(name: 'none');
    }, (e, s) {
      expect(e, isA<Exception>());
    });
  });

  test('Can not save doc with no name', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));

    runZonedGuarded(() {
      vault.updateDoc(
          name: '', content: testDoc, annotation: {'author': 'test'});
    }, (e, s) {
      expect(e, isA<Exception>());
    });
  });

  test('Can not save doc with housekeeping name', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));

    runZonedGuarded(() {
      vault.updateDoc(
          name: '_meta', content: testDoc, annotation: {'author': 'test'});
    }, (e, s) {
      expect(e, isA<Exception>());
    });
  });

  test('Check metadata', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));
    final doc = await vault.getDoc(name: 'test');
    expect(
        doc!.meta.revs.current.hash,
        equals(
            '3d9a14153459ef617d86116297fb63d37948bffc9247bb969b63af29fe9aac6f'));
    expect(doc.meta.stats.keyCount, equals(1));
    expect(doc.meta.stats.size, equals(15));
  });

  test('Create new revision', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));
    final doc = await vault.updateDoc(
        name: 'test', content: testDoc1, annotation: {'author': 'test'});
    expect(doc!.meta.revs.current.seq, equals(2));
    expect(
        doc.meta.revs.current.hash,
        equals(
            'aedbee8c163070b2e39874f2b8a39dd05a778b66ec7d04d7bd87caab13ebeeac'));
    expect(doc.meta.stats.size, equals(16));
    expect(doc.meta.stats.keyCount, equals(1));
    expect(vault.meta.stats.docCount, equals(1));
    expect(vault.meta.stats.keyCount, equals(1));
    expect(vault.meta.stats.size, equals(16));
  });

  test('Check rev limit', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));
    final testDoc2 = {'test': 'test2', 'newKey': 'newContent'};
    final doc =
        await vault.updateDoc(name: 'test', content: testDoc2, annotation: {});
    expect(
        doc!.meta.revs.current.hash,
        equals(
            '1ad6d39ceca427997a11281491508a01b2ee355803c1f32ffd5c3a87d22d050a'));
    expect(doc.meta.revs.revisions.length, equals(2));
    expect(doc.meta.revs.current.seq, equals(3));
    expect(doc.meta.revs.current.author, equals(''));
    expect(
        doc.meta.revs.current.name,
        equals(
            '3-1ad6d39ceca427997a11281491508a01b2ee355803c1f32ffd5c3a87d22d050a'));
    expect(doc.meta.stats.keyCount, equals(2));
    expect(doc.meta.stats.size, equals(38));

    expect(vault.meta.stats.docCount, equals(1));
    expect(vault.meta.stats.keyCount, equals(2));
    expect(vault.meta.stats.size, equals(38));
  });

  test('Add another doc', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));
    final testDoc3 = {'test': 'test2', 'newKey': 'newContent2'};
    final doc = await vault.updateDoc(
        name: 'test2', content: testDoc3, annotation: {'author': 'test'});
    expect(
        doc!.meta.revs.current.hash,
        equals(
            'c8292a031d451397bc5b1b89a4b1588c6d4a75dc4b091167ef83a5b01ffcd0d1'));
    expect(doc.meta.revs.revisions.length, equals(1));
    expect(doc.meta.revs.current.seq, equals(1));
    expect(doc.meta.revs.current.author, equals('test'));
    expect(doc.meta.stats.keyCount, equals(2));
    expect(doc.meta.stats.size, equals(39));

    expect(vault.meta.stats.docCount, equals(2));
    expect(vault.meta.stats.keyCount, equals(4));
    expect(vault.meta.stats.size, equals(77));
  });
}
