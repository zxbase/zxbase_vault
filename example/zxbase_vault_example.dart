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
