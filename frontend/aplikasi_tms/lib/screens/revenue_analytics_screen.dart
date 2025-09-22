import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';

class RevenueAnalyticsScreen extends StatefulWidget {
  @override
  _RevenueAnalyticsScreenState createState() => _RevenueAnalyticsScreenState();
}

class _RevenueAnalyticsScreenState extends State<RevenueAnalyticsScreen> {
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  int _selectedDays = 30;

  final List<int> _dayOptions = [7, 30, 90, 365];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final analytics = await DashboardService.getRevenueAnalytics(days: _selectedDays);
      setState(() {
        _analytics = analytics;
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
        title: Text('Revenue Analytics'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<int>(
            icon: Icon(Icons.date_range),
            onSelected: (days) {
              setState(() => _selectedDays = days);
              _loadAnalytics();
            },
            itemBuilder: (context) => _dayOptions.map((days) {
              return PopupMenuItem(
                value: days,
                child: Text('${days} Hari Terakhir'),
              );
            }).toList(),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodInfo(),
                    SizedBox(height: 16),
                    _buildSummaryCards(),
                    SizedBox(height: 16),
                    _buildDailyChart(),
                    SizedBox(height: 16),
                    _buildVehiclePerformance(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.purple[600]),
            SizedBox(width: 8),
            Text(
              'Periode: $_selectedDays Hari Terakhir',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalRevenue = _analytics['total_revenue']?.toDouble() ?? 0.0;
    final totalExpenses = _analytics['total_expenses']?.toDouble() ?? 0.0;
    final totalProfit = _analytics['total_profit']?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan Keuangan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Pendapatan',
                DashboardService.formatCurrency(totalRevenue),
                Colors.green,
                Icons.trending_up,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                'Total Pengeluaran',
                DashboardService.formatCurrency(totalExpenses),
                Colors.red,
                Icons.trending_down,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        _buildSummaryCard(
          'Keuntungan Bersih',
          DashboardService.formatCurrency(totalProfit),
          totalProfit >= 0 ? Colors.blue : Colors.red,
          totalProfit >= 0 ? Icons.account_balance_wallet : Icons.warning,
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon, {
    bool isWide = false,
  }) {
    return Card(
      child: Container(
        width: isWide ? double.infinity : null,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isWide ? 20 : 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChart() {
    final dailyData = _analytics['daily_data'] as List<dynamic>? ?? [];
    
    if (dailyData.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Grafik Harian',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text('Tidak ada data untuk periode ini'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tren Pendapatan Harian',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: dailyData.length,
                itemBuilder: (context, index) {
                  final data = dailyData[index];
                  final revenue = data['revenue']?.toDouble() ?? 0.0;
                  final profit = data['profit']?.toDouble() ?? 0.0;
                  final date = data['date'] ?? '';
                  
                  return Container(
                    width: 80,
                    margin: EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: 60,
                            decoration: BoxDecoration(
                              color: profit >= 0 ? Colors.green[100] : Colors.red[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: (revenue / 1000000) * 100, // Scale for display
                                  width: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[400],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Container(
                                  height: (profit.abs() / 1000000) * 100, // Scale for display
                                  width: 30,
                                  decoration: BoxDecoration(
                                    color: profit >= 0 ? Colors.green[400] : Colors.red[400],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          date.split('-').last,
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Pendapatan', Colors.blue[400]!),
                SizedBox(width: 16),
                _buildLegendItem('Keuntungan', Colors.green[400]!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildVehiclePerformance() {
    final vehiclePerformance = _analytics['vehicle_performance'] as List<dynamic>? ?? [];
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performa Kendaraan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            if (vehiclePerformance.isEmpty)
              Text('Tidak ada data performa kendaraan')
            else
              ...vehiclePerformance.map((vehicle) => _buildVehiclePerformanceItem(vehicle)),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiclePerformanceItem(Map<String, dynamic> vehicle) {
    final revenue = vehicle['revenue']?.toDouble() ?? 0.0;
    final profit = vehicle['profit']?.toDouble() ?? 0.0;
    final tripCount = vehicle['trip_count'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle['registration_number'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      vehicle['vehicle_name'] ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$tripCount trip',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pendapatan',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      DashboardService.formatCurrency(revenue),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keuntungan',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      DashboardService.formatCurrency(profit),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: profit >= 0 ? Colors.blue[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}