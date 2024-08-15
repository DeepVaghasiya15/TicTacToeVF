import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  Future<void> _signUp(BuildContext context) async {
    try {
      if (passwordController.text == confirmPasswordController.text) {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
        // Handle successful registration (e.g., navigate to another screen)
        Navigator.of(context).pop();
        print("User registered: ${userCredential.user?.email}");
      } else {
        _showErrorDialog(context, "Passwords do not match.");
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Signup failed. Please try again.';
      if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      }
      _showErrorDialog(context, message);
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signup Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set the background color to make white text visible
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Sign Up',
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
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                style: const TextStyle(color: Colors.white, fontFamily: 'Lato'), // Set the text color to white
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
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
                onPressed: () => _signUp(context),
                child: const Text('Sign Up', style: TextStyle(fontFamily: 'Lato')),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text(
                  'Already have an account? Log in',
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
