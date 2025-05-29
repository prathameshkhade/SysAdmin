import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sysadmin/core/utils/color_extension.dart';
import 'package:sysadmin/core/utils/util.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

class Upi extends StatefulWidget {
  const Upi({super.key});

  @override
  State<Upi> createState() => _UpiState();
}

class _UpiState extends State<Upi> {
  late final TextEditingController amountController;

  // UPI Payment Options
  final List<Map<String, dynamic>> _upiOptions = [
    {
      "asset": "assets/about/upi.svg",
      "title": "UPI"
    },
    {
      "asset": "assets/about/google-pay.svg",
      "title": "Google Pay"
    },
    {
      "asset": "assets/about/phonepe.svg",
      "title": "PhonePe"
    },
    {
      "asset": "assets/about/paytm.svg",
      "title": "Paytm"
    },
  ];

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an amount';
    }

    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }

    if (amount > 100000) {
      return 'Amount cannot exceed ₹1,00,000';
    }

    return null;
  }

  Future<void> _launchUpiApp(String appTitle) async {
    final amountText = amountController.text.trim();
    final validation = _validateAmount(amountText);

    if (validation != null) {
      Util.showMsg(context: context, msg: validation);
      return;
    }

    final amount = double.parse(amountText);
    final formattedAmount = amount.toStringAsFixed(2);

    // Replace with your actual UPI ID
    const upiId = "pkhade2865@okaxis";
    const payeeName = "SysAdmin Development";
    const transactionNote = "Donation for SysAdmin App";

    String upiUrl;

    switch (appTitle.toLowerCase()) {
      case 'google pay':
        upiUrl = "tez://upi/pay?pa=$upiId&pn=${Uri.encodeComponent(payeeName)}&am=$formattedAmount&tn=${Uri.encodeComponent(transactionNote)}&cu=INR";
        break;
      case 'phonepe':
        upiUrl = "phonepe://pay?pa=$upiId&pn=${Uri.encodeComponent(payeeName)}&am=$formattedAmount&tn=${Uri.encodeComponent(transactionNote)}&cu=INR";
        break;
      case 'paytm':
        upiUrl = "paytmmp://pay?pa=$upiId&pn=${Uri.encodeComponent(payeeName)}&am=$formattedAmount&tn=${Uri.encodeComponent(transactionNote)}&cu=INR";
        break;
      default: // Generic UPI
        upiUrl = "upi://pay?pa=$upiId&pn=${Uri.encodeComponent(payeeName)}&am=$formattedAmount&tn=${Uri.encodeComponent(transactionNote)}&cu=INR";
        break;
    }

    try {
      final Uri uri = Uri.parse(upiUrl);
      bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!launched) {
        // Fallback to generic UPI URL if specific app URL fails
        final genericUpiUrl = "upi://pay?pa=$upiId&pn=${Uri.encodeComponent(payeeName)}&am=$formattedAmount&tn=${Uri.encodeComponent(transactionNote)}&cu=INR";
        final Uri genericUri = Uri.parse(genericUpiUrl);
        launched = await launchUrl(genericUri, mode: LaunchMode.externalApplication);

        if (!launched) {
          if (mounted) {
            Util.showMsg(
                context: context,
                msg: '$appTitle is not installed or UPI is not available on this device'
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Util.showMsg(
            context: context,
            msg: 'Error launching $appTitle: ${e.toString()}'
        );
      }
    }
  }

  Widget _buildUpiOptions(String asset, String title) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(bottom: 5.0),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.inverseSurface.useOpacity(0.2),
                width: 0.9,
              )
          )
      ),
      child: ListTile(
          contentPadding: const EdgeInsets.only(left: 8.0, right: 4.0),
          titleAlignment: ListTileTitleAlignment.titleHeight,
          titleTextStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 17),
          leading: SizedBox(
              width: 50,
              child: SvgPicture.asset(asset, width: 30, height: 30)),
          title: Text(title),
          trailing: Icon(Icons.chevron_right_sharp, color: theme.colorScheme.primary),
          onTap: () => _launchUpiApp(title)
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const commonStyle = TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.01,
    );

    return IosScaffold(
        title: 'Donate via UPI',
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget> [
                // Title
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text('Support SysAdmin Development', style: theme.textTheme.titleMedium),
                ),
                const SizedBox(height: 40),

                // Amount with TextInput
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text("Amount", style: theme.textTheme.titleSmall?.copyWith(fontSize: 14)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  margin: const EdgeInsets.only(left: 8.0),
                  decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.surface, width: 1.5),
                      borderRadius: BorderRadius.circular(8)
                  ),

                  child: TextFormField(
                    controller: amountController,
                    autofocus: true,
                    cursorHeight: 40,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 4, top: 12, bottom: 12),
                        child: Icon(Icons.currency_rupee_sharp, size: 26, color: Colors.grey),
                      ),
                      hintText: "Enter amount",
                      hintStyle: commonStyle.copyWith(color: theme.colorScheme.surface),
                      errorText: null, // This will be handled by our validation method
                    ),
                    style: commonStyle,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    textAlign: TextAlign.start,
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: (value) {
                      // Optional: Real-time validation
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 80),

                // Pay with
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text("Pay with", style: theme.textTheme.titleSmall?.copyWith(fontSize: 14)),
                ),
                Divider(color: theme.colorScheme.inverseSurface.useOpacity(0.25), thickness: 1.3, height: 20),

                // UPI apps
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _upiOptions.length,
                  itemBuilder: (context, index) => _buildUpiOptions(
                    "${_upiOptions[index]["asset"]}",
                    "${_upiOptions[index]["title"]}"
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }
}
