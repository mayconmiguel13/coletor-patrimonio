import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/export_utils.dart';
import '../core/utils/feedback_utils.dart';
import '../data/models/equipment.dart';
import '../data/repositories/equipment_repository.dart';

class CollectionProvider extends ChangeNotifier {
  final EquipmentRepository _repository;

  CollectionProvider(this._repository);

  // Estados da Sessão Ativa
  String _localidade = '';
  String _tipoEquipamento = AppConstants.tipoCpu;
  List<Equipment> _equipamentos = [];
  
  String? _ultimoCodigoLido;
  String? _mensagemAviso;
  bool _isProcessandoScan = false;
  DateTime? _ultimoScanTimestamp;

  // Getters
  String get localidade => _localidade;
  String get tipoEquipamento => _tipoEquipamento;
  List<Equipment> get equipamentos => _equipamentos;
  String? get ultimoCodigoLido => _ultimoCodigoLido;
  String? get mensagemAviso => _mensagemAviso;
  bool get isProcessandoScan => _isProcessandoScan;

  // Equipamentos filtrados pelo tipo ativo
  List<Equipment> get equipamentosDoTipoAtual =>
      _equipamentos.where((e) => e.tipo == _tipoEquipamento).toList();

  List<Equipment> get cpus =>
      _equipamentos.where((e) => e.tipo == AppConstants.tipoCpu).toList();

  List<Equipment> get monitores =>
      _equipamentos.where((e) => e.tipo == AppConstants.tipoMonitor).toList();

  int get contadorAtual => equipamentosDoTipoAtual.length;

  /// Define a localidade e carrega registros existentes
  void setLocalidade(String localidade) {
    _localidade = localidade.trim();
    carregarEquipamentos();
    notifyListeners();
  }

  /// Define o tipo de equipamento (CPU ou Monitor)
  void setTipoEquipamento(String tipo) {
    _tipoEquipamento = tipo;
    _ultimoCodigoLido = null;
    _mensagemAviso = null;
    notifyListeners();
  }

  /// Recarrega do Hive para a memória
  void carregarEquipamentos() {
    if (_localidade.isEmpty) {
      _equipamentos = [];
    } else {
      _equipamentos = _repository.getEquipmentsByLocalidade(_localidade);
    }
    notifyListeners();
  }

  /// Retorna o histórico de todas as secretarias com contagens e datas
  List<LocalidadeSummary> getHistorico() {
    return _repository.getLocalidadesSummary();
  }

  /// Retorna os equipamentos de qualquer localidade do histórico
  List<Equipment> getEquipamentosPorLocalidade(String localidade) {
    return _repository.getEquipmentsByLocalidade(localidade);
  }

  /// Processa a leitura de um código QR / Barras com debouncing e validação
  Future<bool> processarCodigo(String rawCode) async {
    final codigo = rawCode.trim();
    if (codigo.isEmpty) return false;

    // Debounce de segurança para evitar re-leitura no mesmo segundo
    final agora = DateTime.now();
    if (_ultimoScanTimestamp != null &&
        agora.difference(_ultimoScanTimestamp!).inMilliseconds < AppConstants.scanDebounceMs) {
      return false;
    }

    if (_isProcessandoScan) return false;
    _isProcessandoScan = true;

    try {
      // 1. Verificar duplicação
      final jaExiste = _repository.exists(
        localidade: _localidade,
        tipo: _tipoEquipamento,
        codigoLido: codigo,
      );

      if (jaExiste) {
        _ultimoScanTimestamp = agora;
        _mensagemAviso = '⚠️ Código já foi coletado nesta localidade!';
        notifyListeners();
        await FeedbackUtils.errorFeedback();

        // Limpa o aviso após 2 segundos
        Future.delayed(const Duration(seconds: 2), () {
          if (_mensagemAviso != null) {
            _mensagemAviso = null;
            notifyListeners();
          }
        });
        return false;
      }

      // 2. Inserção ultra-rápida no Hive
      final novoItem = await _repository.insertEquipment(
        localidade: _localidade,
        tipo: _tipoEquipamento,
        codigoLido: codigo,
      );

      _ultimoScanTimestamp = agora;
      _ultimoCodigoLido = codigo;
      _mensagemAviso = null;
      _equipamentos.add(novoItem);

      // 3. Feedback imediato tátil e sonoro
      await FeedbackUtils.successFeedback();
      notifyListeners();

      return true;
    } finally {
      _isProcessandoScan = false;
    }
  }

  /// Remove um item específico
  Future<void> deletarEquipamento(int id) async {
    await _repository.deleteEquipment(id);
    _equipamentos.removeWhere((e) => e.id == id);
    await FeedbackUtils.tapFeedback();
    notifyListeners();
  }

  /// Finaliza a sessão atual mantendo os dados salvos no Hive e limpa para nova coleta
  void finalizarSessao() {
    _localidade = '';
    _tipoEquipamento = AppConstants.tipoCpu;
    _equipamentos = [];
    _ultimoCodigoLido = null;
    _mensagemAviso = null;
    notifyListeners();
  }

  /// Descarta todos os dados da localidade atual do banco
  Future<void> descartarTudo() async {
    if (_localidade.isNotEmpty) {
      await _repository.deleteByLocalidade(_localidade);
    }
    finalizarSessao();
  }

  /// Exclui uma localidade específica do histórico
  Future<void> excluirLocalidadeHistorico(String localidade) async {
    await _repository.deleteByLocalidade(localidade);
    if (_localidade.trim().toLowerCase() == localidade.trim().toLowerCase()) {
      finalizarSessao();
    } else {
      notifyListeners();
    }
  }

  /// Exportação TXT da sessão ativa
  Future<File> exportarTXT() async {
    return await ExportUtils.exportTXT(
      equipamentos: _equipamentos,
      localidade: _localidade,
    );
  }

  /// Exportação XLSX da sessão ativa
  Future<File> exportarXLSX() async {
    return await ExportUtils.exportXLSX(
      equipamentos: _equipamentos,
      localidade: _localidade,
    );
  }

  /// Exportação TXT de qualquer localidade do histórico
  Future<File> exportarLocalidadeTXT(String localidade) async {
    final itens = _repository.getEquipmentsByLocalidade(localidade);
    return await ExportUtils.exportTXT(
      equipamentos: itens,
      localidade: localidade,
    );
  }

  /// Exportação XLSX de qualquer localidade do histórico
  Future<File> exportarLocalidadeXLSX(String localidade) async {
    final itens = _repository.getEquipmentsByLocalidade(localidade);
    return await ExportUtils.exportXLSX(
      equipamentos: itens,
      localidade: localidade,
    );
  }
}
