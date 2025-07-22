import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

void main() {
  test('Core models can be imported', () {
    // Test that core models are accessible
    expect(User, isNotNull);
    expect(Order, isNotNull);
    expect(Vendor, isNotNull);
    expect(MenuItem, isNotNull);
  });
}
