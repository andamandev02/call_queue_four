import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:external_path/external_path.dart';
import 'dart:io';

class TestUSBScreen extends StatefulWidget {
  const TestUSBScreen({super.key});

  @override
  State<TestUSBScreen> createState() => _TestUSBScreenState();
}

class _TestUSBScreenState extends State<TestUSBScreen> {
  List<String> _storagePaths = [];

  @override
  void initState() {
    super.initState();
    _listStoragePaths();
  }

  Future<void> _listStoragePaths() async {
    final List<String> paths = [];

    // ที่เก็บข้อมูลในเครื่อง
    final directory = await getApplicationDocumentsDirectory();
    paths.add(directory.path);

    // ที่เก็บข้อมูล USB (External Storage)
    try {
      final usbPaths = await ExternalPath.getExternalStorageDirectories();
      if (usbPaths.isNotEmpty) {
        paths.addAll(usbPaths);
      }
    } catch (e) {
      print("Error accessing USB storage: $e");
    }

    setState(() {
      _storagePaths = paths;
    });
  }

  void _navigateToImagesFolder(String basePath) {
    final imagesFolder = Directory('$basePath/images');
    // final imagesFolder = Directory('$basePath/');

    if (imagesFolder.existsSync()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ImagesListScreen(imagesFolderPath: imagesFolder.path),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Images folder does not exist')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Storage List'),
      ),
      body: ListView.builder(
        itemCount: _storagePaths.length,
        itemBuilder: (context, index) {
          final path = _storagePaths[index];
          final folderName = path.split('/').last;

          return ListTile(
            title: Text(folderName),
            onTap: () {
              if (folderName == "1474-1882") {
                _navigateToImagesFolder(path);
              } else if (folderName == "22A1-A3D7") {
                _navigateToImagesFolder(path);
              } else if (folderName == "C282-59BC") {
                _navigateToImagesFolder(path);
              } else if (folderName == "1D67-6721") {
                _navigateToImagesFolder(path);
              } else {
                _navigateToImagesFolder(path);
                // _navigateToImagesFolder(path);
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(content: Text('Folder: $folderName')),
                // );
              }
            },
          );
        },
      ),
    );
  }
}

class ImagesListScreen extends StatelessWidget {
  final String imagesFolderPath;

  ImagesListScreen({required this.imagesFolderPath});

  @override
  Widget build(BuildContext context) {
    final directory = Directory(imagesFolderPath);
    final imageFiles = directory
        .listSync()
        .where((item) => item is File && _isImageFile(item.path))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Images in $imagesFolderPath'),
      ),
      body: ListView.builder(
        itemCount: imageFiles.length,
        itemBuilder: (context, index) {
          final file = imageFiles[index] as File;

          return ListTile(
            leading: Image.file(file, width: 50, height: 50, fit: BoxFit.cover),
            title: Text(file.path.split('/').last),
            onTap: () {
              // Add actions if needed
            },
          );
        },
      ),
    );
  }

  bool _isImageFile(String path) {
    final extension = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension);
  }
}
