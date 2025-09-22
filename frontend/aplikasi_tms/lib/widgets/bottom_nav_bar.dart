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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
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
            icon: _buildNavIcon(Icons.home_outlined, Icons.home, 0),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.local_shipping_outlined, Icons.local_shipping, 1),
            label: 'Armada',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.inventory_2_outlined, Icons.inventory_2, 2),
            label: 'Pengiriman',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.analytics_outlined, Icons.analytics, 3),
            label: 'Analitik',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.person_outline, Icons.person, 4),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData outlinedIcon, IconData filledIcon, int index) {
    bool isSelected = currentIndex == index;
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isSelected ? filledIcon : outlinedIcon,
        size: 24,
      ),
    );
  }
}