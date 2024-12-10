import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:external_path/external_path.dart';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class TabUSBScreen extends StatefulWidget {
  const TabUSBScreen({super.key});

  @override
  State<TabUSBScreen> createState() => _TabUSBScreenState();
}

class _TabUSBScreenState extends State<TabUSBScreen> {
  List<String> _storagePaths = [];
  String _selectedPath = '';
  String _imagePath = '';
  String _usbPath = '';
  String _soundPath = '';
  String? _currentPath;

  final TextEditingController _selectedLogoPathController =
      TextEditingController();
  final TextEditingController _imagePathController = TextEditingController();
  final TextEditingController _usbPathController = TextEditingController();
  final TextEditingController _soundPathController = TextEditingController();

  List<FileSystemEntity> _imageFiles = [];
  List<FileSystemEntity> _usbFiles = [];
  List<FileSystemEntity> _soundFiles = [];
  List<FileSystemEntity> _logoFiles = [];

  bool _isContentVisible = false;

  @override
  void initState() {
    super.initState();
    _listStoragePaths();
    _loadSettings();
  }

  Future<void> _listStoragePaths() async {
    final List<String> paths = [];
    final directory = await getApplicationDocumentsDirectory();

    paths.add(directory.path);

    try {
      final usbPaths = await ExternalPath.getExternalStorageDirectories();
      if (usbPaths.isNotEmpty) {
        paths.addAll(usbPaths);
      }
    } catch (e) {
      print("Error accessing USB storage: $e");
      // if (!paths.contains(directory.path)) {
      //   paths.add(directory.path);
      // }
    }

    setState(() {
      _storagePaths = paths;
    });
  }

  Future<void> _loadSettings() async {
    final box = await Hive.openBox('settingsBox');
    _selectedLogoPathController.text = box.get('logoPath', defaultValue: '');
    _imagePathController.text = box.get('imagePath', defaultValue: '');
    _usbPathController.text = box.get('usbPath', defaultValue: '');
    _soundPathController.text = box.get('soundPath', defaultValue: '');
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _imageFiles = [];
      _usbFiles = [];
      _soundFiles = [];
      _logoFiles = [];
    });

    await _loadFilesForPath(_imagePathController.text, _imageFiles);
    await _loadFilesForPath(_usbPathController.text, _usbFiles);
    await _loadFilesForPath(_soundPathController.text, _soundFiles);
    await _loadFilesForPath(_selectedLogoPathController.text, _logoFiles);
  }

  Future<void> _loadFilesForPath(
      String path, List<FileSystemEntity> fileList) async {
    if (path.isNotEmpty) {
      final directory = Directory(path);
      if (await directory.exists()) {
        final files = directory.listSync();
        setState(() {
          fileList.addAll(files);
        });
      }
    }
  }

  Future<void> _navigateToFolder(String path) async {
    // ขอสิทธิ์การเข้าถึงพื้นที่เก็บข้อมูล
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      setState(() {
        _showSnackbar('Permission denied for storage');
      });
      return; // หยุดการทำงานถ้าไม่ได้รับสิทธิ์
    }

    final directory = Directory(path);
    if (await directory.exists()) {
      try {
        final subFolders = directory
            .listSync()
            .where((item) => item is Directory)
            .map((item) => item.path)
            .toList();

        if (subFolders.isNotEmpty) {
          setState(() {
            _currentPath = path;
            _storagePaths = subFolders;
          });
        } else {
          _showSnackbar('ไม่มีโฟลเดอร์ย่อยในไดเร็กทอรีนี้');
        }
      } catch (e) {
        // จับข้อผิดพลาดเมื่อเข้าถึงโฟลเดอร์
        _showSnackbar('Error accessing directory: $e');
      }
    } else {
      // แสดงข้อความถ้าโฟลเดอร์ไม่พบ
      _showSnackbar('Directory does not exist.');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showStoragePathsDialog(
      {String? path, TextEditingController? controller}) {
    if (path != null) {
      _currentPath = path;
    } else {
      _currentPath = null;
      _listStoragePaths();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a Folder'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: _storagePaths.length,
              itemBuilder: (context, index) {
                final path = _storagePaths[index];
                final folderName = path.split('/').last;

                return ListTile(
                  title: Text(folderName),
                  subtitle: Text(path),
                  onTap: () {
                    _navigateToFolder(path);
                    Navigator.of(context).pop();
                    _showStoragePathsDialog(path: path, controller: controller);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_currentPath != null) {
                  setState(() {
                    if (controller == _imagePathController) {
                      _imagePath = _currentPath!;
                      _imagePathController.text = _imagePath;
                    } else if (controller == _usbPathController) {
                      _usbPath = _currentPath!;
                      _usbPathController.text = _usbPath;
                    } else if (controller == _soundPathController) {
                      _soundPath = _currentPath!;
                      _soundPathController.text = _soundPath;
                    } else {
                      _selectedPath = _currentPath!;
                      _selectedLogoPathController.text = _selectedPath;
                    }
                    _loadFiles();
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveSettings() async {
    final box = await Hive.openBox('settingsBox');
    await box.put('logoPath', _selectedLogoPathController.text);
    await box.put('imagePath', _imagePathController.text);
    await box.put('usbPath', _usbPathController.text);
    await box.put('soundPath', _soundPathController.text);
    _showSnackbar('บันทึกการตั้งค่าเรียบร้อยแล้ว!');
  }

  void _checkPassword() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController passwordController =
            TextEditingController();

        return AlertDialog(
          title: const Text('Enter Password'),
          content: TextField(
            controller: passwordController,
            decoration: const InputDecoration(hintText: 'Password'),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (passwordController.text == '0641318526') {
                  setState(() {
                    _isContentVisible = true;
                  });
                  Navigator.of(context).pop();
                } else {
                  _showSnackbar('Incorrect password');
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (!_isContentVisible)
              IconButton(
                icon: const Icon(Icons.lock),
                onPressed: _checkPassword,
              ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () {
                _showStoragePathsDialog(controller: _usbPathController);
              },
              child: IgnorePointer(
                child: TextField(
                  readOnly: true,
                  controller: _usbPathController,
                  style: const TextStyle(
                    fontSize: 40.0, // ปรับขนาดตัวอักษรของข้อมูลที่พิมพ์
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Selected USB Path (เลือก USB)',
                    hintText: 'Tap to select an USB',
                    border: OutlineInputBorder(),
                    hintStyle: TextStyle(
                      fontSize: 40.0, // ปรับขนาดตัวอักษรของ hint
                      color: Colors.grey, // เปลี่ยนสีของ hint (ถ้าต้องการ)
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildFileList(_usbFiles, _usbPathController),
            const SizedBox(height: 20),
            if (_isContentVisible)
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText:
                          'Selected Logo Path (เลือกโฟลเดอร์เก็บรูปภาพโลโก้)',
                      hintText: 'Tap to select a folder',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () => _showStoragePathsDialog(
                        controller: _selectedLogoPathController),
                    controller: _selectedLogoPathController,
                  ),
                  const SizedBox(height: 10),
                  _buildFileList(_logoFiles, _selectedLogoPathController),
                  const SizedBox(height: 20),
                  TextField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Image Path (เลือกโฟลเดอร์เก็บรูปภาพสไลด์)',
                      hintText: 'Tap to select an image',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () => _showStoragePathsDialog(
                        controller: _imagePathController),
                    controller: _imagePathController,
                  ),
                  const SizedBox(height: 10),
                  _buildFileList(_imageFiles, _imagePathController),
                  const SizedBox(height: 20),
                  TextField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Sound Path  (เลือกโฟลเดอร์ที่เก็บเสียง)',
                      hintText: 'Tap to select a sound folder',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () => _showStoragePathsDialog(
                        controller: _soundPathController),
                    controller: _soundPathController,
                  ),
                  const SizedBox(height: 10),
                  _buildFileList(_soundFiles, _soundPathController),
                  const SizedBox(height: 20),
                ],
              ),
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue, // สีพื้นหลังของปุ่ม
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 32.0,
                ), // ขนาดปุ่ม
                minimumSize:
                    Size(double.infinity, 60), // ทำให้ปุ่มมีขนาดกว้างเต็มที่
              ),
              child: const Text(
                'Save Settings\n(บันทึกการตั้งค่าหน้านี้)', // \n ทำให้ข้อความไปอยู่บรรทัดถัดไป
                textAlign: TextAlign.center, // จัดตำแหน่งข้อความให้อยู่กลาง
                style: TextStyle(
                  fontSize: 40.0, // ขนาดตัวอักษรของข้อความบนปุ่ม
                  fontWeight: FontWeight.bold, // น้ำหนักตัวอักษร
                  inherit: false, // ไม่ให้สืบทอดจาก Theme
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList(
      List<FileSystemEntity> files, TextEditingController controller) {
    if (controller.text.isEmpty) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Container(
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: files.map((file) {
            final fileName = file.path.split('/').last;

            return Container(
              width: 100,
              child: Column(
                children: [
                  if (file is File && _isImageFile(file))
                    Image.file(
                      file,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  else if (file is File && _isSoundFile(file))
                    const Icon(Icons.audiotrack, size: 80)
                  else if (file is File && _isFolder(file))
                    const Icon(Icons.folder_sharp, size: 80)
                  else if (file is File && _isAllFile(file))
                    const Icon(Icons.question_mark, size: 80),
                  Text(fileName, textAlign: TextAlign.center),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  bool _isImageFile(File file) {
    return file.path.endsWith('.png') ||
        file.path.endsWith('.jpg') ||
        file.path.endsWith('.JPG') ||
        file.path.endsWith('.jpeg');
  }

  bool _isSoundFile(File file) {
    return file.path.endsWith('.mp3') ||
        file.path.endsWith('.MP3') ||
        file.path.endsWith('.mp4') ||
        file.path.endsWith('.wav');
  }

  bool _isAllFile(File file) {
    return !file.path.endsWith('.mp3') ||
        !file.path.endsWith('.mp4') ||
        !file.path.endsWith('.wav') ||
        !file.path.endsWith('.png') ||
        !file.path.endsWith('.jpg') ||
        !file.path.endsWith('.JPG') ||
        !file.path.endsWith('.jpeg');
  }

  bool _isFolder(File file) {
    final fileType = FileSystemEntity.typeSync(file.path);
    return fileType == FileSystemEntityType.directory;
  }
}
