import 'package:flutter_test/flutter_test.dart';
import 'package:keti/domain/study/csv_codec.dart';

void main() {
  group('CsvCodec.encodeRow', () {
    test('plain fields join with commas', () {
      expect(CsvCodec.encodeRow(['a', 'b', 'c']), 'a,b,c');
    });

    test('null becomes an empty field', () {
      expect(CsvCodec.encodeRow(['a', null, 'c']), 'a,,c');
    });

    test('fields containing commas are quoted', () {
      expect(CsvCodec.encodeRow(['a,b', 'c']), '"a,b",c');
    });

    test('quotes are doubled inside quoted fields', () {
      expect(CsvCodec.encodeRow(['she said "hi"', 'x']),
          '"she said ""hi""",x');
    });

    test('fields containing newlines are quoted', () {
      expect(CsvCodec.encodeRow(['a\nb', 'c']), '"a\nb",c');
    });

    test('numbers and booleans stringify', () {
      expect(CsvCodec.encodeRow([42, true, 3.5]), '42,true,3.5');
    });
  });

  group('CsvCodec.decode', () {
    test('round-trips quoted and plain fields', () {
      final rows = CsvCodec.decode('a,"b,c","d""e"\n1,2,3\n');
      expect(rows, [
        ['a', 'b,c', 'd"e'],
        ['1', '2', '3'],
      ]);
    });

    test('tolerates CRLF line endings', () {
      final rows = CsvCodec.decode('a,b\r\nc,d\r\n');
      expect(rows, [
        ['a', 'b'],
        ['c', 'd'],
      ]);
    });

    test('tolerates missing trailing newline', () {
      expect(CsvCodec.decode('a,b'), [
        ['a', 'b']
      ]);
    });

    test('empty fields decode as empty strings', () {
      expect(CsvCodec.decode('a,,c\n'), [
        ['a', '', 'c']
      ]);
    });

    test('empty input decodes to no rows', () {
      expect(CsvCodec.decode(''), isEmpty);
    });

    test('quoted newline stays inside the field', () {
      final rows = CsvCodec.decode('"a\nb",c\n');
      expect(rows, [
        ['a\nb', 'c']
      ]);
    });
  });

  group('CsvCodec.encode + decode round-trip', () {
    test('header and rows survive intact', () {
      final header = ['eventId', 'note', 'count'];
      final rows = [
        ['reminder01', 'plain', 8],
        ['reminder02', 'has, comma', null],
        ['reminder03', 'has "quote"', 0],
      ];
      final text = CsvCodec.encode(header, rows);
      final decoded = CsvCodec.decode(text);
      expect(decoded.first, header);
      expect(decoded[1], ['reminder01', 'plain', '8']);
      expect(decoded[2], ['reminder02', 'has, comma', '']);
      expect(decoded[3], ['reminder03', 'has "quote"', '0']);
    });
  });
}
