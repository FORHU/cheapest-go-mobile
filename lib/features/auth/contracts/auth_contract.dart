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

  /// A last check before the account is asked for, matching V2's rules. See #45.
  ///
  /// The form has already said all of this in V2's own words — `auth_form_widgets.dart`
  /// validates every field against the mirrored copy, and nothing reaches here until it
  /// passes. This is the guard for a caller that did not go through the form, so its
  /// wording is a backstop and not what a traveller normally reads.
  ///
  /// **A last name is not required**, because V2 does not require one: its register form
  /// checks `firstName` alone, which is why no "last name is required" message exists to
  /// mirror. Demanding one here turned somebody away that the web would have let in.
  void validate() {
    if (!email.contains('@')) {
      throw ApiError('Enter a valid email', category: ErrorCategory.validation);
    }
    if (password.length < 8) {
      throw ApiError('Password must be at least 8 characters', category: ErrorCategory.validation);
    }
    if (firstName.trim().isEmpty) {
      throw ApiError('First name is required', category: ErrorCategory.validation);
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
