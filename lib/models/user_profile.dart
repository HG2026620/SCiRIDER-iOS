// lib/models/user_profile.dart
class UserProfile {
  final int userId;
  final String userCode;
  final String loginId;
  final String fullName;
  final String email;
  final String mobileNo;
  final String designation;
  final int roleId;
  final bool isAdmin;
  final int defaultCompanyId;
  final int defaultProjectId;
  final int defaultDepartmentId;
  final String defaultFinancialYear;
  final String profileImagePath;

  UserProfile({
    required this.userId,
    required this.userCode,
    required this.loginId,
    required this.fullName,
    required this.email,
    required this.mobileNo,
    required this.designation,
    required this.roleId,
    required this.isAdmin,
    required this.defaultCompanyId,
    required this.defaultProjectId,
    required this.defaultDepartmentId,
    required this.defaultFinancialYear,
    required this.profileImagePath,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      userCode: json['userCode']?.toString() ?? '',
      loginId: json['loginId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobileNo: json['mobileNo']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      roleId: (json['roleId'] as num?)?.toInt() ?? 0,
      isAdmin: json['isAdmin'] == true,
      defaultCompanyId:
          (json['defaultCompanyId'] as num?)?.toInt() ?? 0,
      defaultProjectId:
          (json['defaultProjectId'] as num?)?.toInt() ?? 0,
      defaultDepartmentId:
          (json['defaultDepartmentId'] as num?)?.toInt() ?? 0,
      defaultFinancialYear:
          json['defaultFinancialYear']?.toString() ?? '',
      profileImagePath:
          json['profileImagePath']?.toString() ?? '',
    );
  }
}