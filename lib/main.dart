import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'setting-main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = ['000', '000', '000', '000'];
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  bool isFieldEnabled = true;
  FocusNode focusNode = FocusNode();
  String? errorLoading;
  Timer? _timer;

  late Box box;
  late Box boxmode;

  List<File> filteredLogoList = [];
  List<File> logoList = [];

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
    _requestExternalStoragePermission();
    _openBox();
  }

  Future<void> _requestExternalStoragePermission() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
    } else {
      setState(() {
        errorLoading = 'Permission denied for storage';
      });
    }
  }

  Future<void> _openBox() async {
    await Hive.initFlutter();
    box = await Hive.openBox('settingsBox');
    await loadSettings();
    box.listenable().addListener(() {
      loadSettings();
    });
    boxmode.listenable().addListener(() {
      loadSettings();
    });
    setState(() {});
  }

  Future<void> loadSettings() async {
    final usb = box.get('usbPath', defaultValue: '').toString();
    await loadLogoFromUSB();
  }

  void _updateMessage(String input) async {
    try {
      if (isPlaying) {
        return;
      }
      setState(() {
        isFieldEnabled = false;
      });
      final parts = input.split('+');

      if (input == '/1234/') {
        _controller.clear();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingMainScreen()),
        );
        _handleInvalidCharacter();
      } else if (parts.length == 2) {
        await playsounds(parts);
      } else {
        _handleInvalidCharacter();
      }
    } catch (e) {
      _handleInvalidCharacter();
    }
  }

  Future<void> playsounds(parts) async {
    Future.microtask(() async {
      try {
        final usb = box.get('usbPath', defaultValue: '').toString();

        Directory? externalDir = await getExternalStorageDirectory();
        String usbPath = p.join(usb, 'sounds');
        Directory usbDir = Directory(usbPath);

        // ตัดส่วนเกินของ part[0] และ part[1]
        final part0 = parts[0].trim().length > 1
            ? parts[0].trim().substring(0, 1)
            : parts[0].trim();
        final part1 = parts[1].trim().length > 3
            ? parts[1].trim().substring(0, 3)
            : parts[1].trim();

        final index = int.parse(part0.trim()) - 1;

        if (index >= 0 && index < _messages.length) {
          setState(() {
            _messages[index] = part1;
          });
        }

        _timer?.cancel();
        // final trimmedString = parts[1].trim().toString();
        final numberString = part1..replaceAll(RegExp('^0+'), '');

        if (await usbDir.exists()) {
          Future<void> _playAudioFile(String path) async {
            try {
              if (await File(path).exists()) {
                await audioPlayer.play(DeviceFileSource(path));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Audio file not found: $path'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error playing audio file: $e'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }

          if (index >= 0 && index < _messages.length) {
            await _playAudioFile(
                p.join(usbPath, 'SOUNDTRACK', 'เชิญหมายเลข.mp3'));
            await audioPlayer.onPlayerStateChanged.firstWhere(
              (state) => state == PlayerState.completed,
            );
            for (int i = 0; i < numberString.length; i++) {
              await _playAudioFile(
                  p.join(usbPath, 'SOUNDTRACK', '${numberString[i]}.mp3'));
              if (i + 1 < numberString.length &&
                  numberString[i] == numberString[i + 1]) {
                await audioPlayer.onPlayerStateChanged.firstWhere(
                  (state) => state == PlayerState.completed,
                );
              } else {
                await Future.delayed(const Duration(milliseconds: 650));
              }
            }
            await _playAudioFile(
                p.join(usbPath, 'SOUNDTRACK', 'ที่เค้าเตอร์หมายเลข.mp3'));

            await audioPlayer.onPlayerStateChanged.firstWhere(
              (state) => state == PlayerState.completed,
            );

            await _playAudioFile(
                p.join(usbPath, 'SOUNDTRACK', '${index + 1}.mp3'));
          } else {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                const duration = Duration(seconds: 5);
                Timer(duration, () {
                  Navigator.of(context).pop();
                });
                return const AlertDialog(
                  title: Text(
                    'กรุณาระบุ ไฟล์ USB ที่ต้องการใช้งาน',
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            );
            //   await audioPlayer.play(AssetSource('soundtrack/เชิญหมายเลข.mp3'));
            //   await audioPlayer.onPlayerStateChanged.firstWhere(
            //     (state) => state == PlayerState.completed,
            //   );
            //   for (int i = 0; i < numberString.length; i++) {
            //     await audioPlayer
            //         .play(AssetSource('soundtrack/${numberString[i]}.mp3'));
            //     if (i + 1 < numberString.length &&
            //         numberString[i] == numberString[i + 1]) {
            //       await audioPlayer.onPlayerStateChanged.firstWhere(
            //         (state) => state == PlayerState.completed,
            //       );
            //     } else {
            //       await Future.delayed(const Duration(milliseconds: 650));
            //     }
            //   }
            //   await audioPlayer
            //       .play(AssetSource('soundtrack/ที่เค้าเตอร์หมายเลข.mp3'));
            //   await audioPlayer.onPlayerStateChanged.firstWhere(
            //     (state) => state == PlayerState.completed,
            //   );
            //   await audioPlayer.play(AssetSource('soundtrack/${index}.mp3'));
          }
        }
        _timer?.cancel();
        _handleInvalidCharacter();
      } catch (e) {
        _timer?.cancel();
        _handleInvalidCharacter();
      }
      _timer?.cancel();
      _handleInvalidCharacter();
    });
  }

  void _handleInvalidCharacter() {
    setState(() {
      isFieldEnabled = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isFieldEnabled) {
        focusNode.requestFocus();
        _controller.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          if (!focusNode.hasFocus) {
            focusNode.requestFocus();
          }
        },
        child: Stack(
          children: [
            // GridView ที่ทับ TextField
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double gridItemHeight =
                      (constraints.maxHeight - 17) / 2 - 0; // ปรับพื้นที่ Grid
                  double gridItemWidth = constraints.maxWidth / 2 - 16;

                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 0,
                    mainAxisSpacing: 0,
                    childAspectRatio: gridItemWidth / gridItemHeight,
                    padding: EdgeInsets.all(0),
                    children: List.generate(4, (index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          borderRadius: BorderRadius.circular(0),
                          border: Border.all(
                            color: const Color.fromARGB(255, 255, 217, 0),
                            width: 2.0,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment
                              .center, // Aligning everything to the center
                          children: [
                            // ส่วนข้อความ Stack
                            Positioned(
                              left:
                                  100, // Aligning "Order Number" text to the left
                              top: gridItemHeight * 0.25,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 235, 75, 27),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color:
                                        const Color.fromARGB(255, 235, 75, 27),
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  "Order Number",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: gridItemHeight * 0.06,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            Positioned(
                              top: gridItemHeight * 0.4,
                              child: Text(
                                _messages[index],
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 255, 217, 0),
                                  fontSize: gridItemHeight * 0.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            // ส่วนรูปภาพ
                            Positioned(
                              top: 5,
                              child: Container(
                                height: gridItemHeight * 0.2,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: logoList.length > index &&
                                          logoList[index] != null
                                      ? Image.file(
                                          logoList[index],
                                          fit: BoxFit.contain,
                                          width: gridItemHeight * 0.3,
                                          height: gridItemHeight * 0.3,
                                        )
                                      : Icon(
                                          Icons.image,
                                          color: Colors.white,
                                          size: gridItemHeight * 0.5,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),
            ),

            // TextField โปร่งใส
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 0.0, // ทำให้โปร่งใส
                child: TextField(
                  controller: _controller,
                  focusNode: focusNode,
                  autofocus: true,
                  enabled: true, // เปิดใช้งาน TextField
                  onSubmitted: (value) {
                    _updateMessage(value);
                    _controller.clear();
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d+-.*/]')),
                  ],
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loadLogoFromUSB() async {
    final usb = box.get('usbPath', defaultValue: '').toString();

    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await _requestExternalStoragePermission();
    }

    Directory? externalDir = await getExternalStorageDirectory();
    if (externalDir == null) {
      throw 'External storage directory not found';
    }

    String usbPath = p.join(usb, 'logo');
    Directory usbDir = Directory(usbPath);

    if (!usbDir.existsSync()) {
      throw 'USB directory does not exist: $usbPath';
    }

    List<FileSystemEntity> files = usbDir.listSync();
    List<File> logoFiles = files
        .whereType<File>()
        .where((file) => RegExp(r'logo[1-4]\.(png|jpg|jpeg)')
            .hasMatch(p.basename(file.path)))
        .toList();

    if (logoFiles.isEmpty) {
      throw 'No image files found in USB directory';
    }

    // เรียงลำดับไฟล์ตามชื่อ (logo1, logo2, ...)
    logoFiles.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

    setState(() {
      logoList = logoFiles; // เก็บไฟล์ใน logoList
    });
  }
}
