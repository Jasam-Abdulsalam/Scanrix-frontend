import 'package:equatable/equatable.dart';

/// Mirrors the backend's `UserResponse` schema (`app/schemas/user.py`).
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, name, createdAt];
}
