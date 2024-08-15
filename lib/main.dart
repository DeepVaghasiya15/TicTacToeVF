import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tic_tac_toe/Themes/light_theme.dart';
import 'package:flutter_tic_tac_toe/model/history_hive_model.dart';
import 'package:flutter_tic_tac_toe/screens/main_menu.dart';
import 'package:flutter_tic_tac_toe/storage/history_box.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter((await getApplicationDocumentsDirectory()).path);
  Hive.registerAdapter(HistoryModelHiveAdapter());
  await HistoryBox.openBox();

  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Flutter Tic Tac Toe',
    theme: lightMode,
    home: const Scaffold(body: MainMenu()),
  );
}
