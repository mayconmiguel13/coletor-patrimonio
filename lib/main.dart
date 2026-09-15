import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/equipment_repository.dart';
import 'state/collection_provider.dart';
import 'ui/screens/config_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Força orientação vertical para agilidade na operação de campo
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicialização do Hive para armazenamento ultra-rápido NoSQL
  await Hive.initFlutter();

  final equipmentRepository = EquipmentRepository();
  await equipmentRepository.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CollectionProvider(equipmentRepository),
        ),
      ],
      child: const ColetorPatrimonioApp(),
    ),
  );
}

class ColetorPatrimonioApp extends StatelessWidget {
  const ColetorPatrimonioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coletor Ágil de Patrimônio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const ConfigScreen(),
    );
  }
}
