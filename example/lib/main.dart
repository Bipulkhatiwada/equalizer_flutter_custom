import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:equalizer_flutter_custom/equalizer_flutter_custom.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EqualizerProvider(),
      child: MaterialApp(
        title: 'Demo Equalizer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Map<String, String>> songs = [
    {
      'displayName': 'Sample track 1',
      'filePath':
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    },
    {
      'displayName': 'Sample track 2',
      'filePath':
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    },
  ];

  late final AudioPlayer audioPlayer;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Equalizer"),
      ),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final s = songs[index];
          return InkWell(
            onTap: () async {
              final url = s['filePath']!;
              try {
                await audioPlayer.setUrl(url);
                await audioPlayer.play();
                // give platform time to initialize session id
                await Future.delayed(const Duration(milliseconds: 300));
                if (!mounted) return;
                final sessionId = audioPlayer.androidAudioSessionId;
                if (sessionId == null || sessionId <= 0) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Audio session not available on this device.'),
                  ));
                  return;
                }
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomEqualizer(
                      isEqEnabled: true,
                      playerSessionId: sessionId,
                      bandTextColor: Colors.green,
                      sliderBoxHeight: 220,
                      sliderBoxPadding: 10,
                      appbarElevation: 0,
                      appBarShadowColor: Colors.grey,
                      titleTextStyle: const TextStyle(color: Colors.red),
                      sliderBoxBorderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error playing track: $e'),
                ));
              }
            },
            child: ListTile(
              title: Text(s['displayName']!),
            ),
          );
        },
      ),
    );
  }
}
