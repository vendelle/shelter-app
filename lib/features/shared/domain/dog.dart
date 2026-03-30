class Dog {
  final int id;
  final String name;
  final String shelterId;
  final String kennel;
  final bool archived;

  const Dog({
    required this.id,
    required this.name,
    required this.shelterId,
    required this.kennel,
    this.archived = false,
  });

  factory Dog.fromJson(Map<String, dynamic> json) {
    return Dog(
      id: json['id'] as int,
      name: json['name'] as String,
      shelterId: json['shelterid'] as String,
      kennel: json['kennel'] as String,
      archived: json['archived'] as bool? ?? false,
    );
  }
}
