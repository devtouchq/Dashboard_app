import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────
//  Login Request
// ─────────────────────────────────────────────────────────────
class LoginRequest extends Equatable {
  final String accId;
  final String username;
  final String password;
  final String module;

  const LoginRequest({
    required this.accId,
    required this.username,
    required this.password,
    this.module = 'EMR',
  });

  Map<String, dynamic> toJson() => {
        'AccId': accId,
        'Username': username,
        'Password': password,
        'Module': module,
      };

  @override
  List<Object?> get props => [accId, username, password, module];
}

// ─────────────────────────────────────────────────────────────
//  Branch
// ─────────────────────────────────────────────────────────────
class Branch extends Equatable {
  final String text; // m_strText  - display name
  final String value; // m_strValue - submit value

  const Branch({required this.text, required this.value});

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        text: (json['m_strText'] ?? '').toString(),
        value: (json['m_strValue'] ?? '').toString(),
      );

  @override
  List<Object?> get props => [text, value];
}

// ─────────────────────────────────────────────────────────────
//  Login Response
// ─────────────────────────────────────────────────────────────
class LoginResponse extends Equatable {
  final bool isSuccess;
  final bool isOtpRequired;
  final String accountId;
  final String authToken;
  final String userId;
  final String module;
  final String uniqueId;
  final List<Branch> branchList;
  final String? redirectUrl;
  final String? errorMessage;

  const LoginResponse({
    required this.isSuccess,
    required this.isOtpRequired,
    required this.accountId,
    required this.authToken,
    required this.userId,
    required this.module,
    required this.uniqueId,
    required this.branchList,
    this.redirectUrl,
    this.errorMessage,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final branches = (json['BranchList'] as List?)
            ?.map((b) => Branch.fromJson(b as Map<String, dynamic>))
            .toList() ??
        const <Branch>[];
    return LoginResponse(
      isSuccess: json['IsSuccess'] == true,
      isOtpRequired: json['IsOtpRequired'] == true,
      accountId: (json['AccountId'] ?? '').toString(),
      authToken: (json['AuthToken'] ?? '').toString(),
      userId: (json['UserID'] ?? '').toString(),
      module: (json['Module'] ?? '').toString(),
      uniqueId: (json['UniqueID'] ?? '').toString(),
      branchList: branches,
      redirectUrl: json['RedirectUrl']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        isSuccess,
        isOtpRequired,
        accountId,
        authToken,
        userId,
        module,
        uniqueId,
        branchList,
        redirectUrl,
        errorMessage,
      ];
}
