/// Minimal RFC 4180 CSV encoder/decoder for the on-device study CSVs
/// (plan §6.4). Dependency-free by design: the data volume is 8 rows per
/// session, and a hand-rolled codec keeps the column layout in one auditable
/// place shared by the device store, the admin export, and the scripts.
///
/// Dialect: comma-separated, `"` quoting with `""` escaping, LF line endings
/// (CRLF tolerated on decode), no multiline fields produced by this app
/// (newlines in values are quoted and decoded correctly anyway).
class CsvCodec {
  const CsvCodec._();

  /// Encodes a header plus rows into a complete CSV document ending with a
  /// trailing newline. `null` fields become empty strings.
  static String encode(List<String> header, Iterable<List<Object?>> rows) {
    final buffer = StringBuffer(encodeRow(header));
    for (final row in rows) {
      buffer
        ..write('\n')
        ..write(encodeRow(row));
    }
    buffer.write('\n');
    return buffer.toString();
  }

  /// Encodes one row. Fields containing `,`, `"`, `\n` or `\r` are quoted.
  static String encodeRow(List<Object?> fields) =>
      fields.map(_encodeField).join(',');

  static String _encodeField(Object? value) {
    final text = value?.toString() ?? '';
    if (text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  /// Decodes a CSV document into rows of string fields. Empty fields decode
  /// to `''` (the null/empty distinction is the caller's concern). Tolerates
  /// CRLF and a missing trailing newline.
  static List<List<String>> decode(String input) {
    final rows = <List<String>>[];
    final field = StringBuffer();
    var row = <String>[];
    var inQuotes = false;
    var i = 0;

    void endField() {
      row.add(field.toString());
      field.clear();
    }

    void endRow() {
      endField();
      rows.add(row);
      row = <String>[];
    }

    while (i < input.length) {
      final char = input[i];
      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            field.write('"');
            i += 2;
            continue;
          }
          inQuotes = false;
          i++;
          continue;
        }
        field.write(char);
        i++;
        continue;
      }
      if (char == '"') {
        inQuotes = true;
        i++;
        continue;
      }
      if (char == ',') {
        endField();
        i++;
        continue;
      }
      if (char == '\n') {
        endRow();
        i++;
        continue;
      }
      if (char == '\r') {
        i++; // tolerate CRLF
        continue;
      }
      field.write(char);
      i++;
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      endRow();
    }
    return rows;
  }
}
