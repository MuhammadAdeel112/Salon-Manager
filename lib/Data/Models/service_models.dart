class ServiceModel {
  final String id;
  final String name;
  final double price;
  bool isActive;

  ServiceModel({
    required this.id,
    required this.name,
    required this.price,
    this.isActive = true
  });
}