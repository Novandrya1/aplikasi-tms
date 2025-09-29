import 'package:flutter/material.dart';

class VerificationStatusChip extends StatelessWidget {
  final String status;
  final String? substatus;
  final bool showIcon;
  final double fontSize;

  const VerificationStatusChip({
    super.key,
    required this.status,
    this.substatus,
    this.showIcon = true,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo();
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusInfo.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              statusInfo.icon,
              color: statusInfo.color,
              size: fontSize + 2,
            ),
            SizedBox(width: 4),
          ],
          Text(
            statusInfo.label,
            style: TextStyle(
              color: statusInfo.color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo() {
    final effectiveStatus = substatus?.isNotEmpty == true ? substatus! : status;
    
    switch (effectiveStatus.toLowerCase()) {
      case 'submitted':
      case 'pending':
        return _StatusInfo(
          label: 'Menunggu',
          color: Colors.orange,
          icon: Icons.pending,
        );
      case 'needs_correction':
        return _StatusInfo(
          label: 'Perlu Perbaikan',
          color: Colors.amber,
          icon: Icons.warning,
        );
      case 'under_review':
        return _StatusInfo(
          label: 'Ditinjau',
          color: Colors.purple,
          icon: Icons.rate_review,
        );
      case 'pending_inspection':
        return _StatusInfo(
          label: 'Inspeksi',
          color: Colors.indigo,
          icon: Icons.search,
        );
      case 'auto_validating':
        return _StatusInfo(
          label: 'Validasi Otomatis',
          color: Colors.blue,
          icon: Icons.auto_fix_high,
        );
      case 'approved':
        return _StatusInfo(
          label: 'Disetujui',
          color: Colors.green,
          icon: Icons.check_circle,
        );
      case 'rejected':
        return _StatusInfo(
          label: 'Ditolak',
          color: Colors.red,
          icon: Icons.cancel,
        );
      case 'suspended':
        return _StatusInfo(
          label: 'Ditangguhkan',
          color: Colors.grey,
          icon: Icons.pause_circle,
        );
      default:
        return _StatusInfo(
          label: 'Unknown',
          color: Colors.grey,
          icon: Icons.help,
        );
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  final IconData icon;

  _StatusInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}

// Priority chip widget
class PriorityChip extends StatelessWidget {
  final String priority;
  final double fontSize;

  const PriorityChip({
    super.key,
    required this.priority,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (priority.toLowerCase() == 'normal') {
      return SizedBox.shrink();
    }

    Color color;
    String label;
    
    switch (priority.toLowerCase()) {
      case 'urgent':
        color = Colors.red;
        label = 'URGENT';
        break;
      case 'high':
        color = Colors.orange;
        label = 'HIGH';
        break;
      default:
        return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Document completeness indicator
class DocumentCompletenessIndicator extends StatelessWidget {
  final int uploadedCount;
  final int requiredCount;
  final bool showDetails;

  const DocumentCompletenessIndicator({
    super.key,
    required this.uploadedCount,
    required this.requiredCount,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = uploadedCount >= requiredCount;
    final percentage = (uploadedCount / requiredCount * 100).clamp(0, 100);
    
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isComplete ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isComplete ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.warning,
            color: isComplete ? Colors.green[600] : Colors.orange[600],
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isComplete 
                    ? 'Dokumen Lengkap'
                    : 'Dokumen Belum Lengkap',
                  style: TextStyle(
                    color: isComplete ? Colors.green[700] : Colors.orange[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (showDetails) ...[
                  SizedBox(height: 2),
                  Text(
                    '$uploadedCount dari $requiredCount dokumen (${percentage.toInt()}%)',
                    style: TextStyle(
                      color: isComplete ? Colors.green[600] : Colors.orange[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isComplete)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${requiredCount - uploadedCount}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}