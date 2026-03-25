import 'child_model.dart';

class ParentModel {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final List<ChildModel> children;

  ParentModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.children,
  });

  /// Factory method to create ParentModel from Supabase JSON
  factory ParentModel.fromJson(
    Map<String, dynamic> json, {
    List<ChildModel>? children,
  }) {
    return ParentModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['full_name']?.toString() ?? json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatarUrl:
          json['profile_image_url']?.toString() ??
          json['avatarUrl']?.toString(),
      children: children ?? [],
    );
  }
}
