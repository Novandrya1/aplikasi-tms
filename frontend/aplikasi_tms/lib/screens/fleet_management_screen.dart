import 'package:flutter/material.dart';
import 'vehicle_management_screen.dart';
import 'driver_management_screen.dart';

class FleetManagementScreen extends StatelessWidget {
  const FleetManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Armada'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.blue.withOpacity(0.3),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE3F2FD),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width > 600 ? 24 : 16,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 20 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manajemen Armada',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width > 600 ? 20 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kelola kendaraan, driver, dan fleet operations',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width > 600 ? 14 : 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Main Fleet Management Options
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
                  double childAspectRatio = constraints.maxWidth > 600 ? 1.3 : 2.5;
                  
                  return GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: childAspectRatio,
                    children: [
                      _buildFleetCard(
                        context,
                        'Vehicle Management',
                        Icons.directions_car,
                        Color(0xFF1976D2),
                        'Kelola data kendaraan dan maintenance',
                        () => Navigator.pushNamed(context, '/vehicle-management'),
                      ),
                      _buildFleetCard(
                        context,
                        'Driver Management',
                        Icons.person,
                        Color(0xFF388E3C),
                        'Kelola data driver dan lisensi',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DriverManagementScreen(),
                          ),
                        ),
                      ),
                      _buildFleetCard(
                        context,
                        'Fleet Tracking',
                        Icons.gps_fixed,
                        Color(0xFF7B1FA2),
                        'Monitor lokasi real-time',
                        () => _showComingSoon(context, 'Fleet Tracking'),
                      ),
                      _buildFleetCard(
                        context,
                        'Maintenance Schedule',
                        Icons.build,
                        Color(0xFFD32F2F),
                        'Jadwal perawatan kendaraan',
                        () => _showComingSoon(context, 'Maintenance Schedule'),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Sub Components Section
              Text(
                'Sub-Components',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              
              // Sub Components Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildSubComponent(
                            'Registrasi Armada',
                            Icons.app_registration,
                            Color(0xFF1976D2),
                            () => Navigator.pushNamed(context, '/fleet-register'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSubComponent(
                            'Registrasi GPS',
                            Icons.gps_fixed,
                            Color(0xFF7B1FA2),
                            () => _showComingSoon(context, 'Registrasi GPS'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSubComponent(
                            'Integrasi Armada',
                            Icons.integration_instructions,
                            Color(0xFF00796B),
                            () => _showComingSoon(context, 'Integrasi Armada'),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildSubComponent(
                          'Registrasi Armada',
                          Icons.app_registration,
                          Color(0xFF1976D2),
                          () => Navigator.pushNamed(context, '/fleet-register'),
                        ),
                        const SizedBox(height: 12),
                        _buildSubComponent(
                          'Registrasi GPS',
                          Icons.gps_fixed,
                          Color(0xFF7B1FA2),
                          () => _showComingSoon(context, 'Registrasi GPS'),
                        ),
                        const SizedBox(height: 12),
                        _buildSubComponent(
                          'Integrasi Armada',
                          Icons.integration_instructions,
                          Color(0xFF00796B),
                          () => _showComingSoon(context, 'Integrasi Armada'),
                        ),
                      ],
                    );
                  }
                },
              ),
              
              const SizedBox(height: 24),
              
              // Quick Actions
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          return Row(
                            children: [
                              Expanded(
                                child: _buildQuickAction(
                                  'Add Vehicle',
                                  Icons.add_circle,
                                  Color(0xFF1976D2),
                                  () => Navigator.pushNamed(context, '/fleet-register'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickAction(
                                  'Add Driver',
                                  Icons.person_add,
                                  Color(0xFF388E3C),
                                  () => _showComingSoon(context, 'Add Driver'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickAction(
                                  'Fleet Report',
                                  Icons.assessment,
                                  Color(0xFFFF9800),
                                  () => _showComingSoon(context, 'Fleet Report'),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildQuickAction(
                                'Add Vehicle',
                                Icons.add_circle,
                                Color(0xFF1976D2),
                                () => Navigator.pushNamed(context, '/fleet-register'),
                              ),
                              const SizedBox(height: 12),
                              _buildQuickAction(
                                'Add Driver',
                                Icons.person_add,
                                Color(0xFF388E3C),
                                () => _showComingSoon(context, 'Add Driver'),
                              ),
                              const SizedBox(height: 12),
                              _buildQuickAction(
                                'Fleet Report',
                                Icons.assessment,
                                Color(0xFFFF9800),
                                () => _showComingSoon(context, 'Fleet Report'),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFleetCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String description,
    VoidCallback onTap,
  ) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    
    return Card(
      elevation: 8,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isWideScreen ? 20 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: isWideScreen
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, size: 36, color: color),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 28, color: color),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSubComponent(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 6,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}