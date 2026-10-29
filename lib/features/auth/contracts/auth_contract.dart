import 'package:cheapest_go_mobile/shared/auth/roles.dart';
import 'package:cheapest_go_mobile/shared/errors/api_error.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.avatar,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final Role role;
  final String? avatar;

  String get fullName => '$firstName $lastName'.trim();

  factory AuthUser.fromJson(
    Map<String, dynamic> json, {
    String? fallbackEmail,
    String? fallbackFirstName,
    String? fallbackLastName,
  }) {
    final id = (json['id'] ?? '').toString();
    if (id.isEmpty) {
      throw ApiError(
        'Invalid user contract: missing id',
        category: ErrorCategory.validation,
      );
    }
    return AuthUser(
      id: id,
      email: (json['email'] ?? fallbackEmail ?? '').toString(),
      firstName:
          (json['firstName'] ?? json['first_name'] ?? fallbackFirstName ?? '')
              .toString(),
      lastName:
          (json['lastName'] ?? json['last_name'] ?? fallbackLastName ?? '')
              .toString(),
      avatar: (json['avatarUrl'] ?? json['avatar_url'] ?? json['avatar'])
          ?.toString(),
      role: Role.fromString(json['role']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'avatar': avatar,
        'role': role.name,
      };
}

class RegisterInput {
  const RegisterInput({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
  });

  final String email;
  final String password;
  final String firstName;
  final String lastName;

  void validate() {
    if (!email.contains('@')) {
      throw ApiError('Please enter a valid email address.', category: ErrorCategory.validation);
    }
    if (password.length < 8) {
      throw ApiError('Password must be at least 8 characters.', category: ErrorCategory.validation);
    }
    if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
      throw ApiError('First and last name are required.', category: ErrorCategory.validation);
    }
  }

  // Matches `registerSchema` in `cheapestgo-api-v2/src/controllers/auth.controller.ts`
  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'password': password,
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
      };
}
