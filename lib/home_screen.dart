import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'room_status_screen.dart';
import 'daily_report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _children = [
    const DailyReportScreen(),
    const RoomStatusScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
  }

  Future<void> _checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      _showNoInternetDialog();
    }
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Internet Connection Lost'),
        content: const Text('Please connect to the internet.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initialize ScreenUtil for responsive design
    ScreenUtil.init(context);

    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.event_note_outlined,
              size: 24.sp, // Responsive icon size
            ),
            label: 'Daily Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_filled,
              size: 24.sp, // Responsive icon size
            ),
            label: 'Room Status',
          ),
        ],
        selectedLabelStyle: TextStyle(fontSize: 14.sp), // Responsive font size
        unselectedLabelStyle: TextStyle(fontSize: 12.sp), // Responsive font size
      ),
    );
  }
}