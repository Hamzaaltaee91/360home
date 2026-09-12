import 'dart:typed_data';

import 'package:dabberli/utils/image_compressor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageCompressor', () {
    test('returns empty input unchanged', () async {
      final result = await ImageCompressor.compress(Uint8List(0));
      expect(result, isEmpty);
    });

    test('returns original bytes for invalid image data', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final result = await ImageCompressor.compress(bytes);
      expect(result, equals(bytes));
    });

    test('exposes sensible defaults', () {
      expect(ImageCompressor.defaultMaxDimension, greaterThan(0));
      expect(ImageCompressor.defaultQuality, inInclusiveRange(1, 100));
    });
  });
}
