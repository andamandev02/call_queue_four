import 'package:flutter/material.dart';
import 'setting-usb.dart';

class SettingMainScreen extends StatefulWidget {
  const SettingMainScreen({super.key});

  @override
  State<SettingMainScreen> createState() => _SettingMainScreenState();
}

class _SettingMainScreenState extends State<SettingMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setting (การตั้งค่า)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Setting USB (ตั้งค่า USB)'),
            // Tab(text: 'Setting Sound (ตั้งค่า เสียง)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TabUSBScreen(),
          // TabSoundScreen(),
        ],
      ),
    );
  }
}
