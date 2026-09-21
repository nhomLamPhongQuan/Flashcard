import 'package:flutter/material.dart';

import 'learn_tab.dart';
import 'library_tab.dart';
import 'stats_tab.dart';

/// Khung điều hướng chính với 3 tab: Học, Kho từ, Tiến độ.
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
          //IndexedStack giữ trạng thái cả 3 tab không bị mất khi chuyển qua lại
          child: IndexedStack(
            index: _index,
            children: const [LearnTab(), LibraryTab(), StatsTab()],
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
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Tiến độ',
          ),
        ],
      ),
    );
  }
}
