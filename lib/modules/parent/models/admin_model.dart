class AdminModel {
  final int id;
  final String name;
  final String? avatarUrl;
  final String email;
  final String? phoneNumber;
  final bool isActive;

  AdminModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.email,
    this.phoneNumber,
    this.isActive = true,
  });

  /// Factory method to create AdminModel from Supabase JSON
  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['full_name']?.toString() ?? json['name']?.toString() ?? 'مدير النظام',
      avatarUrl: json['profile_image_url']?.toString() ?? json['avatarUrl']?.toString(),
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      isActive: json['is_active'] ?? true,
    );
  }
}
