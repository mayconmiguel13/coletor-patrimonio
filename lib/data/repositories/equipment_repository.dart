import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../models/equipment.dart';

class EquipmentRepository {
  Box? _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(AppConstants.equipmentsBox)) {
      _box = await Hive.openBox(AppConstants.equipmentsBox);
    } else {
      _box = Hive.box(AppConstants.equipmentsBox);
    }
  }

  Box get box {
    if (_box == null || !_box!.isOpen) {
      _box = Hive.box(AppConstants.equipmentsBox);
    }
    return _box!;
  }

  /// Insere ou atualiza um equipamento de forma instantânea (em microssegundos)
  Future<Equipment> insertEquipment({
    required String localidade,
    required String tipo,
    required String codigoLido,
  }) async {
    final nextId = DateTime.now().millisecondsSinceEpoch;
    final equipment = Equipment(
      id: nextId,
      localidade: localidade,
      tipo: tipo,
      codigoLido: codigoLido,
      timestamp: DateTime.now(),
      sincronizado: false,
    );

    // Gravação no Hive (Memory-mapped + append-only binário em disco)
    await box.put(equipment.id, equipment.toMap());
    return equipment;
  }

  /// Retorna todos os equipamentos de uma determinada localidade
  List<Equipment> getEquipmentsByLocalidade(String localidade) {
    final rawValues = box.values;
    final List<Equipment> items = [];

    for (final raw in rawValues) {
      if (raw is Map) {
        final eq = Equipment.fromMap(raw);
        if (eq.localidade.trim().toLowerCase() == localidade.trim().toLowerCase()) {
          items.add(eq);
        }
      }
    }

    // Ordenados pelo mais recente
    items.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return items;
  }

  /// Verifica duplicação no escopo da localidade e tipo
  bool exists({
    required String localidade,
    required String tipo,
    required String codigoLido,
  }) {
    final rawValues = box.values;
    for (final raw in rawValues) {
      if (raw is Map) {
        final eq = Equipment.fromMap(raw);
        if (eq.localidade.trim().toLowerCase() == localidade.trim().toLowerCase() &&
            eq.tipo.trim().toLowerCase() == tipo.trim().toLowerCase() &&
            eq.codigoLido.trim().toLowerCase() == codigoLido.trim().toLowerCase()) {
          return true;
        }
      }
    }
    return false;
  }

  /// Exclui um equipamento específico pelo ID
  Future<void> deleteEquipment(int id) async {
    await box.delete(id);
  }

  /// Remove todos os equipamentos de uma localidade
  Future<void> deleteByLocalidade(String localidade) async {
    final keysToDelete = <dynamic>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) {
        final eq = Equipment.fromMap(raw);
        if (eq.localidade.trim().toLowerCase() == localidade.trim().toLowerCase()) {
          keysToDelete.add(key);
        }
      }
    }
    await box.deleteAll(keysToDelete);
  }

  /// Limpa toda a base
  Future<void> clearAll() async {
    await box.clear();
  }
}
