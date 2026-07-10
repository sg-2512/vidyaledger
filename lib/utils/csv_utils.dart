class CsvRecord {
  const CsvRecord({required this.rowNumber, required this.values});

  final int rowNumber;
  final Map<String, String> values;

  String firstValue(Iterable<String> candidateHeaders) {
    for (final header in candidateHeaders) {
      final value = values[normalizeCsvHeader(header)];
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  bool get isBlank => values.values.every((value) => value.trim().isEmpty);
}

List<List<String>> parseCsvRows(String input) {
  final rows = <List<String>>[];
  final row = <String>[];
  final cell = StringBuffer();
  var quoted = false;

  void finishCell() {
    row.add(cell.toString().trim());
    cell.clear();
  }

  void finishRow() {
    finishCell();
    if (row.any((value) => value.trim().isNotEmpty)) {
      rows.add(List<String>.from(row));
    }
    row.clear();
  }

  for (var index = 0; index < input.length; index += 1) {
    final char = input[index];
    if (quoted) {
      if (char == '"') {
        final hasEscapedQuote =
            index + 1 < input.length && input[index + 1] == '"';
        if (hasEscapedQuote) {
          cell.write('"');
          index += 1;
        } else {
          quoted = false;
        }
      } else {
        cell.write(char);
      }
      continue;
    }

    if (char == '"') {
      if (cell.toString().trim().isEmpty) {
        quoted = true;
      } else {
        cell.write(char);
      }
      continue;
    }
    if (char == ',') {
      finishCell();
      continue;
    }
    if (char == '\n') {
      finishRow();
      continue;
    }
    if (char == '\r') {
      if (index + 1 < input.length && input[index + 1] == '\n') continue;
      finishRow();
      continue;
    }
    cell.write(char);
  }

  if (quoted || cell.isNotEmpty || row.isNotEmpty) {
    finishRow();
  }

  return rows;
}

List<CsvRecord> parseCsvRecords(String input) {
  final rows = parseCsvRows(input);
  if (rows.isEmpty) return const [];

  final headers = rows.first.map(normalizeCsvHeader).toList();
  final records = <CsvRecord>[];
  for (var index = 1; index < rows.length; index += 1) {
    final values = <String, String>{};
    for (var column = 0; column < headers.length; column += 1) {
      final header = headers[column];
      if (header.isEmpty) continue;
      values[header] = column < rows[index].length ? rows[index][column] : '';
    }
    final record = CsvRecord(rowNumber: index + 1, values: values);
    if (!record.isBlank) records.add(record);
  }
  return records;
}

String normalizeCsvHeader(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

double? parseCsvAmount(String value) {
  final cleaned = value.replaceAll(RegExp(r'[^0-9.\-]'), '');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}
