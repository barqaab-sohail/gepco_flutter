class Division {
  final int id;
  final int circle_id;
  final String name;

  Division({required this.id, required this.name, required this.circle_id});

  // Factory method to create an instance from JSON
  factory Division.fromJson(Map<String, dynamic> json) {
    return Division(
      id: json['id'],
      name: json['name'],
      circle_id: json['circle_id'],
    );
  }
}
