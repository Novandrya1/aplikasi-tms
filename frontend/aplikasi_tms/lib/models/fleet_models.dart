class VehicleRegistration {
  final String registrationNumber;
  final String vehicleType;
  final String brand;
  final String model;
  final int year;
  final String chassisNumber;
  final String engineNumber;
  final String color;
  final double? capacityWeight;
  final double? capacityVolume;
  final String ownershipStatus;
  final String? insuranceCompany;
  final String? insurancePolicyNumber;
  final String? insuranceExpiryDate;
  final String? maintenanceNotes;

  VehicleRegistration({
    required this.registrationNumber,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.year,
    required this.chassisNumber,
    required this.engineNumber,
    required this.color,
    this.capacityWeight,
    this.capacityVolume,
    required this.ownershipStatus,
    this.insuranceCompany,
    this.insurancePolicyNumber,
    this.insuranceExpiryDate,
    this.maintenanceNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'registration_number': registrationNumber,
      'vehicle_type': vehicleType,
      'brand': brand,
      'model': model,
      'year': year,
      'chassis_number': chassisNumber,
      'engine_number': engineNumber,
      'color': color,
      'capacity_weight': capacityWeight,
      'capacity_volume': capacityVolume,
      'ownership_status': ownershipStatus,
      'insurance_company': insuranceCompany,
      'insurance_policy_number': insurancePolicyNumber,
      'insurance_expiry_date': insuranceExpiryDate,
      'maintenance_notes': maintenanceNotes,
    };
  }
}

class FleetOwner {
  final int id;
  final String companyName;
  final String businessLicense;
  final String address;
  final String phoneNumber;
  final String email;
  final String status;

  FleetOwner({
    required this.id,
    required this.companyName,
    required this.businessLicense,
    required this.address,
    required this.phoneNumber,
    required this.email,
    required this.status,
  });

  factory FleetOwner.fromJson(Map<String, dynamic> json) {
    return FleetOwner(
      id: json['id'],
      companyName: json['company_name'],
      businessLicense: json['business_license'],
      address: json['address'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      status: json['status'],
    );
  }
}

class FleetOwnerRequest {
  final String companyName;
  final String businessLicense;
  final String address;
  final String phoneNumber;
  final String email;

  FleetOwnerRequest({
    required this.companyName,
    required this.businessLicense,
    required this.address,
    required this.phoneNumber,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'company_name': companyName,
      'business_license': businessLicense,
      'address': address,
      'phone_number': phoneNumber,
      'email': email,
    };
  }
}