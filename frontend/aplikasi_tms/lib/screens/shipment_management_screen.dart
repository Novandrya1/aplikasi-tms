import 'package:flutter/material.dart';
import 'driver_management_screen.dart';

class ShipmentManagementScreen extends StatefulWidget {
  @override
  _ShipmentManagementScreenState createState() => _ShipmentManagementScreenState();
}

class _ShipmentManagementScreenState extends State<ShipmentManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manajemen Pengiriman'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      'Manajemen Pengiriman',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0,
                      children: [
                        _buildMenuCard(
                          'Buat Pengiriman',
                          Icons.add_box,
                          Colors.blue,
                          () => _navigateToCreateShipment(),
                        ),
                        _buildMenuCard(
                          'Daftar Pengiriman',
                          Icons.list_alt,
                          Colors.blue[600]!,
                          () => _navigateToShipmentList(),
                        ),
                        _buildMenuCard(
                          'Tracking',
                          Icons.track_changes,
                          Colors.blue[700]!,
                          () => _navigateToTracking(),
                        ),
                        _buildMenuCard(
                          'Rute Optimal',
                          Icons.route,
                          Colors.blue[800]!,
                          () => _navigateToRouteOptimization(),
                        ),
                        _buildMenuCard(
                          'Laporan',
                          Icons.assessment,
                          Colors.blue[500]!,
                          () => _navigateToShipmentReports(),
                        ),
                        _buildMenuCard(
                          'Manajemen Driver',
                          Icons.person,
                          Colors.blue[400]!,
                          () => _navigateToDriverManagement(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateShipment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateShipmentScreen()),
    );
  }

  void _navigateToShipmentList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ShipmentListScreen()),
    );
  }

  void _navigateToTracking() {
    _showComingSoon('Tracking');
  }

  void _navigateToRouteOptimization() {
    _showComingSoon('Rute Optimal');
  }

  void _navigateToShipmentReports() {
    _showComingSoon('Laporan Pengiriman');
  }

  void _navigateToDriverManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DriverManagementScreen()),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

class CreateShipmentScreen extends StatefulWidget {
  @override
  _CreateShipmentScreenState createState() => _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends State<CreateShipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Buat Pengiriman',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
              TextFormField(
                controller: _originController,
                decoration: InputDecoration(
                  labelText: 'Alamat Asal',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Wajib diisi' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: 'Alamat Tujuan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Wajib diisi' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: 'Berat (kg)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.scale),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Wajib diisi' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Catatan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Buat Pengiriman',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pengiriman berhasil dibuat!')),
      );
      Navigator.pop(context);
    }
  }
}

class ShipmentListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Pengiriman'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) {
          final statuses = ['Pending', 'In Transit', 'Delivered', 'Cancelled'];
          final colors = [Colors.orange, Colors.blue, Colors.green, Colors.red];
          final status = statuses[index % statuses.length];
          final color = colors[index % colors.length];
          
          return Card(
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color,
                child: Icon(Icons.local_shipping, color: Colors.white),
              ),
              title: Text('Pengiriman #${1000 + index}'),
              subtitle: Text('Jakarta → Surabaya'),
              trailing: Chip(
                label: Text(status),
                backgroundColor: color.withOpacity(0.2),
              ),
              onTap: () {
                _showShipmentDetail(context, index);
              },
            ),
          );
        },
      ),
    );
  }

  void _showShipmentDetail(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Pengiriman #${1000 + index}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Asal: Jakarta'),
            Text('Tujuan: Surabaya'),
            Text('Berat: ${(index + 1) * 10} kg'),
            Text('Driver: Driver ${index + 1}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

