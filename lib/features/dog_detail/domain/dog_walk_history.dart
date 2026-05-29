/// A single walk entry in a dog's history.
class DogWalkHistory {
  final String walkDate;
  final String? volunteerName;
  final int? groupIndex;
  final String? notes;
  final List<GroupDog> groupDogs;

  const DogWalkHistory({
    required this.walkDate,
    this.volunteerName,
    this.groupIndex,
    this.notes,
    this.groupDogs = const [],
  });

  factory DogWalkHistory.fromJson(Map<String, dynamic> json) {
    final dogs = (json['group_dogs'] as List?)
            ?.map((d) => GroupDog.fromJson(d as Map<String, dynamic>))
            .toList() ??
        [];
    final rawDate = json['walk_date'] as String;
    return DogWalkHistory(
      walkDate: rawDate.contains('T') ? rawDate.substring(0, 10) : rawDate,
      volunteerName: json['volunteer_name'] as String?,
      groupIndex: json['group_index'] as int?,
      notes: json['notes'] as String?,
      groupDogs: dogs,
    );
  }
}

/// A dog that was part of the same walk group.
class GroupDog {
  final int dogId;
  final String dogName;

  const GroupDog({required this.dogId, required this.dogName});

  factory GroupDog.fromJson(Map<String, dynamic> json) {
    return GroupDog(
      dogId: json['dog_id'] as int,
      dogName: json['dog_name'] as String,
    );
  }
}
