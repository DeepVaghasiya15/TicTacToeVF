import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tic_tac_toe/screens/Vault/AuthScreen.dart';

class LoginScreen extends StatelessWidget {

  final TextEditingController emailController = TextEditingController(text: 'deep@gmail.com');
  final TextEditingController passwordController = TextEditingController(text: '123456');

  // final TextEditingController emailController = TextEditingController();
  // final TextEditingController passwordController = TextEditingController();

  Future<void> _login(BuildContext context) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      // Handle successful login (e.g., navigate to another screen)
      Navigator.push(context, MaterialPageRoute(builder: (BuildContext context)=> AuthScreen()));
      print("Login successful: ${userCredential.user?.email}");
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      } else {
        message = 'Login failed. Please try again.';
      }
      _showErrorDialog(context, message);
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set background color to make white text visible
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Login',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Lato',
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white, fontFamily: 'Lato'), // Set the text color to white
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white, fontFamily: 'Lato'), // Set the label text color to white
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // Set the border color to white
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // Set the border color to white when focused
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                style: const TextStyle(color: Colors.white, fontFamily: 'Lato'), // Set the text color to white
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white, fontFamily: 'Lato'), // Set the label text color to white
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // Set the border color to white
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // Set the border color to white when focused
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _login(context),
                child: const Text('Login', style: TextStyle(fontFamily: 'Lato')),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: const Text(
                  'Don\'t have an account? Sign up',
                  style: TextStyle(color: Colors.grey, fontFamily: 'Lato'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
