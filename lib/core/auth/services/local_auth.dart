import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> checkBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    }
    on PlatformException catch (e) {
      debugPrint('Error checking biometrics: $e');
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      bool canCheckBiometrics = await checkBiometrics();

      if (!canCheckBiometrics) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access SysAdmin App',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    }
    on PlatformException catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    }
  }
}