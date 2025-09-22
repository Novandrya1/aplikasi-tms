import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'vehicle_verification_detail_screen.dart';

class AdminVerificationDashboardScreen extends StatefulWidget {
  const AdminVerificationDashboardScreen({super.key});

  @override
  _AdminVerificationDashboardScreenState createState() => _AdminVerificationDashboardScreenState();
}

class _AdminVerificationDashboardScreenState extends State<AdminVerificationDashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final data = await AdminService.getVerificationDashboard();
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verifikasi Armada'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadDashboardData,
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(Icons.filter_list),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _dashboardData == null
              ? Center(child: Text('Gagal memuat data dashboard'))
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsCards(),
                        SizedBox(height: 24),
                        _buildUrgentItems(),
                        SizedBox(height: 24),
                        _buildRecentSubmissions(),
                        SizedBox(height: 24),
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatsCards() {
    final pendingCount = _dashboardData!['pending_count'] ?? 0;
    final needsCorrectionCount = _dashboardData!['needs_correction_count'] ?? 0;
    final underReviewCount = _dashboardData!['under_review_count'] ?? 0;
    final approvedToday = _dashboardData!['approved_today'] ?? 0;
    final rejectedToday = _dashboardData!['rejected_today'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan Verifikasi',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard(
              'Menunggu Verifikasi',
              pendingCount.toString(),
              Icons.pending,
              Colors.orange,
              () => _navigateToStatusList(AdminService.statusPending),
            ),
            _buildStatCard(
              'Perlu Perbaikan',
              needsCorrectionCount.toString(),
              Icons.warning,
              Colors.amber,
              () => _navigateToStatusList(AdminService.statusNeedsCorrection),
            ),
            _buildStatCard(
              'Sedang Ditinjau',
              underReviewCount.toString(),
              Icons.rate_review,
              Colors.purple,
              () => _navigateToStatusList(AdminService.statusUnderReview),
            ),
            _buildStatCard(
              'Disetujui Hari Ini',
              approvedToday.toString(),
              Icons.check_circle,
              Colors.green,
              () => _navigateToStatusList(AdminService.statusApproved),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Ditolak Hari Ini',
                rejectedToday.toString(),
                Icons.cancel,
                Colors.red,
                () => _navigateToStatusList(AdminService.statusRejected),
              ),
            ),
            SizedBox(width: 16),
            Expanded(child: Container()), // Empty space for alignment
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(height: 12),
              Text(
                count,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrgentItems() {
    final urgentItems = _dashboardData!['urgent_items'] as List? ?? [];
    
    if (urgentItems.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.priority_high, color: Colors.red[600]),
            SizedBox(width: 8),
            Text(
              'Item Mendesak',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${urgentItems.length}',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Card(
          child: Column(
            children: urgentItems.map((item) => _buildUrgentItem(item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildUrgentItem(Map<String, dynamic> item) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.warning, color: Colors.red[600], size: 20),
      ),
      title: Text(
        item['registration_number'] ?? '',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(item['message'] ?? ''),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Text(
          '${item['days_overdue']} hari',
          style: TextStyle(
            color: Colors.red[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      onTap: () => _navigateToVehicleDetail(item['vehicle_id']),
    );
  }

  Widget _buildRecentSubmissions() {
    final recentSubmissions = _dashboardData!['recent_submissions'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: Colors.blue[600]),
            SizedBox(width: 8),
            Text(
              'Pengajuan Terbaru',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            TextButton(
              onPressed: () => _navigateToStatusList('all'),
              child: Text('Lihat Semua'),
            ),
          ],
        ),
        SizedBox(height: 12),
        Card(
          child: recentSubmissions.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada pengajuan terbaru',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: recentSubmissions.take(5).map((submission) => _buildSubmissionItem(submission)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildSubmissionItem(Map<String, dynamic> submission) {
    final status = submission['status'] ?? '';
    final substatus = submission['substatus'] ?? '';
    final priority = submission['priority'] ?? 'normal';
    final daysWaiting = submission['days_waiting'] ?? 0;
    final ownerType = submission['owner_type'] ?? 'individual';

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help;
    String statusText = 'Unknown';

    // Determine status display
    switch (substatus.isNotEmpty ? substatus : status) {
      case 'submitted':
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Menunggu';
        break;
      case 'needs_correction':
        statusColor = Colors.amber;
        statusIcon = Icons.warning;
        statusText = 'Perlu Perbaikan';
        break;
      case 'under_review':
        statusColor = Colors.purple;
        statusIcon = Icons.rate_review;
        statusText = 'Ditinjau';
        break;
      case 'pending_inspection':
        statusColor = Colors.indigo;
        statusIcon = Icons.search;
        statusText = 'Inspeksi';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Disetujui';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Ditolak';
        break;
    }

    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(statusIcon, color: statusColor, size: 20),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              submission['registration_number'] ?? '',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (priority == 'urgent' || priority == 'high')
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: priority == 'urgent' ? Colors.red[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                priority == 'urgent' ? 'URGENT' : 'HIGH',
                style: TextStyle(
                  color: priority == 'urgent' ? Colors.red[700] : Colors.orange[700],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${submission['owner_name']} (${ownerType == 'company' ? 'Perusahaan' : 'Individu'})',
            style: TextStyle(fontSize: 12),
          ),
          SizedBox(height: 2),
          Text(
            '$daysWaiting hari yang lalu',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      onTap: () => _navigateToVehicleDetail(submission['id']),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi Cepat',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildQuickActionCard(
              'Verifikasi Pending',
              Icons.pending_actions,
              Colors.orange,
              () => _navigateToStatusList(AdminService.statusPending),
            ),
            _buildQuickActionCard(
              'Review Manual',
              Icons.rate_review,
              Colors.purple,
              () => _navigateToStatusList(AdminService.statusUnderReview),
            ),
            _buildQuickActionCard(
              'Jadwal Inspeksi',
              Icons.schedule,
              Colors.indigo,
              () => _navigateToStatusList(AdminService.statusPendingInspection),
            ),
            _buildQuickActionCard(
              'Laporan Harian',
              Icons.assessment,
              Colors.blue,
              () => _showDailyReport(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToVehicleDetail(int vehicleId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleVerificationDetailScreen(vehicleId: vehicleId),
      ),
    ).then((_) => _loadDashboardData()); // Refresh when returning
  }

  void _navigateToStatusList(String status) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleStatusListScreen(status: status),
      ),
    ).then((_) => _loadDashboardData()); // Refresh when returning
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Verifikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Semua'),
              leading: Radio<String>(
                value: 'all',
                groupValue: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value!),
              ),
            ),
            ListTile(
              title: Text('Menunggu Verifikasi'),
              leading: Radio<String>(
                value: AdminService.statusPending,
                groupValue: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value!),
              ),
            ),
            ListTile(
              title: Text('Perlu Perbaikan'),
              leading: Radio<String>(
                value: AdminService.statusNeedsCorrection,
                groupValue: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value!),
              ),
            ),
            ListTile(
              title: Text('Sedang Ditinjau'),
              leading: Radio<String>(
                value: AdminService.statusUnderReview,
                groupValue: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToStatusList(_selectedFilter);
            },
            child: Text('Terapkan'),
          ),
        ],
      ),
    );
  }

  void _showDailyReport() {
    final approvedToday = _dashboardData!['approved_today'] ?? 0;
    final rejectedToday = _dashboardData!['rejected_today'] ?? 0;
    final pendingCount = _dashboardData!['pending_count'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Laporan Harian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tanggal: ${DateTime.now().toString().split(' ')[0]}'),
            SizedBox(height: 16),
            _buildReportItem('Disetujui Hari Ini', approvedToday, Colors.green),
            _buildReportItem('Ditolak Hari Ini', rejectedToday, Colors.red),
            _buildReportItem('Masih Pending', pendingCount, Colors.orange),
            SizedBox(height: 16),
            Text(
              'Total Produktivitas: ${approvedToday + rejectedToday} verifikasi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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

  Widget _buildReportItem(String label, int count, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            count.toString(),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

// Vehicle Status List Screen
class VehicleStatusListScreen extends StatefulWidget {
  final String status;

  const VehicleStatusListScreen({super.key, required this.status});

  @override
  _VehicleStatusListScreenState createState() => _VehicleStatusListScreenState();
}

class _VehicleStatusListScreenState extends State<VehicleStatusListScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> vehicles;
      if (widget.status == 'all') {
        vehicles = await AdminService.getAllVehicles();
      } else {
        vehicles = await AdminService.getVehiclesByStatus(widget.status);
      }
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Semua Kendaraan';
    switch (widget.status) {
      case AdminService.statusPending:
        title = 'Menunggu Verifikasi';
        break;
      case AdminService.statusNeedsCorrection:
        title = 'Perlu Perbaikan';
        break;
      case AdminService.statusUnderReview:
        title = 'Sedang Ditinjau';
        break;
      case AdminService.statusApproved:
        title = 'Disetujui';
        break;
      case AdminService.statusRejected:
        title = 'Ditolak';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadVehicles,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'Tidak ada kendaraan dengan status ini',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadVehicles,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = _vehicles[index];
                      return _buildVehicleCard(vehicle);
                    },
                  ),
                ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final status = vehicle['verification_status'] ?? '';
    final substatus = vehicle['verification_substatus'] ?? '';
    final priority = vehicle['priority'] ?? 'normal';
    final daysWaiting = vehicle['days_waiting'] ?? 0;
    final ownerType = vehicle['owner_type'] ?? 'individual';

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help;
    String statusText = 'Unknown';

    // Determine status display
    switch (substatus.isNotEmpty ? substatus : status) {
      case 'submitted':
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Menunggu';
        break;
      case 'needs_correction':
        statusColor = Colors.amber;
        statusIcon = Icons.warning;
        statusText = 'Perlu Perbaikan';
        break;
      case 'under_review':
        statusColor = Colors.purple;
        statusIcon = Icons.rate_review;
        statusText = 'Ditinjau';
        break;
      case 'pending_inspection':
        statusColor = Colors.indigo;
        statusIcon = Icons.search;
        statusText = 'Inspeksi';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Disetujui';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Ditolak';
        break;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(statusIcon, color: statusColor, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                vehicle['registration_number'] ?? '',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (priority == 'urgent' || priority == 'high')
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priority == 'urgent' ? Colors.red[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  priority == 'urgent' ? 'URGENT' : 'HIGH',
                  style: TextStyle(
                    color: priority == 'urgent' ? Colors.red[700] : Colors.orange[700],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${vehicle['brand']} ${vehicle['model']} (${vehicle['year']})'),
            SizedBox(height: 4),
            Text(
              '${vehicle['owner_name']} (${ownerType == 'company' ? 'Perusahaan' : 'Individu'})',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (daysWaiting > 0)
              Text(
                '$daysWaiting hari yang lalu',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleVerificationDetailScreen(vehicleId: vehicle['id']),
          ),
        ).then((_) => _loadVehicles()),
      ),
    );
  }
}