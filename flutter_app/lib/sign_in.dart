import 'package:application_part_1_test/Nvigation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async'; // Import for Timer
import 'auth_service.dart';
import 'forget_password.dart';
import 'Nvigation.dart';
import 'sign_up.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  TextEditingController userNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isObscurePassword = true;
  File? capturedImage;
  String message = '';
  bool _isLoading = false;
  Color _messageColor = Colors.black;
  IconData icon = Icons.help_outline;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isEmailVerified = false;
  bool _isEmailFilled = false;
  bool _isEmailValid = false;

  Timer? _messageTimer; // Timer variable
  bool _isCapturingPhoto = false;

  @override
  void initState() {
    super.initState();
    userNameController.addListener(_checkEmailFilled);
  }

  void _checkEmailFilled() {
    setState(() {
      _isEmailFilled = userNameController.text.isNotEmpty;
      _isEmailValid = _validateEmail(userNameController.text);
    });
  }

  bool _validateEmail(String email) {
    // Simple regex for email validation
    String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regex = RegExp(emailPattern);
    return regex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            color: Color(0xffeff8ec),
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpPage()),
                        );
                      },
                      child: Icon(Icons.arrow_back),
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back! 👋',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Login with your registered account',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Icon(
                      icon,
                      color: _messageColor,
                    ),
                  ],
                ),
                SizedBox(height: 40),
                _buildTextField('Your Email', userNameController),
                SizedBox(height: 20),
                _buildPasswordField('Your Password', passwordController),
                SizedBox(height: 40),
                _buildSignInButton(context),
                SizedBox(height: 20),
                _buildSeparator(),
                SizedBox(height: 20),
                _buildCameraButton(context),
                SizedBox(height: 40),
                Text(
                  message,
                  style: TextStyle(color: _messageColor),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ForgetPasswordPage(),
                      ),
                    );
                  },
                  child: Text(
                    'Forget password?',
                    style: TextStyle(
                      color: Colors.black,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String labelText, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
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
              contentPadding:
                  EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(
      String labelText, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xff043205),
            ),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: controller,
            obscureText: _isObscurePassword,
            decoration: InputDecoration(
              hintText: 'Enter $labelText',
              filled: true,
              fillColor: Color(0xffaad1a9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              suffixIcon: IconButton(
                icon: Icon(_isObscurePassword
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _isObscurePassword = !_isObscurePassword;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () async {
                setState(() {
                  _isLoading = true;
                });

                String username = userNameController.text.trim();
                String password = passwordController.text.trim();

                try {
                  UserCredential userCredential =
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: username,
                    password: password,
                  );

                  if (userCredential.user != null) {
                    if (userCredential.user!.emailVerified) {
                      setState(() {
                        _isEmailVerified = true; // Email is verified
                      });

                      // Set the isLoggedIn flag to true
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setBool('isLoggedIn', true);

                      // Save signed-in email
                      await prefs.setString(
                          'signedInEmail', userCredential.user!.email!);

                      // Navigate to the NavigationPage
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NavigationPage(
                            signedInEmail: userCredential.user!.email!,
                          ),
                        ),
                      );
                    } else {
                      _displayMessage(
                          'Please verify your email before proceeding. A verification email has been sent to ${userCredential.user!.email}.',
                          Colors.red);
                      await userCredential.user!.sendEmailVerification();
                    }
                  }
                } catch (e) {
                  _displayMessage(
                      'Sign in failed. Please try again.', Colors.red);
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xff334234),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        ),
        child: _isLoading
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xffffffff),
                ),
              ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.black,
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.black,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    // Validate email format
    if (!_validateEmail(userNameController.text)) {
      _displayMessage('Please enter a valid email format.', Colors.red);
      return;
    }

    setState(() {
      _isCapturingPhoto = true;
    });

    final pickedImage = await ImagePicker().pickImage(source: source);
    if (pickedImage != null) {
      setState(() {
        capturedImage = File(pickedImage.path);
        _isCapturingPhoto = false;
      });

      // Proceed with image upload and verification
      await _uploadAndVerifyImage();
    } else {
      setState(() {
        _isCapturingPhoto = false;
      });
    }
  }

  Future<void> _uploadAndVerifyImage() async {
    String email = userNameController.text.trim();
    try {
      // Get the URL of the saved image from Firebase Storage
      String savedImagePath = 'images/$email/saved_image.jpg';
      String savedImageUrl =
          await FirebaseStorage.instance.ref(savedImagePath).getDownloadURL();

      // Download the saved image file from Firebase Storage
      final savedImageFile =
          File('${(await getTemporaryDirectory()).path}/saved_image.jpg');
      final savedImageResponse = await http.get(Uri.parse(savedImageUrl));
      await savedImageFile.writeAsBytes(savedImageResponse.bodyBytes);

      // Send the captured image and saved image to the Flask API for face recognition
      String flaskUrl = 'http://192.168.1.7:5000/upload';
      var request = http.MultipartRequest('POST', Uri.parse(flaskUrl));
      request.files.add(await http.MultipartFile.fromPath(
          'captured_image', capturedImage!.path));
      request.files.add(await http.MultipartFile.fromPath(
          'saved_image', savedImageFile.path));

      var response = await request.send();
      var responseString = await response.stream.bytesToString();

      _displayMessage(responseString,
          responseString.contains('a match') ? Colors.green : Colors.red);

      if (responseString.contains('a match')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NavigationPage(signedInEmail: email),
          ),
        );
      }
    } catch (e) {
      _displayMessage('Image upload and verification failed. Please try again.',
          Colors.red);
    }
  }

  Widget _buildCameraButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton.icon(
        onPressed: _isEmailFilled && !_isCapturingPhoto
            ? () {
                _pickImage(ImageSource.camera);
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isEmailFilled && !_isCapturingPhoto
              ? Color(0xff334234)
              : Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        ),
        icon: Icon(Icons.camera_alt),
        label: _isCapturingPhoto
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Capture Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xffffffff),
                ),
              ),
      ),
    );
  }

  void _displayMessage(String msg, Color color) {
    setState(() {
      message = msg;
      _messageColor = color;
    });

    // Cancel previous timer if exists
    if (_messageTimer != null && _messageTimer!.isActive) {
      _messageTimer!.cancel();
    }

    // Set new timer to clear message after 5 seconds
    _messageTimer = Timer(Duration(seconds: 3), () {
      setState(() {
        message = '';
      });
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel(); // Cancel timer to prevent memory leaks
    userNameController.removeListener(_checkEmailFilled);
    userNameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
