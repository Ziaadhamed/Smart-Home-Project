import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgetPasswordPage extends StatefulWidget {
  @override
  _ForgetPasswordPageState createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();
  bool _isObscureNewPassword = true;
  bool _isObscureRepeatPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffeff8ec),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints:
              BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildTitle(),
                SizedBox(height: 30),
                _buildTextField(
                  labelText: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email,
                ),
                SizedBox(height: 20),
                _buildPasswordField(
                  labelText: 'New Password',
                  controller: _newPasswordController,
                  isObscure: _isObscureNewPassword,
                  toggleVisibility: () {
                    setState(() {
                      _isObscureNewPassword = !_isObscureNewPassword;
                    });
                  },
                  icon: Icons.lock,
                ),
                SizedBox(height: 20),
                _buildPasswordField(
                  labelText: 'Repeat Password',
                  controller: _repeatPasswordController,
                  isObscure: _isObscureRepeatPassword,
                  toggleVisibility: () {
                    setState(() {
                      _isObscureRepeatPassword = !_isObscureRepeatPassword;
                    });
                  },
                  icon: Icons.lock_outline,
                ),
                SizedBox(height: 30),
                _buildResetButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Reset Password',
      style: TextStyle(
        fontFamily: 'Raleway',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xff333333),
      ),
    );
  }

  Widget _buildTextField({
    required String labelText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontFamily: 'Raleway',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xff333333),
          ),
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textAlign: TextAlign.start,
          decoration: InputDecoration(
            hintText: 'Enter $labelText',
            prefixIcon: Icon(icon, color: Color(0xff344334)),
            filled: true,
            fillColor: Colors.grey[200],
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

  Widget _buildPasswordField({
    required String labelText,
    required TextEditingController controller,
    required bool isObscure,
    required VoidCallback toggleVisibility,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontFamily: 'Raleway',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xff333333),
          ),
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: controller,
          textAlign: TextAlign.start,
          obscureText: isObscure,
          decoration: InputDecoration(
            hintText: 'Enter $labelText',
            prefixIcon: Icon(icon, color: Color(0xff344334)),
            suffixIcon: IconButton(
              icon: Icon(isObscure ? Icons.visibility : Icons.visibility_off,
                  color: Color(0xff344334)),
              onPressed: toggleVisibility,
            ),
            filled: true,
            fillColor: Colors.grey[200],
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

  Widget _buildResetButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _resetPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xff344334),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        ),
        child: Text(
          'Reset',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    try {
      if (_newPasswordController.text != _repeatPasswordController.text) {
        throw FirebaseAuthException(
          code: 'passwords-do-not-match',
          message: 'Passwords do not match.',
        );
      }

      User? user = FirebaseAuth.instance.currentUser;

      await user?.updatePassword(_newPasswordController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
