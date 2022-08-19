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
import 'package:zxbase_vault/zxbase_vault.dart';

void main() {
  const path = './test_vault/async';
  const pwd = '1@34שלום';
  const id = 'Паляниця';
  const testDoc = {'タイプ': 'वीर्य'};

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

  test('Open vault', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));
    expect(vault.state, equals(VaultStateEnum.ready));
  });

  test('Update doc', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));
    final doc = await vault.updateDoc(
        name: 'noti18n',
        content: testDoc,
        annotation: {'höfundur': 'ผู้เขียน'});
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
    final doc = await vault.getDoc(name: 'noti18n');
    expect(doc!.content, equals(testDoc));
    expect(vault.meta.stats.docCount, equals(1));
    expect(vault.meta.stats.keyCount, equals(1));
    expect(vault.meta.stats.size, equals(15));
  });

  test('Check metadata', () async {
    Vault vault = Vault(path: path);
    await vault.init();
    expect(await vault.open(pwd: pwd), equals(true));
    final doc = await vault.getDoc(name: 'noti18n');
    expect(
        doc!.meta.revs.current.hash,
        equals(
            '961f9e0f2f602c931644b0f0a2794f0c43bb84c270f8a716174ccbb98bdba509'));
    expect(doc.meta.stats.keyCount, equals(1));
    expect(doc.meta.stats.size, equals(15));
  });
}
