import 'package:dabberli/models/pagination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaginatedResult', () {
    test('fromItems infers hasMore when the page is full', () {
      final page = PaginatedResult.fromItems(
        [1, 2, 3],
        offset: 0,
        limit: 3,
      );

      expect(page.items, [1, 2, 3]);
      expect(page.hasMore, isTrue);
      expect(page.nextOffset, 3);
    });

    test('fromItems infers no more when the page is short', () {
      final page = PaginatedResult.fromItems(
        [1, 2],
        offset: 0,
        limit: 3,
      );

      expect(page.hasMore, isFalse);
      expect(page.nextOffset, 2);
    });

    test('empty has no items and no more pages', () {
      final page = PaginatedResult<int>.empty(offset: 10, limit: 5);

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
      expect(page.nextOffset, 10);
    });

    test('nextOffset advances by the number of items returned', () {
      final page = PaginatedResult.fromItems(
        [1, 2, 3, 4],
        offset: 20,
        limit: 5,
      );

      expect(page.nextOffset, 24);
    });
  });
}
