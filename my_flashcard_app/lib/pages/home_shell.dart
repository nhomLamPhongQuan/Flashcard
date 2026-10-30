import 'package:flutter/material.dart';

import 'account_page.dart';
import 'exam_page.dart';
import 'learn_tab.dart';
import 'library_tab.dart';
import 'stats_tab.dart';

/// Khung điều hướng chính cho học, kho từ, kiểm tra, tiến độ và tài khoản.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          // IndexedStack giữ trạng thái các tab khi chuyển qua lại.
          child: IndexedStack(
            index: _index,
            children: [
              const LearnTab(),
              LibraryTab(isActive: _index == 1),
              const ExamPage(),
              const StatsTab(),
              const AccountPage(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Học',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Kho từ',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Kiểm tra',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Tiến độ',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
