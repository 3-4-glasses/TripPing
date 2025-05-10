import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AuthenticationWindow());
}

class AuthenticationWindow extends StatefulWidget {
  const AuthenticationWindow({super.key});

  @override
  _AuthenticationWindowState createState() => _AuthenticationWindowState();
}

class _AuthenticationWindowState extends State<AuthenticationWindow> {
  // Controllers for email and password fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Error message state
  String? errorMessage;

  Future<void> login() async {
    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        setState(() {
          errorMessage = "Please fill in both fields!";
        });
        return;
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get the ID token asynchronously
        String? idToken = await user.getIdToken();
        // Pass the token to the backend, returns success and decoded user info
      }
        // Navigate to the home screen (or wherever needed)

    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? "An error occurred during sign-in!";
      });
    }
  }


  Future<void> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth = await googleUser
          ?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      UserCredential userCred = await FirebaseAuth.instance
          .signInWithCredential(credential);
      User? user = userCred.user;
      String? tokenId = await user?.getIdToken();
    }on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? "An error occurred during sign-in!";
      });
    }
  }

  Future<void> registerUser() async{
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 160, 205, 195),
                Color.fromARGB(255, 160, 233, 242)
              ],
              begin: Alignment.topCenter,
              end: Alignment.center,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'TripPing',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "Enter your email",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Your email",
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Enter your password",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    obscuringCharacter: "•",
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Your password",
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (errorMessage != null) // Error message
                    Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  Center(
                    child: SizedBox(
                      width: 300,
                      child: ElevatedButton.icon(
                        onPressed: login,
                        icon: Icon(Icons.login_outlined),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        label: const Text(
                          "Login",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      width: 300,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Handle Google login logic here
                        },
                        icon: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                          height: 24,
                          width: 24,
                        ),
                        label: Text("Login with Google",
                            style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(height: 30, thickness: 1),
                      ),
                      Text(
                        '  Don\'t have an account?  ',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      Expanded(
                        child: Divider(height: 30, thickness: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      width: 300,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Handle registration logic
                        },
                        icon: Icon(Icons.app_registration_rounded),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        label: const Text(
                          "Register",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
