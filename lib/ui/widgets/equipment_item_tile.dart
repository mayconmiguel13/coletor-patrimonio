import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/equipment.dart';

class EquipmentItemTile extends StatelessWidget {
  final Equipment equipment;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback? onToggleTipo;

  const EquipmentItemTile({
    super.key,
    required this.equipment,
    required this.index,
    required this.onDelete,
    this.onToggleTipo,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('dd/MM HH:mm').format(equipment.timestamp);
    final outroTipo = equipment.tipo == AppConstants.tipoCpu ? 'Monitor' : 'CPU';

    return Dismissible(
      key: ValueKey(equipment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 26),
            SizedBox(width: 8),
            Text(
              'Excluir',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remover equipamento?'),
            content: Text('Deseja remover o código "${equipment.codigoLido}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  minimumSize: const Size(90, 40),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Remover'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Text(
              '#$index',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          title: Text(
            equipment.codigoLido,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.5,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          subtitle: Row(
            children: [
              const Icon(Icons.access_time, size: 13, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 4),
              Text(
                timeStr,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onToggleTipo != null)
                Tooltip(
                  message: 'Alternar para $outroTipo',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onToggleTipo,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            equipment.tipo == AppConstants.tipoCpu ? Icons.tv : Icons.computer,
                            size: 13,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '⇄ $outroTipo',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.secondaryColor),
                tooltip: 'Deletar',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Remover equipamento?'),
                      content: Text('Deseja remover "${equipment.codigoLido}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorColor,
                            minimumSize: const Size(90, 40),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Remover'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    onDelete();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
