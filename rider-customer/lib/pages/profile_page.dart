import 'package:flutter/material.dart';
import 'package:rider/pages/wallet_page.dart';
import 'package:rider/pages/order_history_screen.dart';
import 'package:rider/service/shared_pref.dart';
import 'package:rider/pages/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? name, email;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    name = await SharedpreferenceHelper().getUserName();
    email = await SharedpreferenceHelper().getUserEmail();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: const Color(0xff6053f8),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xff6053f8),
                child: Icon(Icons.person, size: 80, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              name ?? "User Name",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              email ?? "user@example.com",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            _buildListTile(
              icon: Icons.verified_user_outlined,
              title: "KYC Verification",
              subtitle: "Status: Not Verified",
              onTap: () {
                // Navigate to KYC Page (to be implemented)
              },
            ),
            _buildListTile(
              icon: Icons.account_balance_wallet_outlined,
              title: "My Wallet",
              subtitle: "Balance: ₦0.00",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WalletPage()),
                );
              },
            ),
            _buildListTile(
              icon: Icons.history_outlined,
              title: "Order History",
              subtitle: "View all your orders",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                );
              },
            ),
            _buildListTile(
              icon: Icons.help_outline,
              title: "Help & Support",
              onTap: () {},
            ),
            const Divider(),
            _buildListTile(
              icon: Icons.logout,
              title: "Logout",
              color: Colors.red,
              onTap: () async {
                await SharedpreferenceHelper().saveAccessToken("");
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xff6053f8)),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
