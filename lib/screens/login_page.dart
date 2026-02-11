import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'candidate_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // ✅ TEST LOGIN (LOCAL LOGIN WITHOUT API)
    if (_emailController.text.trim() == "candidate@gmail.com" &&
        _passwordController.text.trim() == "123456") {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString("token", "dummy_candidate_token");

      await prefs.setInt("login_time", DateTime.now().millisecondsSinceEpoch);

      await prefs.setString("candidate_name", "Test Candidate");
      await prefs.setString("candidate_email", "candidate@gmail.com");
      await prefs.setString("candidate_photo", "");
      await prefs.setString("user_role", "CANDIDATE");

      Fluttertoast.showToast(
        msg: "Welcome Candidate!",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CandidateDashboard()),
      );

      setState(() => _loading = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
          "http://voting-alb-1933918113.eu-north-1.elb.amazonaws.com/auth/login",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "identifier": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
          "app": "CANDIDATE", // 🔑 IMPORTANT
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        Fluttertoast.showToast(
          msg: data["message"] ?? "Login failed",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        setState(() => _loading = false);
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      // ✅ MUST match dashboard
      await prefs.setString("token", data["token"]);

      // ✅ ADD LOGIN TIME (24h session)
      await prefs.setInt("login_time", DateTime.now().millisecondsSinceEpoch);

      // ✅ REQUIRED for drawer
      final user = data["user"];

      await prefs.setString(
        "candidate_name",
        user?["name"]?.toString() ?? "Candidate",
      );

      await prefs.setString(
        "candidate_email",
        user?["email"]?.toString() ?? "",
      );

      await prefs.setString(
        "candidate_photo",
        user?["profile_photo"]?.toString() ?? "",
      );

      // optional
      await prefs.setString("user_role", data["user"]["role"]);

      Fluttertoast.showToast(
        msg: "Welcome Candidate!",

        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CandidateDashboard()),
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Server not reachable",
        backgroundColor: Colors.red,
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            height: constraints.maxHeight,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.white, Colors.blue],
                stops: [0.4, 1.0],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: sw * 0.08),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: sh * 0.05),

                            // LOGO
                            Image.asset(
                              'assets/logo_circle.png',
                              width: 110,
                              height: 110,
                            ),

                            const SizedBox(height: 20),

                            Text(
                              "Candidate Login",
                              style: TextStyle(
                                fontSize: sw * 0.075,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "Access your candidate dashboard",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: sw * 0.04,
                                color: Colors.grey.shade600,
                              ),
                            ),

                            const SizedBox(height: 40),

                            // EMAIL
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: "Email/VOTER ID/PHONE",
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? "Enter email/voter id/phone"
                                  : null,
                            ),
                            const SizedBox(height: 20),

                            // PASSWORD
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: "Password",
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? "Enter password"
                                  : null,
                            ),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Fluttertoast.showToast(
                                    msg: "Password recovery coming soon",
                                    backgroundColor: Colors.blueGrey,
                                  );
                                },
                                child: const Text("Forgot Password?"),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // LOGIN BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _loading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        "Login",
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
