class ApiConstants {
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String forgotPassword = '/password/email';
  static const String verifyPasswordOtp = '/password/verify-otp';
  static const String resetPassword = '/password/reset';
  static const String user = '/user';
  static const String profile = '/profile';
  static const String changePassword = '/password';
  static const String cameraGroups = '/user/camera-groups';
  static const String cameraGroupsUpdate = '/user/camera-groups/update';
  static const String cameraGroupsDelete = '/user/camera-groups/delete';
  static const String cameraGroupsAssign = '/user/camera-groups/assign';
  static const String cameraGroupsRemove = '/user/camera-groups/remove';
  static const String cameras = '/user/cameras';
  static const String cameraStatuses = '/camera-statuses';

  static String cameraHistory(String id) => '/images/$id/history';
  static String latestImage(String id) => '/cameras/$id/latest-image';
}
