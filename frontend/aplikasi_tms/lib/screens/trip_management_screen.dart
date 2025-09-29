import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/trip_service.dart';
import '../services/driver_service.dart';
import '../services/vehicle_service.dart';

class TripManagementScreen extends StatefulWidget {
  const TripManagementScreen({super.key});

  @override
  State<TripManagementScreen> createState() => _TripManagementScreenState();
}

class _TripManagementScreenState extends State<TripManagementScreen> with TickerProviderStateMixin {
  List<Trip> trips = [];
  bool isLoading = true;
  String? error;
  Timer? _refreshTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadTrips();
    _startRealTimeUpdates();
  }

  void _startRealTimeUpdates() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadTrips();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await TripService.getTrips();
      setState(() {
        trips = result ?? [];
        isLoading = false;
      });
      if (trips.isEmpty) {
        _animationController.reset();
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      _animationController.reset();
    }
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'planned':
        return Colors.blue;
      case 'ongoing':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'planned':
        return Icons.schedule;
      case 'ongoing':
        return Icons.directions_car;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  void _showAddTripDialog() {
    final originController = TextEditingController();
    final destinationController = TextEditingController();
    final distanceController = TextEditingController();
    int? selectedDriverId;
    int? selectedVehicleId;
    String selectedStatus = 'planned';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Trip'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: originController,
                decoration: const InputDecoration(labelText: 'Origin'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: destinationController,
                decoration: const InputDecoration(labelText: 'Destination'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: distanceController,
                decoration: const InputDecoration(labelText: 'Distance (km)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // Driver Selection
              FutureBuilder<List<Driver>?>(
                future: DriverService.getDrivers(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Driver (Optional)'),
                      value: selectedDriverId,
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('No Driver'),
                        ),
                        ...snapshot.data!.map((driver) => DropdownMenuItem<int>(
                          value: driver.id,
                          child: Text('${driver.user?.fullName ?? 'Driver ${driver.id}'} (${driver.licenseNumber})'),
                        )),
                      ],
                      onChanged: (value) => selectedDriverId = value,
                    );
                  }
                  return const SizedBox(
                    height: 50,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Vehicle Selection
              FutureBuilder<List<dynamic>?>(
                future: VehicleService.getVehicles(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Vehicle (Optional)'),
                      value: selectedVehicleId,
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('No Vehicle'),
                        ),
                        ...snapshot.data!.map((vehicle) => DropdownMenuItem<int>(
                          value: vehicle['id'],
                          child: Text('${vehicle['registration_number']} (${vehicle['brand']} ${vehicle['model']})'),
                        )),
                      ],
                      onChanged: (value) => selectedVehicleId = value,
                    );
                  }
                  return const SizedBox(
                    height: 50,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'planned', child: Text('Planned')),
                  DropdownMenuItem(value: 'ongoing', child: Text('Ongoing')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (value) => selectedStatus = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await TripService.createTrip(
                  driverId: selectedDriverId,
                  vehicleId: selectedVehicleId,
                  origin: originController.text,
                  destination: destinationController.text,
                  status: selectedStatus,
                  distance: distanceController.text.isNotEmpty 
                      ? double.tryParse(distanceController.text) 
                      : null,
                );
                Navigator.pop(context);
                _loadTrips();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trip added successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    _animationController.forward();
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withOpacity(0.2),
                          Colors.blue.withOpacity(0.2),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.local_shipping_outlined,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Belum Ada Aktivitas Trip',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              'Mulai perjalanan pertama Anda dengan\nmenambahkan trip baru',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // Real-time Clock
            StreamBuilder<DateTime>(
              stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
              builder: (context, snapshot) {
                final now = snapshot.data ?? DateTime.now();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, color: Colors.blue[600], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Action Button
            ElevatedButton.icon(
              onPressed: _showAddTripDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Tambah Trip Pertama',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 4,
              ),
            ),
            const SizedBox(height: 16),
            
            // Quick Stats
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickStat('Trips', '0', Icons.route),
                  Container(width: 1, height: 30, color: Colors.grey[300]),
                  _buildQuickStat('Drivers', '0', Icons.person),
                  Container(width: 1, height: 30, color: Colors.grey[300]),
                  _buildQuickStat('Vehicles', '0', Icons.directions_car),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Auto-refresh indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green[300]!),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Auto-refresh setiap 30 detik',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header Stats
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Total Trips', trips.length.toString(), Colors.green),
                _buildStatCard(
                  'Planned', 
                  trips.where((t) => t.status == 'planned').length.toString(), 
                  Colors.blue
                ),
                _buildStatCard(
                  'Ongoing', 
                  trips.where((t) => t.status == 'ongoing').length.toString(), 
                  Colors.orange
                ),
                _buildStatCard(
                  'Completed', 
                  trips.where((t) => t.status == 'completed').length.toString(), 
                  Colors.green
                ),
              ],
            ),
          ),
          
          // Trip List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Gagal memuat data trip',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error: $error',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadTrips,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : trips.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadTrips,
                            child: ListView.builder(
                              itemCount: trips.length,
                              itemBuilder: (context, index) {
                                final trip = trips[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getStatusColor(trip.status),
                                      child: Icon(
                                        _getStatusIcon(trip.status),
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      '${trip.origin} → ${trip.destination}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (trip.driver?.user?.fullName != null)
                                          Text('Driver: ${trip.driver!.user!.fullName}'),
                                        if (trip.vehicle?.registrationNumber != null)
                                          Text('Vehicle: ${trip.vehicle!.registrationNumber}'),
                                        if (trip.distance != null)
                                          Text('Distance: ${trip.distance!.toStringAsFixed(1)} km'),
                                        Text('Created: ${trip.createdAt.toLocal().toString().split('.')[0]}'),
                                      ],
                                    ),
                                    trailing: PopupMenuButton(
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        // Handle menu actions
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTripDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}