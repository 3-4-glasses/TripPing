import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/global_user.dart';

class AuthenticationWindow extends StatefulWidget {
  const AuthenticationWindow({super.key});

  @override
  _AuthenticationWindowState createState() => _AuthenticationWindowState();
}

class _AuthenticationWindowState extends State<AuthenticationWindow> {
  bool isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureReenter = true;
  final RegExp _emailRegex = RegExp(
    r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
  );
  final _formKey = GlobalKey<FormState>();
  String? errorMessage;

  Future<({bool status, String? uid, String? name})> verifyToken(String? idToken) async{
    if(idToken==null) {
      return (status: false, uid: null, name: null);

    }
    final res = await http.post(Uri.parse('https://backend-server-412321340776.us-west1.run.app/user/verify-token'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'tokenReq':idToken
        }));
    if(res.statusCode == 201){
      try{
        final decodedToken = jsonDecode(res.body)['decodedToken'];
        return (status:true, uid:decodedToken['uid'] as String?, name:decodedToken['name'] as String?);

      }catch(er){
        print(er);
        throw(er);
      }
    }else{
      setState(() {
        errorMessage = jsonDecode(res.body)['error'];
      });
      return (status: false, uid: null, name: null);
    }

  }

  Future<void> login() async {
    if (_formKey.currentState!.validate()) {
      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String? idToken = await user.getIdToken();
          final message = await verifyToken(idToken);
          if(message.status){
            if(message.uid!=null && message.name !=null){
              UserSession().uid = message.uid!;
              UserSession().name = message.name!;
              // Navigate to main screen with uid
            }
            else{
              setState(() {
                errorMessage = "An error occurred";
              });
            }
          }

        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          errorMessage = e.message ?? "An error occurred during sign-in!";
        });
      }
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      final googleAuth = await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCred.user;
      final idToken = await user?.getIdToken();
      // Handle navigation
      if(idToken==null) {
        return;
      }
      final message = await verifyToken(idToken);
      if(message.status){
        if(message.uid!=null && message.name !=null){
          UserSession().uid = message.uid!;
          UserSession().name = message.name!;
          // Navigate to main screen with uid
        }
        else{
          setState(() {
            errorMessage = "An error occurred";
          });
        }
      }

    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? "An error occurred during sign-in!";
      });
    }
  }

  Future<void> registerUser() async {
    if (_formKey.currentState!.validate()) {
      final res = await http.post(Uri.parse('https://backend-server-412321340776.us-west1.run.app/user/register'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'user_name':_nameController.text,
            'email':_emailController.text,
            'password':_passwordController.text
          }));
      if(res.statusCode == 201){
        UserSession().uid = jsonDecode(res.body)['userId'];
        UserSession().name = _nameController.text;
        // navigate to amin screen with uid
      }else{
        setState(() {
          errorMessage = jsonDecode(res.body)['error'];
        });
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body:
        Container(
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedAlign(
                      duration: Duration(milliseconds: 300),
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.only(top: isLogin ? 10 : 5),
                        child: Text(
                          'TripPing',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 36,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: SizedBox(
                        height: isLogin ? 40 : 20,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      child:
                      isLogin ? // If its login
                      Column(
                        children: [
                      const Text("Enter your email", style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Your email",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your email';
                          if (!_emailRegex.hasMatch(value)) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text("Enter your password", style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        obscuringCharacter: "•",
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Your password",
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your password';
                          if (value.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      Center(
                        child: SizedBox(
                          width: 300,
                          child: ElevatedButton.icon(
                            onPressed: login,
                            icon: Icon(Icons.login_outlined),
                            label: Text("Login", style: TextStyle(fontSize: 18)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: SizedBox(
                          width: 300,
                          child: ElevatedButton.icon(
                            onPressed: signInWithGoogle,
                            icon: Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                              height: 24,
                              width: 24,
                            ),
                            label: Text("Login with Google", style: TextStyle(fontSize: 18)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: Divider(thickness: 1)),
                          Text(
                            '  Don\'t have an account?  ',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          Expanded(child: Divider(thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: SizedBox(
                          width: 300,
                          child: ElevatedButton.icon(
                            onPressed: (){
                              setState(() {
                                isLogin = !isLogin;
                              });
                            },
                            icon: Icon(Icons.app_registration_rounded),
                            label: Text("Register", style: TextStyle(fontSize: 18)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      )
                        ]
                      )
                          :
                      Column(
                        children: [
                          const Text("Enter your name", style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: "Your name",
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your name';
                              if (value.length < 3) return 'Name must be minimum of 3 letters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text("Enter your email", style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: "Your name",
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your name';
                              if (value.length < 3) return 'Name must be minimum of 3 letters';
                              return null;
                            },
                          ),
                          const Text("Enter your password", style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            obscuringCharacter: "•",
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: "Your password",
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your password';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text("Please re-enter your password", style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmController,
                            obscureText: _obscureReenter,
                            obscuringCharacter: "•",
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: "Your password",
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureReenter ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureReenter = !_obscureReenter;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if(_passwordController.text != _confirmController.text) {
                                return 'Password does not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          if (errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                errorMessage!,
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          const SizedBox(height: 20),
                          Center(
                            child: SizedBox(
                              width: 300,
                              child: ElevatedButton.icon(
                                onPressed: registerUser,
                                icon: Icon(Icons.app_registration_rounded),
                                label: Text("Register", style: TextStyle(fontSize: 18)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: SizedBox(
                              width: 300,
                              child: ElevatedButton.icon(
                                onPressed: (){ setState(() {
                                  isLogin=!isLogin;
                                });},
                                icon: Icon(Icons.arrow_back_rounded),
                                label: Text("Back", style: TextStyle(fontSize: 18)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    )
                  ]
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
