import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/equipment.dart';
import '../constants/app_constants.dart';

class ExportUtils {
  /// Formatação padrão de data e hora
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _fileSafeFormat = DateFormat('yyyyMMdd_HHmmss');

  /// Gera e exporta o arquivo TXT estruturado
  static Future<File> exportTXT({
    required List<Equipment> equipamentos,
    required String localidade,
  }) async {
    final cpus = equipamentos.where((e) => e.tipo == AppConstants.tipoCpu).toList();
    final monitores = equipamentos.where((e) => e.tipo == AppConstants.tipoMonitor).toList();
    final now = DateTime.now();

    final buffer = StringBuffer();
    buffer.writeln('RELATÓRIO DE COLETA DE EQUIPAMENTOS');
    buffer.writeln('=====================================');
    buffer.writeln('Localidade: $localidade');
    buffer.writeln('Data: ${_dateFormat.format(now)}');
    buffer.writeln('');

    buffer.writeln('CPUS (${cpus.length} equipamentos):');
    if (cpus.isEmpty) {
      buffer.writeln('  (Nenhum equipamento coletado)');
    } else {
      for (final cpu in cpus) {
        buffer.writeln('- ${cpu.codigoLido} (${_timeFormat.format(cpu.timestamp)})');
      }
    }
    buffer.writeln('');

    buffer.writeln('MONITORES (${monitores.length} equipamentos):');
    if (monitores.isEmpty) {
      buffer.writeln('  (Nenhum equipamento coletado)');
    } else {
      for (final mon in monitores) {
        buffer.writeln('- ${mon.codigoLido} (${_timeFormat.format(mon.timestamp)})');
      }
    }
    buffer.writeln('');
    buffer.writeln('Total: ${equipamentos.length} equipamentos');

    final dir = await _getExportDirectory();
    final cleanLoc = _sanitizeFileName(localidade);
    final fileName = 'coleta_${cleanLoc}_${_fileSafeFormat.format(now)}.txt';
    final file = File('${dir.path}/$fileName');

    await file.writeAsString(buffer.toString());
    return file;
  }

  /// Gera e exporta a planilha XLSX com 3 abas estruturadas
  static Future<File> exportXLSX({
    required List<Equipment> equipamentos,
    required String localidade,
  }) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();

    final cpus = equipamentos.where((e) => e.tipo == AppConstants.tipoCpu).toList();
    final monitores = equipamentos.where((e) => e.tipo == AppConstants.tipoMonitor).toList();
    final now = DateTime.now();

    // ──────────────────────────────────────────────
    // Aba 1: Resumo
    // ──────────────────────────────────────────────
    const sheetResumoName = 'Resumo';
    final sheetResumo = excel[sheetResumoName];
    
    sheetResumo.appendRow([TextCellValue('RELATÓRIO DE COLETA DE EQUIPAMENTOS')]);
    sheetResumo.appendRow([TextCellValue('Localidade:'), TextCellValue(localidade)]);
    sheetResumo.appendRow([TextCellValue('Data da Coleta:'), TextCellValue(_dateFormat.format(now))]);
    sheetResumo.appendRow([TextCellValue('')]);
    sheetResumo.appendRow([TextCellValue('Tipo'), TextCellValue('Quantidade')]);
    sheetResumo.appendRow([TextCellValue('CPUs'), IntCellValue(cpus.length)]);
    sheetResumo.appendRow([TextCellValue('Monitores'), IntCellValue(monitores.length)]);
    sheetResumo.appendRow([TextCellValue('Total Geral'), IntCellValue(equipamentos.length)]);

    // ──────────────────────────────────────────────
    // Aba 2: CPUs
    // ──────────────────────────────────────────────
    const sheetCpuName = 'CPUs';
    final sheetCPU = excel[sheetCpuName];
    sheetCPU.appendRow([
      TextCellValue('Item'),
      TextCellValue('ID'),
      TextCellValue('Código Lido'),
      TextCellValue('Data/Hora'),
    ]);

    for (var i = 0; i < cpus.length; i++) {
      final eq = cpus[i];
      sheetCPU.appendRow([
        IntCellValue(i + 1),
        IntCellValue(eq.id),
        TextCellValue(eq.codigoLido),
        TextCellValue(_dateFormat.format(eq.timestamp)),
      ]);
    }

    // ──────────────────────────────────────────────
    // Aba 3: Monitores
    // ──────────────────────────────────────────────
    const sheetMonName = 'Monitores';
    final sheetMonitor = excel[sheetMonName];
    sheetMonitor.appendRow([
      TextCellValue('Item'),
      TextCellValue('ID'),
      TextCellValue('Código Lido'),
      TextCellValue('Data/Hora'),
    ]);

    for (var i = 0; i < monitores.length; i++) {
      final eq = monitores[i];
      sheetMonitor.appendRow([
        IntCellValue(i + 1),
        IntCellValue(eq.id),
        TextCellValue(eq.codigoLido),
        TextCellValue(_dateFormat.format(eq.timestamp)),
      ]);
    }

    // Remove sheet padrão se for diferente
    if (defaultSheet != null && defaultSheet != sheetResumoName) {
      excel.delete(defaultSheet);
    }

    final dir = await _getExportDirectory();
    final cleanLoc = _sanitizeFileName(localidade);
    final fileName = 'coleta_${cleanLoc}_${_fileSafeFormat.format(now)}.xlsx';
    final file = File('${dir.path}/$fileName');

    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    return file;
  }

  /// Compartilha o arquivo via bandeja nativa do Android (WhatsApp, Drive, Arquivos)
  static Future<void> shareFile(File file, {String? subject}) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject ?? 'Relatório de Coleta de Patrimônio',
      text: 'Relatório gerado pelo aplicativo Coletor Ágil.',
    );
  }

  static Future<Directory> _getExportDirectory() async {
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        return extDir;
      }
    } catch (_) {}
    return await getApplicationDocumentsDirectory();
  }

  static String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
  }
}
