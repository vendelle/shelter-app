enum VolunteerRole {
  senior,
  independent,
  supporter,
  newHelper;

  static VolunteerRole fromString(String? value) {
    return switch (value) {
      'senior' => VolunteerRole.senior,
      'independent' => VolunteerRole.independent,
      'supporter' => VolunteerRole.supporter,
      _ => VolunteerRole.newHelper,
    };
  }

  String toJson() {
    return switch (this) {
      VolunteerRole.senior => 'senior',
      VolunteerRole.independent => 'independent',
      VolunteerRole.supporter => 'supporter',
      VolunteerRole.newHelper => 'new',
    };
  }

  String get label {
    return switch (this) {
      VolunteerRole.senior => 'Volunteer',
      VolunteerRole.independent => 'Independent supporter',
      VolunteerRole.supporter => 'Supporter',
      VolunteerRole.newHelper => 'New',
    };
  }
}

class Volunteer {
  final int id;
  final String firstName;
  final String lastName;
  final bool archived;
  final VolunteerRole role;

  const Volunteer({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.archived = false,
    this.role = VolunteerRole.newHelper,
  });

  String get fullName => '$firstName $lastName';

  factory Volunteer.fromJson(Map<String, dynamic> json) {
    return Volunteer(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      archived: json['archived'] as bool? ?? false,
      role: VolunteerRole.fromString(json['role'] as String?),
    );
  }
}
