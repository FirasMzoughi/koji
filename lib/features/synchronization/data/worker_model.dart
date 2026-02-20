class Worker {
  final String id;
  final String firstName;
  final String lastName;
  final String profession;
  final String status;
  final String? profilePictureUrl;
  final String? socialSecurityNumber;
  final String? address;
  final String? idCardUrl;
  final String? phoneNumber;
  final String? email;
  final double? hourlyRate;
  final DateTime? hireDate;

  Worker({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.profession,
    this.status = 'Disponible',
    this.profilePictureUrl,
    this.socialSecurityNumber,
    this.address,
    this.idCardUrl,
    this.phoneNumber,
    this.email,
    this.hourlyRate,
    this.hireDate,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      profession: json['profession'] as String,
      status: json['status'] as String? ?? 'Disponible',
      profilePictureUrl: json['profile_picture_url'] as String?,
      socialSecurityNumber: json['social_security_number'] as String?,
      address: json['address'] as String?,
      idCardUrl: json['id_card_url'] as String?,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      hourlyRate: json['hourly_rate'] != null ? (json['hourly_rate'] as num).toDouble() : null,
      hireDate: json['hire_date'] != null ? DateTime.parse(json['hire_date'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'profession': profession,
      'status': status,
      'profile_picture_url': profilePictureUrl,
      'social_security_number': socialSecurityNumber,
      'address': address,
      'id_card_url': idCardUrl,
      'phone_number': phoneNumber,
      'email': email,
      'hourly_rate': hourlyRate,
      'hire_date': hireDate?.toIso8601String(),
    };
  }
}
