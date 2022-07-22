[![Build](https://github.com/zxbase/zxbase_vault/actions/workflows/build.yml/badge.svg)](https://github.com/zxbase/zxbase_vault/actions/workflows/build.yml)
[![codecov](https://codecov.io/gh/zxbase/zxbase_vault/branch/main/graph/badge.svg?token=5GEZHD3E6W)](https://codecov.io/gh/zxbase/zxbase_vault)
[![Dependencies](https://github.com/zxbase/zxbase_vault/actions/workflows/dependencies.yml/badge.svg)](https://github.com/zxbase/zxbase_vault/actions/workflows/dependencies.yml)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Zxbase Vault is an encrypted document store implemented in pure Dart.

## Features

- Encryption
- Limits
- Stats

## Getting started

In _pubspec.yaml_:
```yaml
dependencies:
  zxbase_vault: ^1.0.0
```

In your code:
```
import 'package:zxbase_vault/zxbase_vault.dart';
```

## Usage
```
import 'package:zxbase_vault/zxbase_vault.dart';

void main() async {
  print('Zxbase Vault Example');

  String myPath = './sample_vault';
  String pwd = 'temporary';
  String id = 'myVault';

  /// Initialize / open the vault.
  Vault vault = Vault(path: myPath);
  VaultStateEnum state = await vault.init();
  if (state == VaultStateEnum.empty) {
    await vault.setup(pwd: pwd, id: id);
  } else {
    await vault.open(pwd: pwd);
  }

  /// Save document.
  final docName = 'myDoc';
  final myDoc = {'sample': 'sample'};
  await vault
      .updateDoc(name: docName, content: myDoc, annotation: {'author': 'me'});

  /// Load document.
  final readCopy = await vault.getDoc(name: docName);
  print(readCopy!.content);
}
```
