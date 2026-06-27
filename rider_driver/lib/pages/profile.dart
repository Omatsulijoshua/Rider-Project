import 'package:flutter/material.dart';
import 'package:rider_driver/pages/login.dart';
import 'package:rider_driver/services/auth_service.dart';
import 'package:rider_driver/utils/app_colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _auth = AuthService();
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _walletData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profileResult = await _auth.getProfile();
    final walletResult = await _auth.getWallet();
    
    if (mounted) {
      setState(() {
        if (profileResult['success'] == true) {
          _userData = profileResult['data'];
        }
        if (walletResult['success'] == true) {
          _walletData = walletResult['data'];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar & Name
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _userData?['user']?['name'] ?? _userData?['name'] ?? "Driver Name",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _userData?['user']?['email'] ?? _userData?['email'] ?? "driver@email.com",
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 30),

                  // KYC & Wallet Section
                  _sectionCard([
                    _menuItem(
                      icon: Icons.verified_user_outlined,
                      title: "KYC Verification",
                      subtitle: "Status: ${_userData?['user']?['status'] ?? "Not Verified"}",
                      onTap: () {},
                      iconColor: Colors.blueAccent,
                    ),
                    _menuItem(
                      icon: Icons.wallet_outlined,
                      title: "My Wallet",
                      subtitle: "Balance: ₦${_walletData?['balance']?.toStringAsFixed(2) ?? "0.00"}",
                      onTap: () {},
                      iconColor: Colors.deepPurpleAccent,
                    ),
                    _menuItem(
                      icon: Icons.history,
                      title: "Order History",
                      subtitle: "View all your orders",
                      onTap: () {},
                      iconColor: Colors.blueAccent,
                    ),
                    _menuItem(
                      icon: Icons.help_outline,
                      title: "Help & Support",
                      onTap: () {},
                      iconColor: Colors.blueAccent,
                      showDivider: false,
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // Info Sections
                  _infoCard("Account Details", [
                    _infoRow(Icons.phone, "Phone", _userData?['user']?['phone'] ?? _userData?['phone'] ?? "N/A"),
                    _infoRow(Icons.star_rate, "Average Rating", _userData?['averageRating']?.toString() ?? "N/A"),
                    _infoRow(Icons.verified_user, "Role", "Logistics Partner"),
                    _infoRow(Icons.location_city, "Region", "Lagos, NG"),
                  ]),
                  
                  const SizedBox(height: 20),
                  
                  _infoCard("Vehicle Info", [
                    _infoRow(Icons.motorcycle, "Vehicle Type", "Motorcycle"),
                    _infoRow(Icons.credit_card, "License Plate", "ABC-123-XY"),
                  ]),

                  const SizedBox(height: 40),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _auth.logout();
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text("Logout", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _sectionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(children: children),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required Color iconColor,
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                Icon(icon, size: 28, color: iconColor),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      if (subtitle != null)
                        Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
          if (showDivider)
            const Divider(height: 1, indent: 60, endIndent: 20, color: Colors.black12),
        ],
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const Divider(height: 30),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
