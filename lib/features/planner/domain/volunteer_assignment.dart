/// A dog assigned to a volunteer in the day plan.
class DogEntry {
  final int dogId;
  final String dogName;
  final String? shelterId;

  /// Kennel/region identifier (e.g. "A1", "B3").
  final String? kennel;

  final String? region;

  /// Group index for color-coding dogs that walk together.
  /// null or 0 = solo walk (no color). 1+ = group number.
  final int? groupIndex;

  /// Optional note (e.g. "hospital", "bring to vet").
  final String? note;

  const DogEntry({
    required this.dogId,
    required this.dogName,
    this.shelterId,
    this.kennel,
    this.region,
    this.groupIndex,
    this.note,
  });

  DogEntry copyWith({
    int? dogId,
    String? dogName,
    String? shelterId,
    String? kennel,
    String? region,
    int? Function()? groupIndex,
    String? Function()? note,
  }) {
    return DogEntry(
      dogId: dogId ?? this.dogId,
      dogName: dogName ?? this.dogName,
      shelterId: shelterId ?? this.shelterId,
      kennel: kennel ?? this.kennel,
      region: region ?? this.region,
      groupIndex: groupIndex != null ? groupIndex() : this.groupIndex,
      note: note != null ? note() : this.note,
    );
  }
}

/// Represents one volunteer's walk assignment for a day.
class VolunteerAssignment {
  final int volunteerId;
  final String volunteerName;
  final List<DogEntry> dogs;

  /// Optional note for the volunteer (e.g. "10-13", "2 dogs only").
  final String? note;

  VolunteerAssignment({
    required this.volunteerId,
    required this.volunteerName,
    List<DogEntry>? dogs,
    this.note,
  }) : dogs = dogs ?? [];

  VolunteerAssignment copyWith({
    int? volunteerId,
    String? volunteerName,
    List<DogEntry>? dogs,
    String? Function()? note,
  }) {
    return VolunteerAssignment(
      volunteerId: volunteerId ?? this.volunteerId,
      volunteerName: volunteerName ?? this.volunteerName,
      dogs: dogs ?? List.of(this.dogs),
      note: note != null ? note() : this.note,
    );
  }
}
