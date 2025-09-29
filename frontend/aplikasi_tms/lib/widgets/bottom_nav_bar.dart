import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF1976D2),
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.dashboard_outlined, Icons.dashboard, 0),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.analytics_outlined, Icons.analytics, 1),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.notifications_outlined, Icons.notifications, 2),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.person_outline, Icons.person, 3),
            label: 'Profile',
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData outlinedIcon, IconData filledIcon, int index) {
    bool isSelected = currentIndex == index;
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xFF1976D2).withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        isSelected ? filledIcon : outlinedIcon,
        size: isSelected ? 26 : 24,
        color: isSelected ? Color(0xFF1976D2) : Colors.grey[600],
      ),
    );
  }
}