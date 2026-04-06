enum GoogleSignInFailureCode {
  cancelled,
  missingClientConfiguration,
  noIdToken,
  networkError,
  androidDeveloperError,
  signInFailed,
  backendRejected,
  unexpected,
}

class GoogleSignInFailure {
  const GoogleSignInFailure({
    required this.code,
    required this.message,
    this.rawMessage,
    this.diagnostics = const <String, String>{},
  });

  final GoogleSignInFailureCode code;
  final String message;
  final String? rawMessage;
  final Map<String, String> diagnostics;

  bool get isConfigurationIssue =>
      code == GoogleSignInFailureCode.missingClientConfiguration ||
      code == GoogleSignInFailureCode.noIdToken ||
      code == GoogleSignInFailureCode.androidDeveloperError;
}

class GoogleSignInResult {
  const GoogleSignInResult._({
    required this.success,
    required this.message,
    this.failure,
  });

  const GoogleSignInResult.success({
    required String message,
  }) : this._(success: true, message: message);

  GoogleSignInResult.failure({
    required GoogleSignInFailure failure,
  }) : this._(success: false, message: failure.message, failure: failure);

  final bool success;
  final String message;
  final GoogleSignInFailure? failure;
}
