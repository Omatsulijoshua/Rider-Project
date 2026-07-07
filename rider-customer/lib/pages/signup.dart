import 'package:flutter/material.dart';
import 'package:rider/pages/login.dart';
import 'package:rider/service/backend_auth_service.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController =
      TextEditingController(); // ✅ NEW

  final BackendAuthService _authService = BackendAuthService();

  bool isLoading = false;

  Future<void> registration() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        phoneController.text.isEmpty) {
      // ✅ include phone validation

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          "Please fill all the details",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ));
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await _authService.signup(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        phone: phoneController.text.trim(), // ✅ SEND PHONE
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Account Created 🎉 Redirecting...",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          duration: Duration(seconds: 2),
        ));

        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            result['message'] ?? 'Registration failed',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          e.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFefeeed),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              "images/delivery-bike.png",
              fit: BoxFit.cover,
              width: double.infinity,
            ),
            const SizedBox(height: 30.0),

            _buildTextField(nameController, "Name"),
            const SizedBox(height: 20.0),

            _buildTextField(emailController, "Email"),
            const SizedBox(height: 20.0),

            _buildTextField(phoneController, "Phone Number"), // ✅ NEW UI FIELD
            const SizedBox(height: 20.0),

            _buildTextField(passwordController, "Password", isPassword: true),
            const SizedBox(height: 40.0),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Sign Up",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 32.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: registration,
                    child: Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(60),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: const BoxDecoration(
                          color: Color(0xff3a688d),
                          shape: BoxShape.circle,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(Icons.arrow_forward,
                                color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Already have an account?",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Login()),
                    );
                  },
                  child: const Text(
                    "Sign in",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: TextField(
        controller: controller,
        keyboardType:
            hint == "Phone Number" ? TextInputType.phone : TextInputType.text,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black54, fontSize: 23.0),
        ),
      ),
    );
  }
}
