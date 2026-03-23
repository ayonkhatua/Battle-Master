import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:battle_master/screens/login_screen.dart'; // Corrected import path

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isChangingPassword = false;

  // Controllers for Profile Edit
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Controllers for Password Reset (Ab Old Password bhi yahan hai)
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- 1. Fetch User Data ---
  Future<void> _fetchProfileData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('username, mobile, email')
          .eq('id', user.id)
          .single();

      setState(() {
        _usernameController.text = response['username'] ?? '';
        _phoneController.text = response['mobile'] ?? '';
        _emailController.text = response['email'] ?? user.email ?? '';
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching profile: $e");
      setState(() => _isLoading = false);
      _showMessage("❌ Failed to load profile.", isError: true);
    }
  }

  // --- 2. Save Profile Data ---
  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Update custom users table
      await Supabase.instance.client.from('users').update({
        'username': _usernameController.text.trim(),
        'mobile': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
      }).eq('id', user.id);

      _showMessage("✅ Profile updated successfully.");
    } catch (e) {
      print("Error updating profile: $e");
      _showMessage("❌ Failed to update profile.", isError: true);
    } finally {
      setState(() => _isSavingProfile = false);
    }
  }

  // --- 3. Change Password (SECURE METHOD) ---
  Future<void> _changePassword() async {
    final oldPass = _oldPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showMessage("⚠️ Please fill all password fields.", isError: true);
      return;
    }

    if (newPass != confirmPass) {
      _showMessage("❌ New password and confirm password do not match.", isError: true);
      return;
    }

    if (newPass.length < 6) {
      _showMessage("⚠️ Password must be at least 6 characters.", isError: true);
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) throw Exception("User not logged in");

      // 1. Verify Old Password by attempting to sign in
      await Supabase.instance.client.auth.signInWithPassword(
        email: user.email!,
        password: oldPass,
      );

      // 2. If it reaches here, Old Password is correct. Update to New Password.
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass),
      );

      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      
      _showMessage("🔑 Password changed successfully!");
      
    } on AuthException catch (e) {
      // Check if the error is because of a wrong old password
      if (e.message.contains("Invalid login credentials") || e.message.contains("Invalid credentials")) {
        _showMessage("❌ Old password is incorrect.", isError: true);
      } else {
        _showMessage("❌ ${e.message}", isError: true);
      }
    } catch (e) {
      print("Error changing password: $e");
      _showMessage("❌ Failed to change password.", isError: true);
    } finally {
      setState(() => _isChangingPassword = false);
    }
  }

  // --- 4. Logout ---
  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      // Navigate to login and clear stack
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print("Logout error: $e");
      _showMessage("❌ Logout failed.", isError: true);
    }
  }

  // Helper method for Snackbars
  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? const Color(0xFF7f1d1d) : const Color(0xFF065f46),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827), // Dark theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF1f2937),
        title: const Text("Profile", style: TextStyle(color: Colors.white, fontSize: 20)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFfacc15)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Profile Picture
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[800],
                        // backgroundImage: const AssetImage('assets/profile.png'), // Uncomment when you add the image
                      ),
                      child: const Icon(Icons.person, size: 60, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Edit Profile Section
                  const Text("Edit Profile", style: TextStyle(fontSize: 18, color: Color(0xFFfacc15), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildInputLabel("Username"),
                  _buildTextField(_usernameController),
                  const SizedBox(height: 15),
                  _buildInputLabel("Phone Number"),
                  _buildTextField(_phoneController, keyboardType: TextInputType.phone),
                  const SizedBox(height: 15),
                  _buildInputLabel("Email"),
                  _buildTextField(_emailController, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 20),
                  _buildButton(
                    text: "Save",
                    isLoading: _isSavingProfile,
                    color: const Color(0xFF2563eb),
                    onPressed: _saveProfile,
                  ),

                  const SizedBox(height: 40),

                  // Reset Password Section
                  const Text("Reset Password", style: TextStyle(fontSize: 18, color: Color(0xFFfacc15), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  // 🔥 OLD PASSWORD FIELD ADDED HERE 🔥
                  _buildInputLabel("Old Password"),
                  _buildTextField(_oldPasswordController, obscureText: true),
                  const SizedBox(height: 15),
                  
                  _buildInputLabel("New Password"),
                  _buildTextField(_newPasswordController, obscureText: true),
                  const SizedBox(height: 15),
                  
                  _buildInputLabel("Confirm New Password"),
                  _buildTextField(_confirmPasswordController, obscureText: true),
                  const SizedBox(height: 20),
                  
                  _buildButton(
                    text: "Reset Password",
                    isLoading: _isChangingPassword,
                    color: const Color(0xFF2563eb),
                    onPressed: _changePassword,
                  ),

                  const SizedBox(height: 40),

                  // Logout Button
                  _buildButton(
                    text: "Logout",
                    isLoading: false,
                    color: const Color(0xFFdc2626), // Red color
                    onPressed: _logout,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // Custom UI Builders
  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF9ca3af))),
    );
  }

  Widget _buildTextField(TextEditingController controller, {bool obscureText = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1f2937),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildButton({required String text, required bool isLoading, required Color color, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
