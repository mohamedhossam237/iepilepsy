import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../HomePage.dart';
import '../Model/Patient.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _epilepsyTypeController = TextEditingController();
  String? _gender; // Store the selected gender
  String? _diagnosis; // Store the entered diagnosis
  File? _image; // Store the selected image

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.white60),
      contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.7), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.blue, width: 2),
      ),
    );
  }

  // Function to handle image selection
  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  Future<void> _handleSignUp() async {
    // Validate user input
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _epilepsyTypeController.text.isEmpty ||
        _gender == null ||
        _diagnosis == null) {
      // Show an error message if any field is empty
      _showErrorMessage("Please fill in all fields.");
      return;
    }

    // Check if the passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorMessage("Passwords do not match.");
      return;
    }

    try {
      // Create a Firebase user
      final UserCredential userCredential =
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // User registration successful, proceed to save user data to Firestore

      // Create a new Patient object with the collected information
      final patient = Patient(
        id: userCredential.user!.uid, // Use the UID of the Firebase user as the patient's ID
        name: _nameController.text,
        age: int.tryParse(_ageController.text) ?? 0,
        diagnosis: _diagnosis!,
        gender: _gender!,
        epilepsyType: _epilepsyTypeController.text,
        profileImage: _image != null ? _image!.path : '',
      );

      // Save patient data to Firestore
      await _firestore.collection('patients').doc(patient.id).set({
        'name': patient.name,
        'age': patient.age,
        'diagnosis': patient.diagnosis,
        'gender': patient.gender,
        'epilepsyType': patient.epilepsyType,
        'profileImage': patient.profileImage,
      });

      // Navigate to the home page with the patient data
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(patient: patient),
        ),
      );
    } catch (e) {
      // Handle Firebase sign-up error
      _showErrorMessage("Error signing up. Please try again.");
    }
  }

  void _showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDCA1FF),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _selectImage,
                child: _image == null
                    ? CircleAvatar(
                  radius: 50,
                  backgroundImage:
                  AssetImage('assets/default_avatar.jpg'),
                )
                    : CircleAvatar(
                  radius: 50,
                  backgroundImage: FileImage(_image!),
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: _selectImage,
                child: Text(
                  'Select Profile Picture',
                  style: TextStyle(color: Colors.amber),
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _nameController,
                  decoration: _inputDecoration("Enter Name"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _emailController,
                  decoration: _inputDecoration("Enter Email"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _inputDecoration("Enter Password"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: _inputDecoration("Confirm Password"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration("Enter Age"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _epilepsyTypeController,
                  decoration: _inputDecoration("Enter Epilepsy Type"),
                ),
              ),
              SizedBox(height: 10),
              // Radio buttons for gender selection
              Row(
                children: [
                  SizedBox(width: 10),
                  Text('Gender: ',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                  Radio(
                    value: 'Male',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value.toString();
                      });
                    },
                  ),
                  Text('Male',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                  Radio(
                    value: 'Female',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value.toString();
                      });
                    },
                  ),
                  Text('Female',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ],
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _diagnosis = value;
                    });
                  },
                  decoration: _inputDecoration("Enter Diagnosis"),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _handleSignUp, // Call _handleSignUp to initiate sign-up
                style: ElevatedButton.styleFrom(
                  primary: Colors.amber,
                  onPrimary: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text("Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _epilepsyTypeController.dispose();
    super.dispose();
  }
}
