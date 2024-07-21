class Course {
  final String id;
  final List<List<double>> route;
  final double distance;

  Course({
    required this.id,
    required this.route,
    required this.distance,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      route: (json['route'] as List).map((e) => List<double>.from(e)).toList(),
      distance: json['distance'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'route': route,
      'distance': distance,
    };
  }
}