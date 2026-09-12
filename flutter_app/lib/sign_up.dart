import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'auth_service.dart';
import 'sign_in.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _isObscurePassword = true;
  bool _isObscureConfirmPassword = true;
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  Color _lineColor = Colors.grey;

  final AuthService _auth = AuthService();
  File? _pickedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Container(
            color: Color(0xffeff8ec),
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Let\'s get started',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff000000),
                  ),
                ),
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create your account to continue ',
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff757373),
                      ),
                    ),
                    Text(
                      '🙌',
                      style: TextStyle(fontSize: 23),
                    ),
                  ],
                ),
                SizedBox(height: 50),
                _buildTextField('Your Email', controller: _usernameController),
                SizedBox(height: 20),
                _buildPasswordField(
                    'Your Password', _passwordController, _isObscurePassword),
                SizedBox(height: 20),
                _buildPasswordField('Confirm Password',
                    _confirmPasswordController, _isObscureConfirmPassword),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    if (_usernameController.text.isNotEmpty &&
                        _validateEmail(_usernameController.text)) {
                      final picker = ImagePicker();
                      final pickedImage =
                          await picker.pickImage(source: ImageSource.camera);
                      if (pickedImage != null) {
                        setState(() {
                          _pickedImage = File(pickedImage.path);
                        });
                        _showMessageDialog(
                            'Success', 'Image captured successfully.');
                      } else {
                        _showErrorDialog('No Image', 'No image selected.');
                      }
                    } else {
                      _showErrorDialog('Invalid Input',
                          'Please enter a valid email address.');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff344334),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  ),
                  child: Text(
                    'Save a Face Picture',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xffffffff),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (!(_usernameController.text.isNotEmpty &&
                          _passwordController.text.isNotEmpty &&
                          _confirmPasswordController.text.isNotEmpty &&
                          _passwordController.text ==
                              _confirmPasswordController.text &&
                          _calculatePasswordStrength(
                                  _passwordController.text) ==
                              Colors.green &&
                          _validateEmail(_usernameController.text))) {
                        _showInvalidInputsDialog();
                      } else {
                        await _signUp();
                        if (_pickedImage != null) {
                          await _saveImage(_pickedImage!);
                          _showMessageDialog(
                              'Success', 'Image saved successfully.');
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignInScreen(),
                          ),
                        );
                      }
                    } catch (e) {
                      _showErrorDialog(
                          'Sign Up Failed', 'Error during sign up: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xffaad1a9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                  ),
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xffffffff),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  height: 2,
                  color: _lineColor,
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff6e6d6d),
                      ),
                    ),
                    SizedBox(width: 5),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignInScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff050d01),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String labelText,
      {TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontFamily: 'Raleway',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xff043205),
          ),
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: controller,
          textAlign: TextAlign.start,
          decoration: InputDecoration(
            hintText: 'Enter $labelText',
            filled: true,
            fillColor: Color(0xffaad1a9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
      String labelText, TextEditingController controller, bool isObscure) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontFamily: 'Raleway',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xff043205),
          ),
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: controller,
          textAlign: TextAlign.start,
          obscureText: isObscure,
          onChanged: (value) {
            setState(() {
              _lineColor = _calculatePasswordStrength(value);
            });
          },
          decoration: InputDecoration(
            hintText: 'Enter $labelText',
            filled: true,
            fillColor: Color(0xffaad1a9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            suffixIcon: IconButton(
              icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  if (labelText == 'Your Password') {
                    _isObscurePassword = !_isObscurePassword;
                  } else {
                    _isObscureConfirmPassword = !_isObscureConfirmPassword;
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showInvalidInputsDialog() {
    _showMessageDialog('Invalid or insufficient inputs',
        'Please make sure all fields are filled correctly and the password strength is adequate.');
  }

  void _showErrorDialog(String title, String message) {
    _showMessageDialog(title, message);
  }

  void _showMessageDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  bool _validateEmail(String email) {
    String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regex = RegExp(emailPattern);
    return regex.hasMatch(email);
  }

  Color _calculatePasswordStrength(String password) {
    if (password.length >= 8 &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return Colors.green; // Strong password
    } else if (password.length >= 6) {
      return Colors.orange; // Medium strength password
    } else if (password.length == 0) {
      return Colors.grey; // Medium strength password
    } else {
      return Colors.red; // Weak password
    }
  }

  Future<void> _saveImage(File image) async {
    try {
      String email = _usernameController.text;
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child('images/$email/saved_image.jpg');
      await ref.putFile(image);
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }

  Future<void> _signUp() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _usernameController.text,
        password: _passwordController.text,
      );
      User? user = userCredential.user;
      if (user != null) {
        await user.sendEmailVerification();
        await _initializeUserDatabase(user.uid);
        _showMessageDialog('Verification Email Sent',
            'Please check your email to verify your account.');
      }
    } catch (e) {
      print('Error signing up: $e');
    }
  }

  Future<void> _initializeUserDatabase(String userId) async {
    try {
      final CollectionReference usersCollection =
          FirebaseFirestore.instance.collection('users');

      // Create the user's document with initial data
      await usersCollection.doc(userId).set({
        'chosen_preference': "Not set",
      });
    } catch (e) {
      print('Error initializing user database: $e');
    }
  }
}
