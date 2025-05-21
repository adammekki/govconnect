import 'package:flutter/material.dart';

class AppBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        onTap(index);
        switch (index) {
          case 0:
            Navigator.of(context).pushReplacementNamed('/feed');
            break;
          case 1:
            Navigator.of(context).pushReplacementNamed('/chat');
            break;
          case 2:
            Navigator.of(context).pushReplacementNamed('/notifications');
            break;
          case 3:
            Navigator.of(context).pushReplacementNamed('/profile');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF1C2F41),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      elevation: 0,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined, size: 28),
          activeIcon: Icon(Icons.home, size: 28),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message_outlined, size: 28),
          activeIcon: Icon(Icons.message, size: 28),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_none, size: 28),
          activeIcon: Icon(Icons.notifications, size: 28),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu, size: 28),
          activeIcon: Icon(Icons.menu, size: 28),
          label: '',
        ),
      ],
    );
  }
}