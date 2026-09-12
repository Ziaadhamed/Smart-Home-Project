import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'PreferencesTitle.dart';
import 'lightcontrol.dart';
import 'EnergyMonitor.dart';
import 'EnvMonitor.dart';
import 'sign_in.dart';
import 'preferences.dart';
import 'energysaving1.dart';

class NavigationPage extends StatelessWidget {
  final String signedInEmail;

  NavigationPage({required this.signedInEmail});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut(); // Sign out user from Firebase

      // Clear SharedPreferences data
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('signedInEmail');

      Navigator.of(context).popUntil((route) =>
          route.isFirst); // Pop all routes until you reach the first screen
      Navigator.pushReplacement(
        // Navigate to SignInScreen and clear previous routes
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
    } catch (e) {
      print('Error signing out: $e');
      // Handle sign-out error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Navigation Page',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Color(0xFFCAD4D3),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: Expanded(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFFEFF8EC),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 20),
              CustomButton(
                icon: Icons.settings,
                label: 'Customize Preferences',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            TopCenterRoundedClickableContainer()),
                  );
                },
              ),
              SizedBox(height: 20),
              CustomButton(
                icon: Icons.lightbulb_outline,
                label: 'Lights Control',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LightControlPage()),
                  );
                },
              ),
              SizedBox(height: 20),
              CustomButton(
                icon: Icons.thermostat_outlined,
                label: 'Environment Monitoring',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
              ),
              SizedBox(height: 20),
              CustomButton(
                icon: Icons.battery_charging_full,
                label: 'Energy Saving',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EnergySaving()),
                  );
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF5A5A5A),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Signed in as:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.account_circle,
                        color: Colors.white,
                        size: 40,
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          signedInEmail,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              title: Row(
                children: [
                  Icon(Icons.logout, color: Colors.black87),
                  SizedBox(width: 10),
                  Text('Logout', style: TextStyle(color: Colors.black87)),
                ],
              ),
              onTap: () {
                _signOut(context); // Call sign-out method
              },
            ),
            ListTile(
              title: Row(
                children: [
                  Icon(Icons.email, color: Colors.black87),
                  SizedBox(width: 10),
                  Text(signedInEmail, style: TextStyle(color: Colors.black87)),
                ],
              ),
              onTap: () {
                // Handle email tap
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  CustomButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF5A5A5A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white, size: 40),
          ],
        ),
      ),
    );
  }
}
