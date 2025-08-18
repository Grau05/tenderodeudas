import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ExportService {
  static Future<File> exportBasic({
    required List<List<String>> clients,
    required List<List<String>> debts,
    required List<List<String>> payments,
  }) async {
    final excel = Excel.createExcel();
    final cSheet = excel['Clientes'];
    for (var row in clients) {
      cSheet.appendRow(row.map((e) => TextCellValue(e)).toList());
    }
    final dSheet = excel['Deudas'];
    for (var row in debts) {
      dSheet.appendRow(row.map((e) => TextCellValue(e)).toList());
    }
    final pSheet = excel['Pagos'];
    for (var row in payments) {
      pSheet.appendRow(row.map((e) => TextCellValue(e)).toList());
    }
    excel.delete('Sheet1');

    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'reporte_me_debe.xlsx'));
    final bytes = excel.encode()!;
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
