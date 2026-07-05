import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/palette.dart';
import 'services/puzzle_repository.dart';
import 'services/progress_service.dart';
import 'services/settings_service.dart';
import 'services/audio_manager.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FleetsightApp());
}

class FleetsightApp extends StatefulWidget {
  const FleetsightApp({super.key});

  @override
  State<FleetsightApp> createState() => _FleetsightAppState();
}

class _FleetsightAppState extends State<FleetsightApp> {
  final repo = PuzzleRepository();
  final progress = ProgressService();
  final settings = SettingsService();
  late final AudioManager audio;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    audio = AudioManager(settings);
    _boot();
  }

  Future<void> _boot() async {
    await Future.wait([repo.load(), progress.init(), settings.init()]);
    if (settings.sound) audio.startMusic();
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: progress),
        ChangeNotifierProvider.value(value: settings),
      ],
      child: MaterialApp(
        title: 'Fleetsight',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: Palette.abyss,
          colorScheme: const ColorScheme.dark(
            primary: Palette.brass,
            surface: Palette.panel,
          ),
        ),
        home: _ready
            ? HomeScreen(repo: repo, audio: audio)
            : const _SplashScreen(),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Palette.abyss,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_boat, color: Palette.brass, size: 56),
            SizedBox(height: 16),
            Text('FLEETSIGHT',
                style: TextStyle(
                    color: Palette.foam,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}
