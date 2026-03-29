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

  // Controllers for Password Reset
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

      if (mounted) {
        setState(() {
          _usernameController.text = response['username'] ?? '';
          _phoneController.text = response['mobile'] ?? '';
          _emailController.text = response['email'] ?? user.email ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      if (mounted) setState(() => _isLoading = false);
      _showMessage("❌ Failed to load profile.", isError: true);
    }
  }

  // --- 2. Save Profile Data ---
  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // 🌟 FIX: Email ko yahan se hata diya hai taaki DB me update na jaye
      await Supabase.instance.client.from('users').update({
        'username': _usernameController.text.trim(),
        'mobile': _phoneController.text.trim(),
      }).eq('id', user.id);

      _showMessage("✅ Profile updated successfully.");
    } catch (e) {
      debugPrint("Error updating profile: $e");
      _showMessage("❌ Failed to update profile.", isError: true);
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
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

      // Verify Old Password
      await Supabase.instance.client.auth.signInWithPassword(
        email: user.email!,
        password: oldPass,
      );

      // Update to New Password
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass),
      );

      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      
      _showMessage("🔑 Password changed successfully!");
      
    } on AuthException catch (e) {
      if (e.message.contains("Invalid login credentials") || e.message.contains("Invalid credentials")) {
        _showMessage("❌ Old password is incorrect.", isError: true);
      } else {
        _showMessage("❌ ${e.message}", isError: true);
      }
    } catch (e) {
      debugPrint("Error changing password: $e");
      _showMessage("❌ Failed to change password.", isError: true);
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  // --- 4. Logout ---
  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Logout error: $e");
      _showMessage("❌ Logout failed.", isError: true);
    }
  }

  // Helper method for Snackbars
  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), // 🌟 Deep Dark Esports Theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("MY PROFILE", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF3B82F6)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🌟 Premium Avatar Section
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.2), blurRadius: 20, spreadRadius: 2)
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF1E293B),
                        child: Text(
                          _usernameController.text.isNotEmpty ? _usernameController.text[0].toUpperCase() : "?",
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      _usernameController.text.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 🌟 Personal Details Section
                  _buildSectionHeader("PERSONAL DETAILS", Icons.person),
                  const SizedBox(height: 15),
                  _buildTextField(_usernameController, "Username", Icons.badge),
                  const SizedBox(height: 15),
                  _buildTextField(_phoneController, "Phone Number", Icons.phone, keyboardType: TextInputType.phone),
                  const SizedBox(height: 15),
                  
                  // 🌟 FIX: Email is now Read-Only with a Lock Icon
                  _buildTextField(_emailController, "Email Address", Icons.email, keyboardType: TextInputType.emailAddress, isReadOnly: true),
                  
                  const SizedBox(height: 20),
                  _buildButton(
                    text: "SAVE PROFILE",
                    isLoading: _isSavingProfile,
                    color: const Color(0xFF3B82F6), // Blue
                    icon: Icons.save_rounded,
                    onPressed: _saveProfile,
                  ),

                  const SizedBox(height: 40),

                  // 🌟 Security Section
                  _buildSectionHeader("SECURITY", Icons.security),
                  const SizedBox(height: 15),
                  _buildTextField(_oldPasswordController, "Old Password", Icons.lock_clock, obscureText: true),
                  const SizedBox(height: 15),
                  _buildTextField(_newPasswordController, "New Password", Icons.lock_reset, obscureText: true),
                  const SizedBox(height: 15),
                  _buildTextField(_confirmPasswordController, "Confirm New Password", Icons.lock, obscureText: true),
                  const SizedBox(height: 20),
                  _buildButton(
                    text: "UPDATE PASSWORD",
                    isLoading: _isChangingPassword,
                    color: const Color(0xFF10B981), // Green
                    icon: Icons.key_rounded,
                    onPressed: _changePassword,
                  ),

                  const SizedBox(height: 40),

                  // 🌟 Danger Zone
                  _buildSectionHeader("DANGER ZONE", Icons.warning_rounded, color: const Color(0xFFEF4444)),
                  const SizedBox(height: 15),
                  _buildButton(
                    text: "LOGOUT",
                    isLoading: false,
                    color: const Color(0xFFEF4444), // Red
                    icon: Icons.logout_rounded,
                    onPressed: _logout,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // Custom UI Builders
  Widget _buildSectionHeader(String title, IconData icon, {Color color = const Color(0xFFFACC15)}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
      ],
    );
  }

  // 🌟 FIX: isReadOnly parameter added
  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool obscureText = false, TextInputType keyboardType = TextInputType.text, bool isReadOnly = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      readOnly: isReadOnly, // Field locked if true
      style: TextStyle(color: isReadOnly ? Colors.white54 : Colors.white, fontSize: 14, fontWeight: FontWeight.w600), // Dim text if locked
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        prefixIcon: Icon(icon, color: isReadOnly ? Colors.grey : const Color(0xFF3B82F6), size: 20),
        
        // Lock icon added if readOnly
        suffixIcon: isReadOnly ? const Icon(Icons.lock, color: Colors.white38, size: 18) : null,
        
        filled: true,
        // Darker background if locked
        fillColor: isReadOnly ? const Color(0xFF0F172A).withOpacity(0.5) : const Color(0xFF1E293B).withOpacity(0.8), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isReadOnly ? Colors.transparent : const Color(0xFF3B82F6), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildButton({required String text, required bool isLoading, required Color color, required IconData icon, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: color.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.0)),
                ],
              ),
      ),
    );
  }
}