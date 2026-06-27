import 'package:flutter/material.dart';
import 'package:rider/service/api_client.dart';
import 'package:rider/service/widget_support.dart';
import 'package:rider/pages/track_delivery.dart';
import 'package:rider/pages/wallet_page.dart';
import 'package:rider/pages/searching_rider.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final double amount;

  const PaymentPage({
    super.key,
    required this.orderData,
    required this.amount,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedMethod = 'CASH';
  bool _isLoading = false;
  double _walletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchWalletBalance();
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final response = await ApiClient().get('/wallet/me');
      setState(() {
        _walletBalance = (response['balance'] as num).toDouble();
      });
    } catch (e) {
      // If error, assume 0 or handle accordingly
    }
  }

  Future<void> _processOrder() async {
    if (_selectedMethod == 'WALLET' && _walletBalance < widget.amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Insufficient wallet balance!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        ...widget.orderData,
        'paymentMethod': _selectedMethod,
      };

      final response = await ApiClient().post('/orders', body: data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order placed successfully! 🎉"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SearchingRiderPage(order: response),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to place order: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Payment Method"),
        backgroundColor: const Color(0xff6053f8),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order Total: ₦${widget.amount.toStringAsFixed(2)}",
              style: AppWidget.headlineTextFieldStyle(),
            ),
            const SizedBox(height: 30),
            _buildPaymentOption(
              id: 'CASH',
              title: "Pay with Cash",
              subtitle: "Pay the driver upon delivery",
              icon: Icons.money,
            ),
            const SizedBox(height: 15),
            _buildPaymentOption(
              id: 'WALLET',
              title: "Pay with Wallet",
              subtitle: "Balance: ₦${_walletBalance.toStringAsFixed(2)}",
              icon: Icons.account_balance_wallet,
              enabled: _walletBalance >= widget.amount,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff6053f8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Complete Order",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    bool enabled = true,
  }) {
    bool isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: enabled ? () => setState(() => _selectedMethod = id) : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x116053f8) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xff6053f8) : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xff6053f8) : Colors.grey),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: enabled ? Colors.black : Colors.grey,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (enabled)
              Radio<String>(
                value: id,
                groupValue: _selectedMethod,
                onChanged: (v) => setState(() => _selectedMethod = v!),
                activeColor: const Color(0xff6053f8),
              )
            else
              Column(
                children: [
                  const Text(
                    "Insufficient",
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WalletPage()),
                      ).then((_) => _fetchWalletBalance());
                    },
                    child: const Text("Top Up", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
