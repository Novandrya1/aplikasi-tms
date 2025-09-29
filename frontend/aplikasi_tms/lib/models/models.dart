class User {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'user',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'full_name': fullName,
    'role': role,
  };
}

class LoginRequest {
  final String email;
  final String password;
  
  LoginRequest({required this.email, required this.password});
  
  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String fullName;
  final String? role;
  
  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
    this.role,
  });
  
  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'password': password,
    'full_name': fullName,
    if (role != null) 'role': role,
  };
}

class LoginResponse {
  final String token;
  final User user;
  
  LoginResponse({required this.token, required this.user});
  
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      user: User.fromJson(json['user']),
    );
  }
}

class DashboardStats {
  final int totalVehicles;
  final int activeVehicles;
  final int totalDrivers;
  final int activeDrivers;
  final int totalTrips;
  final int ongoingTrips;
  final int completedTrips;
  final double totalDistance;
  final int maintenanceDue;
  
  DashboardStats({
    required this.totalVehicles,
    required this.activeVehicles,
    required this.totalDrivers,
    required this.activeDrivers,
    required this.totalTrips,
    required this.ongoingTrips,
    required this.completedTrips,
    required this.totalDistance,
    required this.maintenanceDue,
  });
  
  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalVehicles: json['total_vehicles'] ?? 0,
      activeVehicles: json['active_vehicles'] ?? 0,
      totalDrivers: json['total_drivers'] ?? 0,
      activeDrivers: json['active_drivers'] ?? 0,
      totalTrips: json['total_trips'] ?? 0,
      ongoingTrips: json['ongoing_trips'] ?? 0,
      completedTrips: json['completed_trips'] ?? 0,
      totalDistance: (json['total_distance'] ?? 0).toDouble(),
      maintenanceDue: json['maintenance_due'] ?? 0,
    );
  }
}

class Vehicle {
  final int id;
  final String registrationNumber;
  final String vehicleType;
  final String brand;
  final String model;
  final int year;
  final String operationalStatus;

  Vehicle({
    required this.id,
    required this.registrationNumber,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.year,
    required this.operationalStatus,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      registrationNumber: json['registration_number'],
      vehicleType: json['vehicle_type'],
      brand: json['brand'],
      model: json['model'],
      year: json['year'],
      operationalStatus: json['operational_status'],
    );
  }
}

class Driver {
  final int id;
  final int userId;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final String status;
  final User? user;

  Driver({
    required this.id,
    required this.userId,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.status,
    this.user,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      userId: json['user_id'],
      licenseNumber: json['license_number'],
      licenseExpiry: DateTime.parse(json['license_expiry']),
      status: json['status'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

class Trip {
  final int id;
  final int? driverId;
  final int? vehicleId;
  final String origin;
  final String destination;
  final String status;
  final double? distance;
  final DateTime createdAt;
  final Driver? driver;
  final Vehicle? vehicle;

  Trip({
    required this.id,
    this.driverId,
    this.vehicleId,
    required this.origin,
    required this.destination,
    required this.status,
    this.distance,
    required this.createdAt,
    this.driver,
    this.vehicle,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      driverId: json['driver_id'],
      vehicleId: json['vehicle_id'],
      origin: json['origin'],
      destination: json['destination'],
      status: json['status'],
      distance: json['distance']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      driver: json['driver'] != null ? Driver.fromJson(json['driver']) : null,
      vehicle: json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
    );
  }
}