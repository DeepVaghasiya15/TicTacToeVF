import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tic_tac_toe/screens/Vault/HomePage.dart';
import 'package:local_auth/local_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

// Fingerprint or FaceID Support state
enum SupportState {
  unknown,
  supported,
  unSupported,
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  SupportState supportState = SupportState.unknown;
  List<BiometricType>? availableBiometric;
  String? backgroundImagePath;

  @override
  void initState() {
    super.initState();
    auth.isDeviceSupported().then(
            (bool isSupported) => setState(() => supportState = isSupported ? SupportState.supported : SupportState.unSupported));
    checkBiometric();
    getAvailableBiometrics();
    // loadBackgroundImagePath();
  }

  // For checking biometrics
  Future<void> checkBiometric() async {
    late bool canCheckBiometric;
    try {
      canCheckBiometric = await auth.canCheckBiometrics;
      print("Biometric Supported: $canCheckBiometric");
    } on PlatformException catch (e) {
      print(e);
      canCheckBiometric = false;
    }
  }

  // Getting available Biometrics
  Future<void> getAvailableBiometrics() async {
    late List<BiometricType> biometricTypes;
    try {
      biometricTypes = await auth.getAvailableBiometrics();
      print("Supported Biometrics $biometricTypes");
    } on PlatformException catch (e) {
      print(e);
    }
    setState(() {
      availableBiometric = biometricTypes;
    });
  }

  // Authenticating with your biometrics
  Future<void> authenticateWithBiometrics() async {
    try {
      final authenticated = await auth.authenticate(
        localizedReason: 'Authenticate with Fingerprint or Face ID',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (authenticated) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        print("Authentication failed");
      }
    } on PlatformException catch (e) {
      print("Authentication error: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          "Authentication ",
          style: TextStyle(
            fontFamily: 'Lato',
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // FaceID Image
                Image.asset(
                  'assets/QuickShieldLogoMain.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.fitHeight,
                ),
                const SizedBox(height: 10),
                const Text.rich(
                  TextSpan(
                    text: "Powered by ",style: TextStyle(fontFamily: 'Lato',color: Colors.white),
                    children: <TextSpan>[
                      TextSpan(text: "QuickShield",style: TextStyle(fontFamily: 'Lato',color: Colors.green,fontWeight: FontWeight.bold))
                    ]
                  )
                ),
                // const Text("Powered by QuickShield",style: TextStyle(color: Colors.green),),
                const SizedBox(height: 80),
                // Button for authenticate
                Padding(
                  padding: const EdgeInsets.only(left: 18.0, right: 18.0),
                  child: ElevatedButton(
                    onPressed: authenticateWithBiometrics,
                    child: const Text.rich(
                      TextSpan(
                        text: "Authenticate with ",
                        style: TextStyle(fontFamily: 'Lato', fontSize: 15),
                        children: <TextSpan>[
                          TextSpan(
                            text: "Fingerprint",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          TextSpan(
                            text: " or ",
                            style: TextStyle(fontFamily: 'Lato', fontSize: 15),
                          ),
                          TextSpan(
                            text: "Face ID",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
