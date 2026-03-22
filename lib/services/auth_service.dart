import 'dart:async';

class AuthService {
  // यह एक सिमुलेटेड डेटाबेस है जिसमें पहले से रजिस्टर्ड यूजर्स हैं
  // वास्तविक एप्लीकेशन में, आप एक वास्तविक डेटाबेस या बैकएंड API का उपयोग करेंगे
  static final List<Map<String, String>> _registeredUsers = [
    {'id': '1', 'username': 'testuser', 'email': 'test@example.com', 'mobile': '1234567890', 'password': 'password123', 'status': 'active', 'refer_code': 'USR12345'},
    {'id': '2', 'username': 'blockeduser', 'email': 'blocked@example.com', 'mobile': '0987654321', 'password': 'password123', 'status': 'blocked', 'refer_code': 'USR54321'},
  ];

  // एक लॉग-इन यूजर सेशन को सिमुलेट करें
  static Map<String, String>? _currentUser;

  Future<String?> register({
    required String username,
    required String mobile,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    // PHP कोड के समान, हम एक छोटी देरी का अनुकरण करते हैं
    await Future.delayed(const Duration(milliseconds: 500));

    if (password != confirmPassword) {
      return "❌ Password or Confirm Password don't match.";
    }

    // डुप्लीकेट यूजरनेम/ईमेल/मोबाइल की जाँच करें
    final isDuplicate = _registeredUsers.any((user) =>
        user['username'] == username ||
        user['email'] == email ||
        user['mobile'] == mobile);

    if (isDuplicate) {
      return "⚠️ Username, Email ya Mobile already exist karta hai.";
    }

    // वास्तविक एप्लीकेशन में, पासवर्ड हैशिंग बैकएंड पर होना चाहिए
    // यहाँ हम इसे सिमुलेट कर रहे हैं, और पासवर्ड को सादे टेक्स्ट में स्टोर कर रहे हैं
    final newUser = {
      'id': (_registeredUsers.length + 1).toString(), // एक साधारण ID जनरेशन
      'username': username,
      'mobile': mobile,
      'email': email,
      'password': password, // सिमुलेशन के लिए सादा पासवर्ड
      'status': 'active',
      'refer_code': 'USR${(10000 + (DateTime.now().millisecondsSinceEpoch % 90000)).toString()}',
    };
    _registeredUsers.add(newUser);
    return null; // सफलता पर null लौटाएँ
  }

  Future<String?> login({
    required String identifier, // ईमेल या मोबाइल
    required String password,
    String? referCode, // वैकल्पिक रेफर कोड
  }) async {
    // PHP कोड के समान, हम एक छोटी देरी का अनुकरण करते हैं
    await Future.delayed(const Duration(milliseconds: 500));

    // यूजर को ईमेल या मोबाइल द्वारा खोजें
    final user = _registeredUsers.firstWhere(
      (u) => u['email'] == identifier || u['mobile'] == identifier,
      orElse: () => {}, // न मिलने पर खाली मैप लौटाएँ
    );

    if (user.isEmpty) {
      return "❌ User not found.";
    }

    if (user['status'] == 'blocked') {
      return "❌ Your account is Suspended!";
    }

    // पासवर्ड वेरिफिकेशन सिमुलेट करें (PHP के password_verify के समान)
    if (user['password'] != password) {
      return "❌ Incorrect password.";
    }

    // रेफर कोड की जाँच करें यदि प्रदान किया गया हो
    if (referCode != null && referCode.isNotEmpty && referCode != user['refer_code']) {
      return "❌ Invalid refer code.";
    }

    _currentUser = user; // सेशन को सिमुलेट करें
    return null; // सफलता
  }

  // यह जाँचने के लिए कि कोई यूजर लॉग इन है या नहीं (सिमुलेटेड)
  bool isLoggedIn() => _currentUser != null;

  // लॉग आउट करने के लिए (सिमुलेटेड)
  void logout() => _currentUser = null;

  // वर्तमान यूजर प्राप्त करने के लिए (सिमुलेटेड)
  Map<String, String>? getCurrentUser() => _currentUser;
}