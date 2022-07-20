import 'package:zxbase_vault/src/common/utils.dart';
import 'package:test/test.dart';

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
    print('finished sequence test');
  });
}
