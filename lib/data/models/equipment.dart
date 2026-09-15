class Equipment {
  final int id;
  final String localidade;
  final String tipo; // "CPU" ou "Monitor"
  final String codigoLido;
  final DateTime timestamp;
  final bool sincronizado;

  Equipment({
    required this.id,
    required this.localidade,
    required this.tipo,
    required this.codigoLido,
    required this.timestamp,
    this.sincronizado = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'localidade': localidade,
      'tipo': tipo,
      'codigoLido': codigoLido,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'sincronizado': sincronizado,
    };
  }

  factory Equipment.fromMap(Map<dynamic, dynamic> map) {
    return Equipment(
      id: map['id'] as int? ?? 0,
      localidade: map['localidade'] as String? ?? '',
      tipo: map['tipo'] as String? ?? 'CPU',
      codigoLido: map['codigoLido'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      sincronizado: map['sincronizado'] as bool? ?? false,
    );
  }

  Equipment copyWith({
    int? id,
    String? localidade,
    String? tipo,
    String? codigoLido,
    DateTime? timestamp,
    bool? sincronizado,
  }) {
    return Equipment(
      id: id ?? this.id,
      localidade: localidade ?? this.localidade,
      tipo: tipo ?? this.tipo,
      codigoLido: codigoLido ?? this.codigoLido,
      timestamp: timestamp ?? this.timestamp,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }
}
