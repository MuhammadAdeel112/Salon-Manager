class EmployeeModel {
  final String id;
  final String fullName;
  final String type; // 'Commission' or 'Fixed'
  final double rate; // Percentage or Salary
  final bool isActive;

  EmployeeModel({required this.id, required this.fullName, required this.type, required this.rate, this.isActive = true});
}