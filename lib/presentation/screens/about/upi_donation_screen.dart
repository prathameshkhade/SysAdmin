import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class UpiDonationScreen extends StatefulWidget {
  const UpiDonationScreen({super.key});

  @override
  State<UpiDonationScreen> createState() => _UpiDonationScreenState();
}

class _UpiDonationScreenState extends State<UpiDonationScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isProcessing = false;
  String? _amountError;

  // UPI Payment options
  final List<Map<String, dynamic>> _upiOptions = [
    {
      'name': 'UPI',
      'icon': Icons.account_balance_wallet,
      'color': const Color(0xFF00C853),
      'packageName': 'upi'
    },
    {
      'name': 'Google Pay',
      'icon': Icons.g_mobiledata,
      'color': const Color(0xFF4285F4),
      'packageName': 'com.google.android.apps.nbu.paisa.user'
    },
    {
      'name': 'PhonePe',
      'icon': Icons.phone_android,
      'color': const Color(0xFF5F259F),
      'packageName': 'com.phonepe.app'
    },
    {
      'name': 'Paytm',
      'icon': Icons.payment,
      'color': const Color(0xFF00BAF2),
      'packageName': 'net.one97.paytm'
    },
    {
      'name': 'Amazon Pay',
      'icon': Icons.shopping_bag,
      'color': const Color(0xFFFF9900),
      'packageName': 'in.amazon.mShop.android.shopping'
    },
    {
      'name': 'BHIM',
      'icon': Icons.account_balance,
      'color': const Color(0xFF1976D2),
      'packageName': 'in.org.npci.upiapp'
    },
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount <= 0) {
      return 'Amount must be greater than ₹0';
    }

    if (amount > 100000) {
      return 'Amount cannot exceed ₹1,00,000';
    }

    return null;
  }

  void _onAmountChanged(String value) {
    setState(() {
      _amountError = _validateAmount(value);
    });
  }

  Future<void> _processUpiPayment(String appPackage) async {
    // Validate amount first
    final error = _validateAmount(_amountController.text);
    if (error != null) {
      setState(() {
        _amountError = error;
      });
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final amount = _amountController.text.trim();

      // UPI URL format
      String upiUrl = 'upi://pay?pa=pkhade2865@okaxis&pn=Prathamesh%20Khade&am=$amount&cu=INR&tn=SysAdmin%20Donation';

      // For specific apps, add package parameter
      if (appPackage != 'upi') {
        upiUrl += '&mc=0000&mode=02&purpose=00';
      }

      final Uri uri = Uri.parse(upiUrl);

      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        // Show processing dialog
        if (mounted) {
          _showProcessingDialog();
        }
      } else {
        throw Exception('Could not launch UPI app');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing payment...'),
              SizedBox(height: 8),
              Text(
                'Please complete the payment in your UPI app',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showThankYouDialog();
              },
              child: const Text('Payment Done'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment cancelled'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showThankYouDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(
            Icons.favorite,
            color: Colors.red,
            size: 48,
          ),
          title: const Text('Thank You!'),
          content: Text(
            'Thank you for your generous donation of ₹${_amountController.text}!\n\nYour support helps keep SysAdmin development active.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to about screen
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUpiOption(Map<String, dynamic> option) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: option['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            option['icon'],
            color: option['color'],
            size: 24,
          ),
        ),
        title: Text(
          option['name'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: _isProcessing ? null : () => _processUpiPayment(option['packageName']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Support Development',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: const Text(
              'Support SysAdmin Development',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          const Divider(color: Colors.grey, height: 1),

          // Amount Input Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Amount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _amountError != null ? Colors.red : Colors.grey.shade700,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _amountController,
                    onChanged: _onAmountChanged,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          '₹',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                if (_amountError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _amountError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(color: Colors.grey, height: 1),

          // Pay with Section
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Pay with',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // UPI Options
          Expanded(
            child: ListView.builder(
              itemCount: _upiOptions.length,
              itemBuilder: (context, index) {
                return _buildUpiOption(_upiOptions[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}