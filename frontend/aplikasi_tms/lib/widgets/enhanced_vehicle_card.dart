import 'package:flutter/material.dart';
import 'verification_status_chip.dart';

class EnhancedVehicleCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final VoidCallback? onTap;
  final VoidCallback? onVerify;
  final bool showActions;
  final bool isCompact;

  const EnhancedVehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.onVerify,
    this.showActions = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = vehicle['verification_status'] ?? 'pending';
    final substatus = vehicle['verification_substatus'] ?? '';
    final priority = vehicle['priority'] ?? 'normal';
    final daysWaiting = vehicle['days_waiting'] ?? 0;
    final ownerType = vehicle['owner_type'] ?? 'individual';
    final isUrgent = daysWaiting > 7 || priority == 'urgent';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: isUrgent ? 4 : 2,
      shadowColor: isUrgent ? Colors.red.withOpacity(0.3) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isUrgent ? Border.all(color: Colors.red.withOpacity(0.3), width: 1) : null,
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                if (!isCompact) ...[
                  SizedBox(height: 12),
                  _buildOwnerInfo(),
                  SizedBox(height: 12),
                  _buildMetadata(),
                ],
                if (showActions) ...[
                  SizedBox(height: 12),
                  _buildActions(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.directions_car,
            color: Colors.blue[600],
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vehicle['registration_number'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PriorityChip(priority: vehicle['priority'] ?? 'normal'),
                ],
              ),
              SizedBox(height: 2),
              Text(
                '${vehicle['brand'] ?? 'N/A'} ${vehicle['model'] ?? 'N/A'} (${vehicle['year'] ?? 'N/A'})',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        VerificationStatusChip(
          status: vehicle['verification_status'] ?? 'pending',
          substatus: vehicle['verification_substatus'],
        ),
      ],
    );
  }

  Widget _buildOwnerInfo() {
    final ownerType = vehicle['owner_type'] ?? 'individual';
    final isCompany = ownerType == 'company';
    final ownerName = isCompany 
        ? (vehicle['company_name'] ?? vehicle['owner_name'])
        : vehicle['owner_name'];

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isCompany ? Colors.blue[100] : Colors.green[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isCompany ? 'Perusahaan' : 'Individu',
              style: TextStyle(
                color: isCompany ? Colors.blue[700] : Colors.green[700],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              ownerName ?? 'N/A',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          if (vehicle['owner_email'] != null)
            Icon(Icons.email, size: 14, color: Colors.grey[500]),
        ],
      ),
    );
  }

  Widget _buildMetadata() {
    final daysWaiting = vehicle['days_waiting'] ?? 0;
    final createdAt = vehicle['created_at'];
    final documentsCount = vehicle['documents_count'] ?? 0;
    final requiredDocs = vehicle['owner_type'] == 'company' ? 8 : 6;

    return Row(
      children: [
        if (daysWaiting > 0) ...[
          Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
          SizedBox(width: 4),
          Text(
            '$daysWaiting hari',
            style: TextStyle(
              color: daysWaiting > 7 ? Colors.red[600] : Colors.grey[600],
              fontSize: 12,
              fontWeight: daysWaiting > 7 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          SizedBox(width: 16),
        ],
        Icon(Icons.folder, size: 14, color: Colors.grey[600]),
        SizedBox(width: 4),
        Text(
          '$documentsCount/$requiredDocs docs',
          style: TextStyle(
            color: documentsCount >= requiredDocs ? Colors.green[600] : Colors.orange[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Spacer(),
        if (createdAt != null)
          Text(
            _formatDate(createdAt),
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final status = vehicle['verification_status'] ?? 'pending';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (status == 'pending' && onVerify != null) ...[
          OutlinedButton.icon(
            onPressed: onVerify,
            icon: Icon(Icons.verified, size: 16),
            label: Text('Verifikasi'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green[600],
              side: BorderSide(color: Colors.green[300]!),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          SizedBox(width: 8),
        ],
        ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(Icons.visibility, size: 16),
          label: Text('Detail'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}

// Compact version for lists
class CompactVehicleCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final VoidCallback? onTap;

  const CompactVehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedVehicleCard(
      vehicle: vehicle,
      onTap: onTap,
      showActions: false,
      isCompact: true,
    );
  }
}