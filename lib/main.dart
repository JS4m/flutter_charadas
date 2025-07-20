import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/game_bloc.dart';
import 'bloc/game_event.dart';
import 'screens/home_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicializar Hive con manejo de errores
    await _initializeHive();
  } catch (e) {
    debugPrint('Error inicializando Hive: $e');
    // Continuar sin persistencia si hay error
  }
  
  // Bloquear orientación vertical para pantallas principales
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Deshabilitar el corrector ortográfico del sistema para evitar subrayados amarillos
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  
  runApp(const MyApp());
}

Future<void> _initializeHive() async {
  try {
    // Método alternativo si initFlutter falla
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
  } catch (e) {
    // Fallback a initFlutter
    await Hive.initFlutter();
  }
  
  // Abrir boxes con manejo de errores
  try {
    await Hive.openBox('app_state');
  } catch (e) {
    debugPrint('Error abriendo box app_state: $e');
  }
  
  try {
    await Hive.openBox('settings');
  } catch (e) {
    debugPrint('Error abriendo box settings: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  int _rebuildCounter = 0;
  late Box _settingsBox;
  bool _hiveInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSettingsBox();
  }

  void _initializeSettingsBox() {
    try {
      if (Hive.isBoxOpen('settings')) {
        _settingsBox = Hive.box('settings');
        _hiveInitialized = true;
      }
    } catch (e) {
      debugPrint('Error inicializando settings box: $e');
      _hiveInitialized = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Forzar reconstrucción completa de la app cuando vuelve al primer plano
      setState(() {
        _rebuildCounter++;
      });
      
      // Restaurar orientación vertical bloqueada
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
          ]);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si Hive no está inicializado, usar tema por defecto
    if (!_hiveInitialized) {
      return BlocProvider(
        create: (context) => GameBloc()..add(LoadCategoriesEvent()),
        child: MaterialApp(
          key: ValueKey('app_$_rebuildCounter'),
          title: 'Charadas Bíblicas',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
            useMaterial3: true,
            fontFamily: 'System',
          ),
          home: HomeScreen(key: ValueKey('home_screen_$_rebuildCounter')),
          debugShowCheckedModeBanner: false,
        ),
      );
    }

    return ValueListenableBuilder(
      valueListenable: _settingsBox.listenable(),
      builder: (context, box, _) {
        final bool darkMode = box.get('darkMode', defaultValue: false);
        return BlocProvider(
          create: (context) => GameBloc()..add(LoadCategoriesEvent()),
          child: MaterialApp(
            key: ValueKey('app_$_rebuildCounter'),
            title: 'Charadas Bíblicas',
            theme: darkMode
                ? ThemeData.dark().copyWith(
                    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6), brightness: Brightness.dark),
                    useMaterial3: true,
                    textTheme: const TextTheme().apply(
                      fontFamily: 'System',
                      bodyColor: Colors.white,
                      displayColor: Colors.white,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                  )
                : ThemeData(
                    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
                    useMaterial3: true,
                    fontFamily: 'System',
                    textTheme: const TextTheme().apply(
                      bodyColor: Colors.black,
                      displayColor: Colors.black,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                    inputDecorationTheme: const InputDecorationTheme(
                      border: InputBorder.none,
                    ),
                  ),
            home: HomeScreen(key: ValueKey('home_screen_$_rebuildCounter')),
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}
