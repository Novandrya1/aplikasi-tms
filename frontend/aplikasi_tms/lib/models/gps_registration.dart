class GPSRegistration {
  final int id;
  final String registrationNumber;
  final String vehicleType;
  final int capacityTons;
  final String status;
  final String operatorNotes;
  final String adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? approvedAt;
  final int? approvedBy;

  GPSRegistration({
    required this.id,
    required this.registrationNumber,
    required this.vehicleType,
    required this.capacityTons,
    required this.status,
    required this.operatorNotes,
    required this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
    this.approvedAt,
    this.approvedBy,
  });

  factory GPSRegistration.fromJson(Map<String, dynamic> json) {
    return GPSRegistration(
      id: json['id'],
      registrationNumber: json['registration_number'],
      vehicleType: json['vehicle_type'],
      capacityTons: json['capacity_tons'],
      status: json['status'],
      operatorNotes: json['operator_notes'] ?? '',
      adminNotes: json['admin_notes'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      approvedBy: json['approved_by'],
    );
  }
}

class GPSRegistrationRequest {
  final String registrationNumber;
  final String vehicleType;
  final int capacityTons;
  final String operatorNotes;

  GPSRegistrationRequest({
    required this.registrationNumber,
    required this.vehicleType,
    required this.capacityTons,
    required this.operatorNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'registration_number': registrationNumber,
      'vehicle_type': vehicleType,
      'capacity_tons': capacityTons,
      'operator_notes': operatorNotes,
    };
  }
}